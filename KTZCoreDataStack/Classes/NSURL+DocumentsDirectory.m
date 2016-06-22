//
//  NSURL+DocumentsDirectory.m
//  CoreDataNov2015
//
//  Created by Kyle Zaragoza on 11/3/15.
//  Copyright © 2015 Five. All rights reserved.
//

#import "NSURL+DocumentsDirectory.h"

@implementation NSURL (DocumentsDirectory)

+ (NSURL *)documentsDirectory {
    NSURL *url = (NSURL *)[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory
                                                                  inDomains:NSUserDomainMask] lastObject];
    return url;
}

@end
