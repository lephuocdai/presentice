//
//  MyListViewController.h
//  Presentice
//
//  Created by レー フックダイ on 12/31/13.
//  Copyright (c) 2013 Presentice. All rights reserved.
//

#import "PresenticeUtility.h"
#import <AssetsLibrary/AssetsLibrary.h>

#import "NSDate+TimeAgo.h"

#import "VideoViewController.h"


@interface MyListViewController : PFQueryTableViewController < UINavigationControllerDelegate, AmazonServiceRequestDelegate, UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) IBOutlet UITableView *tableView;
- (IBAction)showLeftMenu:(id)sender;
- (IBAction)showRightMenu:(id)sender;

@end
