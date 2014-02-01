//
//  FriendListViewController.h
//  Presentice
//
//  Created by レー フックダイ on 1/9/14.
//  Copyright (c) 2014 Presentice. All rights reserved.
//

#import "PresenticeUtility.h"

#import "MessageDetailViewController.h"


@interface FriendListViewController : PFQueryTableViewController <UINavigationControllerDelegate, UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) IBOutlet UITableView *tableView;

- (IBAction)showLeftMenu:(id)sender;
- (IBAction)showRightMenu:(id)sender;


@end
