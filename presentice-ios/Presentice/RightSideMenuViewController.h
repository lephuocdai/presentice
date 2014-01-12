//
//  RightSideMenuViewController.h
//  Presentice
//
//  Created by レー フックダイ on 1/12/14.
//  Copyright (c) 2014 Presentice. All rights reserved.
//

#import <Parse/Parse.h>
#import "MFSideMenu.h"

#import <AWSRuntime/AWSRuntime.h>
#import <AWSS3/AWSS3.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "MessageDetailViewController.h"
#import "Constants.h"

#import <Parse/Parse.h>
#import "MBProgressHUD.h"

@interface RightSideMenuViewController : PFQueryTableViewController <UINavigationControllerDelegate, AmazonServiceRequestDelegate, UITableViewDelegate, UITableViewDataSource>
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@end
