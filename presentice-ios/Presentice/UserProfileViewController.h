//
//  UserProfileViewController.h
//  Presentice
//
//  Created by レー フックダイ on 1/16/14.
//  Copyright (c) 2014 Presentice. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MFSideMenu.h"
#import <Parse/Parse.h>
#import "MBProgressHUD.h"
#import "Constants.h"
#import "PresenticeUtility.h"

#import <AWSRuntime/AWSRuntime.h>
#import <AWSS3/AWSS3.h>

#import "UILabel+Boldify.h"

#import "MessageDetailViewController.h"
#import "QuestionDetailViewController.h"
#import "VideoViewController.h"


@interface UserProfileViewController : PFQueryTableViewController <UINavigationControllerDelegate, AmazonServiceRequestDelegate, UITableViewDelegate, UITableViewDataSource, UIAlertViewDelegate, UIImagePickerControllerDelegate>

// For display user info
@property (strong, nonatomic) PFUser *userObj;
@property (strong, nonatomic) IBOutlet UIImageView *userProfilePicture;
@property (strong, nonatomic) IBOutlet UILabel *userNameLabel;
@property (strong, nonatomic) IBOutlet UITableView *tableView;

// Action to this user
- (IBAction)sendMessage:(id)sender;
- (IBAction)reportUser:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *followBtn;

// For display user videos
@property BOOL isFollowing;

// Navigation button
- (IBAction)showLeftMenu:(id)sender;
- (IBAction)showRightMenu:(id)sender;



//@property (nonatomic, strong) NSMutableArray *menuItems;


@end
