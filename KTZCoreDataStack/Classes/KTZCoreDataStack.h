//
//  KTZCoreDataStack.h
//
//  Created by Kyle Zaragoza on 11/3/15.
//  Copyright © 2015 Five. All rights reserved.
//

#import <Foundation/Foundation.h>
@import CoreData;

// callback type for core data stack init completion
typedef void (^CoreDataStackInitCallbackBlock)(void);

@interface KTZCoreDataStack : NSObject

// used for all user interaction
@property (readonly, strong, nonatomic, nonnull) NSManagedObjectContext *managedObjectContext;

/**
 * Inits core data stack and calls optional callback when finished.
 * Equivilant to calling `[initWithInMemoryStore:NO synchronously:NO callback:callback]`
 */
- (id _Nonnull)initWithCallback:(CoreDataStackInitCallbackBlock _Nullable)callback;


/**
 * Inits core data stack and calls optional callback when finished.
 * 
 * Parameter inMemory: YES if stack should use in-memory storage, NO to use SQLite backed store.
 * Parameter synchronously: YES to bring up stack on calling thread synchronously, NO to bring up on high-priority background queue.
 */
- (id _Nonnull)initWithInMemoryStore:(BOOL)inMemory synchronously:(BOOL)synchronously callback:(CoreDataInitCallbackBlock _Nullable)callback;

// saves both main context and private context (which will save to disk)
- (void)save;

// these should be overridden by the subclass
- (NSString * _Nonnull)dataModelFilename;
- (NSString * _Nonnull)storeFilename;

@end
