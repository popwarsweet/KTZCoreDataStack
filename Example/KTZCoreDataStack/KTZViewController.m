//
//  KTZViewController.m
//  KTZCoreDataStack
//
//  Created by Kyle Zaragoza on 06/22/2016.
//  Copyright (c) 2016 Kyle Zaragoza. All rights reserved.
//

#import "KTZViewController.h"
#import "KTZCoreDataStack.h"

@interface KTZViewController ()
@property (nonatomic, strong) KTZCoreDataStack *coreDataStack;
@end

@implementation KTZViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.coreDataStack = [[KTZCoreDataStack alloc] initWithDataModelFilename:@"ExampleModel"
                                                               storeFilename:@"ExampleFilename"
                                                                    callback:^(BOOL success, NSError * _Nullable error) {
                                                                        if (success) {
                                                                            NSLog(@"successfully opened core data store");
                                                                        } else {
                                                                            NSLog(@"failed to open core data store: %@", error);
                                                                        }
                                                                    }];
}

@end
