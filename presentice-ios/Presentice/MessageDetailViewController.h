//
//  MessageDetailViewController.h
//  Presentice
//
//  Created by レー フックダイ on 12/26/13.
//  Copyright (c) 2013 Appcoda. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Constants.h"
#import <Parse/Parse.h>
#import "MBProgressHUD.h"
#import "JSMessagesViewController.h"

#import "MessageFooterView.h"

#import "UserProfileViewController.h"

@interface MessageDetailViewController : JSMessagesViewController <JSDismissiveTextViewDelegate, JSMessagesViewDataSource, JSMessagesViewDelegate, JSDismissiveTextViewDelegate, UINavigationControllerDelegate, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>

@property (strong, nonatomic) PFUser *toUser;
@property (strong, nonatomic) PFObject *messageObj;

@property (strong, nonatomic) NSMutableArray *messages;
@property (strong, nonatomic) NSDictionary *avatars;

@end
