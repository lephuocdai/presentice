//
//  UserProfileViewController.h
//  Presentice
//
//  Created by レー フックダイ on 1/16/14.
//  Copyright (c) 2014 Presentice. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MFSideMenu.h"
#import <Parse/Parse.h>
#import "MBProgressHUD.h"
#import "Constants.h"

@interface UserProfileViewController : UITableViewController

@property (strong, nonatomic) PFUser *userObj;
@property (nonatomic, strong) NSMutableArray *menuItems;
- (IBAction)showLeftMenuPressed:(id)sender;
- (IBAction)showRightMenuPressed:(id)sender;

@end
