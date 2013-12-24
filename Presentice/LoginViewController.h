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


@interface LoginViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIButton *btnFBLogin;
- (IBAction)didPressLoginButton:(id)sender;

@end
