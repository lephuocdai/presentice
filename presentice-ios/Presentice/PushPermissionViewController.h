//
//  PushPermissionViewController.h
//  Presentice
//
//  Created by レー フックダイ on 1/10/14.
//  Copyright (c) 2014 Presentice. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import "Constants.h"
@protocol PushPermissionViewDataDelegate

- (void)recieveData:(NSMutableDictionary *)pushPermission;

@end


@interface PushPermissionViewController : UITableViewController

@property (nonatomic) id<PushPermissionViewDataDelegate> delegate;
@property (nonatomic, strong) NSMutableDictionary *pushPermission;
-(void)updateSwitch:(UISwitch *)switchView;

@end
