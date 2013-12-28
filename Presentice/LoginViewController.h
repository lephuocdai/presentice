//
//  LoginViewController.h
//  Presentice
//
//  Created by PhuongNQ on 12/21/13.
//  Copyright (c) 2013 Appcoda. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import "MainViewController.h"
#import "RegisterViewController.h"


@interface LoginViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITextField *tbUsername;
@property (weak, nonatomic) IBOutlet UITextField *tbPassword;
@property (weak, nonatomic) IBOutlet UIButton *btnRegister;
@property (weak, nonatomic) IBOutlet UIButton *btnFBLogin;

- (IBAction)didPressLoginButton:(id)sender;
- (IBAction)didPressRegisterButton:(id)sender;

@end
