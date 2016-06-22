//
//  KTZCoreDataStack.m
//
//  Created by Kyle Zaragoza on 11/3/15.
//  Copyright © 2015 Five. All rights reserved.
//

#import "KTZCoreDataStack.h"
#import "NSURL+DocumentsDirectory.h"

@interface KTZCoreDataStack()

// core data stack
@property (nonatomic, strong) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, strong) NSPersistentStoreCoordinator *coordinator;

// used for all user interaction
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

// used for non-blocking writes to disk
@property (nonatomic, strong) NSManagedObjectContext *privateDiskContext;

// used for performing work on background context
@property (nonatomic, strong) NSManagedObjectContext *backgroundWorkerContext;

@end

@implementation KTZCoreDataStack


#pragma mark - Init

- (id)initWithDataModelFilename:(NSString *)dataModelFilename
                  storeFilename:(NSString *)storeFilename
                       callback:(CoreDataStackInitCallbackBlock)callback
{
    return [self initWithDataModelFilename:dataModelFilename
                             storeFilename:storeFilename
                             inMemoryStore:NO
                          dumpInvalidStore:YES
                                  callback:callback];
}

- (id _Nonnull)initWithDataModelFilename:(NSString *)dataModelFilename
                           storeFilename:(NSString *)storeFilename
                           inMemoryStore:(BOOL)inMemory
                        dumpInvalidStore:(BOOL)dumpInvalidStore
                                callback:(CoreDataStackInitCallbackBlock)callback
{
    self = [super init];
    [self ktz_initializeCoreDataInMemory:inMemory
                        dumpInvalidStore:dumpInvalidStore
                       dataModelFilename:dataModelFilename
                           storeFilename:storeFilename
                                callback:callback];
    
    return self;
}

- (void)ktz_initializeCoreDataInMemory:(BOOL)inMemory
                      dumpInvalidStore:(BOOL)dumpInvalidStore
                     dataModelFilename:(NSString *)dataModelFilename
                         storeFilename:(NSString *)storeFilename
                              callback:(CoreDataStackInitCallbackBlock)callback
{
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:dataModelFilename withExtension:@"momd"];
    self.managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    NSAssert(self.managedObjectModel, @"%@:%s No model to generate a store from", [self class], __PRETTY_FUNCTION__);
    
    self.coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];
    NSAssert(self.coordinator, @"Failed to initialize coordinator");
    
    // init contexts
    self.managedObjectContext       = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    self.privateDiskContext         = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    self.backgroundWorkerContext    = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    
    // setup contexts parents
    [self.privateDiskContext setPersistentStoreCoordinator:self.coordinator];
    [self.managedObjectContext setParentContext:self.privateDiskContext];
    [self.backgroundWorkerContext setParentContext:self.managedObjectContext];
    
    __weak __typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        if (!weakSelf) { return; }
        NSPersistentStoreCoordinator *psc = weakSelf.privateDiskContext.persistentStoreCoordinator;
        NSMutableDictionary *options = [NSMutableDictionary dictionary];
        options[NSMigratePersistentStoresAutomaticallyOption]   = @YES;
        options[NSInferMappingModelAutomaticallyOption]         = @YES;
        options[NSSQLitePragmasOption]                          = @{@"journal_mode":@"DELETE"};
        
        NSURL *docUrl = [[NSURL documentsDirectory] URLByAppendingPathComponent:@"DataStore"];
        
        // ensure directory is created
        NSFileManager *manager = [NSFileManager new];
        [manager createDirectoryAtURL:docUrl
          withIntermediateDirectories:TRUE
                           attributes:nil
                                error:nil];
        
        // attempt to open store normally
        NSURL *storeUrl = [docUrl URLByAppendingPathComponent:storeFilename];
        NSError *firstTryError = nil;
        NSString *storeType = inMemory ? NSInMemoryStoreType : NSSQLiteStoreType;
        if (inMemory) {
            NSLog(@"opening core data store in memory");
        } else {
            NSLog(@"opening core data store at URL: %@", storeUrl);
        }
        [psc addPersistentStoreWithType:storeType
                          configuration:nil
                                    URL:storeUrl
                                options:options
                                  error:&firstTryError];
        
        if (firstTryError) {
            if (dumpInvalidStore) {
                NSLog(@"dumping old core data store, will retry to open clean store");
                // remove the old store (all of our data can be re-built)
                [manager removeItemAtURL:storeUrl
                                   error:nil];
                
                NSError *secondTryError = nil;
                [psc addPersistentStoreWithType:storeType
                                  configuration:nil
                                            URL:storeUrl
                                        options:options
                                          error:&secondTryError];
                
                // respond w/ error
                if (secondTryError) {
                    if (callback) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            callback(NO, secondTryError);
                        });
                    }
                    return;
                }
            } else {
                // respond w/ error if user didn't want to delete outdated/corrupt store
                if (callback) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        callback(NO, firstTryError);
                    });
                }
                return;
            }
        }
        // dispatch_sync wait for our UI thread to be ready
        if (callback) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                callback(TRUE, nil);
            });
        }
    });
}


#pragma mark - Saving

- (void)saveToDisk {
    // saves both main context and private context (which will save to disk)
    if (!self.privateDiskContext.hasChanges && !self.managedObjectContext.hasChanges) return;
    
    [[self managedObjectContext] performBlockAndWait:^{
        NSError *error = nil;
        [self.managedObjectContext save:&error];
        
        NSAssert(error == nil,
                 @"Failed to save main context: %@\n%@",
                 [error localizedDescription],
                 [error userInfo]);
        
        NSLog(@"save main thread context %s", __PRETTY_FUNCTION__);
        
        [self.privateDiskContext performBlock:^{
            NSError *privateError = nil;
            [self.privateDiskContext save:&privateError];
            
            NSAssert(error == nil,
                     @"Error saving private context: %@\n%@",
                     [privateError localizedDescription],
                     [privateError userInfo]);
            
            NSLog(@"save main thread context %s", __PRETTY_FUNCTION__);
        }];
    }];
}

@end
