//
//  FriendListViewController.h
//  Presentice
//
//  Created by レー フックダイ on 1/9/14.
//  Copyright (c) 2014 Presentice. All rights reserved.
//

#import <Parse/Parse.h>
#import "SWRevealViewController.h"

#import <AWSRuntime/AWSRuntime.h>
#import <AWSS3/AWSS3.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "MessageDetailViewController.h"
#import "Constants.h"

#import <Parse/Parse.h>
#import "MBProgressHUD.h"

@interface FriendListViewController : PFQueryTableViewController <UINavigationControllerDelegate, AmazonServiceRequestDelegate, UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) IBOutlet UITableView *tableView;

- (IBAction)showLeftMenu:(id)sender;
- (IBAction)showRightMenu:(id)sender;


@end
