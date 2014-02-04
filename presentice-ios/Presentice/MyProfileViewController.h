//
//  MyProfileViewController.h
//  Presentice
//
//  Created by レー フックダイ on 1/9/14.
//  Copyright (c) 2014 Presentice. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MFSideMenu.h"
#import <Parse/Parse.h>
#import "MBProgressHUD.h"
#import "Constants.h"
#import "PresenticeUtility.h"


#import "PushPermissionViewController.h"
#import "LoginViewController.h"

@interface MyProfileViewController : UITableViewController <PushPermissionViewDataDelegate>
@property (strong, nonatomic) NSString *photoFilename;
@property (nonatomic, strong) NSMutableArray *menuItems;
- (IBAction)showLeftMenu:(id)sender;

@end
