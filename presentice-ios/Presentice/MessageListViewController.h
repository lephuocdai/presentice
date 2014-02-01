//
//  MessageListViewController.h
//  Presentice
//
//  Created by レー フックダイ on 12/26/13.
//  Copyright (c) 2013 Appcoda. All rights reserved.
//

#import "PresenticeUtility.h"

#import "NSDate+TimeAgo.h"

#import "MessageDetailViewController.h"

@interface MessageListViewController : PFQueryTableViewController < UINavigationControllerDelegate, UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) IBOutlet UITableView *tableView;
- (IBAction)showLeftMenu:(id)sender;
- (IBAction)showRightMenu:(id)sender;

@end
