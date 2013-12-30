//
//  MyListViewController.h
//  Presentice
//
//  Created by レー フックダイ on 12/24/13.
//  Copyright (c) 2013 Appcoda. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SWRevealViewController.h"

#import <AWSRuntime/AWSRuntime.h>
#import <AWSS3/AWSS3.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "MyAnswerViewController.h"
#import "Constants.h"
#import "MBProgressHUD.h"
#import <Parse/Parse.h>

@interface MyListViewController : UIViewController <UINavigationControllerDelegate, AmazonServiceRequestDelegate, UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) IBOutlet UIBarButtonItem *sidebarButton;
@property (strong, nonatomic) IBOutlet UITableView *tableView;

@end
