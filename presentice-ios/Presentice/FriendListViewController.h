//
//  FriendListViewController.h
//  Presentice
//
//  Created by レー フックダイ on 1/9/14.
//  Copyright (c) 2014 Presentice. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import "MBProgressHUD.h"
#import "MFSideMenu.h"
#import "Constants.h"
#import "PresenticeUtility.h"

#import "MessageDetailViewController.h"


@interface FriendListViewController : PFQueryTableViewController <UINavigationControllerDelegate, UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) IBOutlet UITableView *tableView;

- (IBAction)showLeftMenu:(id)sender;
- (IBAction)showRightMenu:(id)sender;


@end
