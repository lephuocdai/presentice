//
//  FindFriendViewController.h
//  Presentice
//
//  Created by PhuongNQ on 1/18/14.
//  Copyright (c) 2014 Presentice. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MFSideMenu.h"
#import <Parse/Parse.h>
#import "MBProgressHUD.h"

#import "PresenticeCache.h"
#import "PresenticeUtility.h"
#import "FindFriendCell.h"

#import "UserProfileViewController.h"

@interface FindFriendViewController : PFQueryTableViewController <FindFriendCellDelegate, UINavigationControllerDelegate, UITableViewDelegate, UITableViewDataSource>
- (IBAction)showLeftMenu:(id)sender;
- (IBAction)showRightMenu:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *followAllBtn;

@end
