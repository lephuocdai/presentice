//
//  MessageDetailViewController.h
//  Presentice
//
//  Created by レー フックダイ on 12/26/13.
//  Copyright (c) 2013 Appcoda. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MessageFooterView.h"

#import "Constants.h"
#import <Parse/Parse.h>
#import "MBProgressHUD.h"

@interface MessageDetailViewController : PFQueryTableViewController <UINavigationControllerDelegate, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>

@property (strong, nonatomic) PFUser *toUser;

@end
