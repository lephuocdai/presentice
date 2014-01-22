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
#import "PresenticeUtitily.h"

#import "MessageDetailViewController.h"

@interface UserProfileViewController : UITableViewController

@property (strong, nonatomic) PFUser *userObj;
@property (nonatomic, strong) NSMutableArray *menuItems;

//- (IBAction)showLeftMenuPressed:(id)sender;

- (IBAction)showLeftMenu:(id)sender;
- (IBAction)showRightMenu:(id)sender;


//@property (strong, nonatomic) IBOutlet UIButton *sendMessage;
//@property (strong, nonatomic) IBOutlet UIButton *reportUser;

- (IBAction)sendMessage:(id)sender;
- (IBAction)reportUser:(id)sender;

@property (weak, nonatomic) IBOutlet UIButton *followBtn;

@end
