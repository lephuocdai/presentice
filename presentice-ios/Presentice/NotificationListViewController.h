//
//  NotificationListViewController.h
//  Presentice
//
//  Created by レー フックダイ on 12/26/13.
//  Copyright (c) 2013 Appcoda. All rights reserved.
//

#import "PresenticeUtility.h"
#import <AssetsLibrary/AssetsLibrary.h>


#import "UILabel+Boldify.h"
#import "NSDate+TimeAgo.h"

#import "VideoViewController.h"
#import "QuestionDetailViewController.h"
#import "UserProfileViewController.h"

@interface NotificationListViewController : PFQueryTableViewController <UINavigationControllerDelegate, AmazonServiceRequestDelegate, UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) IBOutlet UITableView *tableView;
- (IBAction)showLeftMenu:(id)sender;
- (IBAction)showRightMenu:(id)sender;

@end
