//
//  FindFriendViewController.h
//  Presentice
//
//  Created by PhuongNQ on 1/18/14.
//  Copyright (c) 2014 Presentice. All rights reserved.
//

#import "PresenticeUtility.h"
#import "PresenticeCache.h"
#import <MessageUI/MessageUI.h>

#import "FindFriendCell.h"

#import "UserProfileViewController.h"


@interface FindFriendViewController : PFQueryTableViewController <FindFriendCellDelegate, UINavigationControllerDelegate, UITableViewDelegate, UITableViewDataSource, MFMailComposeViewControllerDelegate>

- (IBAction)showLeftMenu:(id)sender;
- (IBAction)showRightMenu:(id)sender;
- (IBAction)inviteFriends:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *followAllBtn;

@end
