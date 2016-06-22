//
//  FIVCoreDataController.m
//  CoreDataNov2015
//
//  Created by Kyle Zaragoza on 11/3/15.
//  Copyright © 2015 Five. All rights reserved.
//

#import "KTZCoreDataController.h"
#import "NSURL+DocumentsDirectory.h"

@interface KTZCoreDataController()

// core data stack
@property (nonatomic, strong) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, strong) NSPersistentStoreCoordinator *coordinator;

// used for all user interaction
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

// used for non-blocking writes to disk
@property (nonatomic, strong) NSManagedObjectContext *privateDiskContext;

// callback used after stack init
@property (nonatomic, strong) CoreDataInitCallbackBlock initCallback;

@end

@implementation KTZCoreDataController


#pragma mark - Init

- (id)initWithCallback:(CoreDataInitCallbackBlock)callback {
    return [self initWithInMemoryStore:NO synchronously:NO callback:callback];
}

- (id)initWithInMemoryStore:(BOOL)inMemory synchronously:(BOOL)synchronously callback:(CoreDataInitCallbackBlock)callback {
    self = [super init];
    
    [self setInitCallback:callback];
    [self ktz_initializeCoreDataInMemory:inMemory synchronously:synchronously];
    
    return self;
}

- (void)ktz_initializeCoreDataInMemory:(BOOL)inMemory synchronously:(BOOL)synchronously {
    if (self.managedObjectContext) return;
    
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:self.dataModelFilename withExtension:@"momd"];
    self.managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    NSAssert(self.managedObjectModel, @"%@:%s No model to generate a store from", [self class], __PRETTY_FUNCTION__);
    
    self.coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];
    NSAssert(self.coordinator, @"Failed to initialize coordinator");
    
    // init contexts
    self.managedObjectContext   = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    self.privateDiskContext     = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    
    // setup contexts parents
    [self.privateDiskContext setPersistentStoreCoordinator:self.coordinator];
    [self.managedObjectContext setParentContext:self.privateDiskContext];
    
    // setup is done inside this block so we can do it synchronously or asynchronously below
    void(^setupStack)() = ^() {
        NSPersistentStoreCoordinator *psc = self.privateDiskContext.persistentStoreCoordinator;
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
        
        NSURL *storeUrl = [docUrl URLByAppendingPathComponent:self.storeFilename];
        NSLog(@"opening store URL: %@", storeUrl);
        
        NSError *firstTryError = nil;
        NSString *storeType = inMemory ? NSInMemoryStoreType : NSSQLiteStoreType;
        [psc addPersistentStoreWithType:storeType
                          configuration:nil
                                    URL:storeUrl
                                options:options
                                  error:&firstTryError];
        
        if (firstTryError) {
            // remove the old store (all of our data can be re-built)
            [manager removeItemAtURL:storeUrl
                               error:nil];
            
            NSError *secondTryError = nil;
            [psc addPersistentStoreWithType:storeType
                              configuration:nil
                                        URL:storeUrl
                                    options:options
                                      error:&secondTryError];
            
            NSAssert(secondTryError == nil,
                     @"Error initializing PSC: %@\n%@",
                     secondTryError.localizedDescription,
                     secondTryError.userInfo);
        }
        
        // return early if no callback
        if (!self.initCallback) return;
     
        if (synchronously) {
            self.initCallback();
        } else {
            // dispatch_sync wait for our UI thread to be ready
            dispatch_sync(dispatch_get_main_queue(), ^{
                self.initCallback();
            });
        }
    };
    
    if (synchronously) {
        setupStack();
    } else {
        // jump to background queue since addPersistentStoreWithType can take an unknown amount of time (if `synchrounously == YES`)
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            setupStack();
        });
    }
}


#pragma mark - Filenames

- (NSString *)dataModelFilename {
    return @"CoreDataNov2015";
}

- (NSString *)storeFilename {
    return @"CoreDataNov2015.sqlite";
}


#pragma mark - Saving

- (void)save {
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
