//
//  RegisterViewController.h
//  Presentice
//
//  Created by PhuongNQ on 12/23/13.
//  Copyright (c) 2013 Appcoda. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import "MBProgressHUD.h"
#import "quickdialog/QuickDialog.h"
#import "MFSideMenuContainerViewController.h"

#import "RegisterInfo.h"

#import "LoginViewController.h"
#import "Validate.h"


@interface RegisterViewController : QuickDialogController <QuickDialogEntryElementDelegate> {
    
}

@property NSString *email;


@end
