//
//  QuestionListViewController.h
//  Presentice
//
//  Created by レー フックダイ on 12/31/13.
//  Copyright (c) 2013 Presentice. All rights reserved.
//

#import <Parse/Parse.h>
#import "MFSideMenu.h"

#import <AWSRuntime/AWSRuntime.h>
#import <AWSS3/AWSS3.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "QuestionViewController.h"
#import "Constants.h"

#import <Parse/Parse.h>
#import "MBProgressHUD.h"

@interface QuestionListViewController : PFQueryTableViewController <UINavigationControllerDelegate, AmazonServiceRequestDelegate, UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) IBOutlet UITableView *tableView;
- (IBAction)showLeftMenu:(id)sender;
- (IBAction)showRightMenu:(id)sender;

@end
