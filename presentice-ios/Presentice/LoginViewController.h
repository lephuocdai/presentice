//
//  LoginViewController.h
//  Presentice
//
//  Created by PhuongNQ on 12/21/13.
//  Copyright (c) 2013 Appcoda. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import "MBProgressHUD.h"
#import "quickdialog/QuickDialog.h"
#import "MFSideMenuContainerViewController.h"

#import "LeftSideMenuViewController.h"
#import "RightSideMenuViewController.h"

#import "LoginInfo.h"
#import "EmailInfo.h"

#import "MainViewController.h"
#import "QuestionListViewController.h"
#import "MyListViewController.h"
#import "NotificationListViewController.h"
#import "RegisterViewController.h"

//#import "UITabBarController+HideTabBar.h"

//@interface LoginViewController : UIViewController
@interface LoginViewController : QuickDialogController <QuickDialogEntryElementDelegate> {
    
}

@end
