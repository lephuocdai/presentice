//
//  RightSideMenuViewController.h
//  Presentice
//
//  Created by レー フックダイ on 1/12/14.
//  Copyright (c) 2014 Presentice. All rights reserved.
//

#import "PresenticeUtility.h"

#import "UserProfileViewController.h"


@interface RightSideMenuViewController : PFQueryTableViewController

- (IBAction)doClickFindFriendsBtn:(id)sender;
@property (strong, nonatomic) IBOutlet UITableView *tableView;

@end
