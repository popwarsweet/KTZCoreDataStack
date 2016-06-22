//
//  KTZCoreDataStack.h
//
//  Created by Kyle Zaragoza on 11/3/15.
//  Copyright © 2015 Five. All rights reserved.
//

#import <Foundation/Foundation.h>
@import CoreData;

/// Callback type for core data stack init completion
typedef void (^CoreDataStackInitCallbackBlock)(BOOL success, NSError * _Nullable error);

@interface KTZCoreDataStack : NSObject

/// Used for all user interaction
@property (readonly, strong, nonatomic, nonnull) NSManagedObjectContext *managedObjectContext;

/// Used for performing work on background context
@property (readonly, strong, nonatomic, nonnull) NSManagedObjectContext *backgroundWorkerContext;

/**
 Inits core data stack and calls optional callback when finished.
 
 @note This is equivilant to calling @code initWithDataModelFilename:storeFilename:inMemoryStore:dumpInvalidStore:callback @endcode w/ inMemoryStore set to NO and dumpInvalidStore set to YES.
 @param dataModelFilename: Name of .xcdatamodel file to associate w/ core data stack
 @param storeFilename: Name of file which will be saved to disk, can be found in `Documents/DataStore/{storeFilename}`
 @param callback: The block which is called after opening the store has failed or succeeded.
 */
- (id _Nonnull)initWithDataModelFilename:(NSString * _Nonnull)dataModelFilename
                           storeFilename:(NSString * _Nonnull)storeFilename
                                callback:(CoreDataStackInitCallbackBlock _Nullable)callback;

/**
 Inits core data stack and calls optional callback when finished.
 
 @param dataModelFilename: Name of .xcdatamodel file to associate w/ core data stack
 @param storeFilename: Name of file which will be saved to disk, can be found in 'Documents/DataStore/{storeFilename}'
 @param inMemory: Set to YES if the stack should use in-memory storage, NO to use SQLite backed store.
 @param dumpInvalidStore: Set to YES if the original SQLite file should be deleted if it can't be opened on the first try. Only use this feature if your data is reproduceable (from server, backup, etc.).
 @param callback: The block which is called after opening the store has failed or succeeded.
 */
- (id _Nonnull)initWithDataModelFilename:(NSString * _Nonnull)dataModelFilename
                           storeFilename:(NSString * _Nonnull)storeFilename
                           inMemoryStore:(BOOL)inMemory
                        dumpInvalidStore:(BOOL)dumpInvalidStore
                                callback:(CoreDataStackInitCallbackBlock _Nullable)callback;

/// Saves both main context and private context (which will save to disk)
- (void)saveToDisk;

@end
