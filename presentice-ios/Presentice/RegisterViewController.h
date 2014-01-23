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


//@interface RegisterViewController : UIViewController<UIAlertViewDelegate>
@interface RegisterViewController : QuickDialogController <QuickDialogEntryElementDelegate> {
    
}

//@property (weak, nonatomic) IBOutlet UITextField *tbEmail;
//- (IBAction)didClickRegisterButton:(id)sender;
//
//@property (weak, nonatomic) IBOutlet UITextField *emailField;
//@property (weak, nonatomic) IBOutlet UITextField *passwordField;
//@property (weak, nonatomic) IBOutlet UITextField *confirmPasswordField;

@property NSString *email;


@end
