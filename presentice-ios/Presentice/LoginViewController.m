//
//  LoginViewController.m
//  Presentice
//
//  Created by PhuongNQ on 12/21/13.
//  Copyright (c) 2013 Appcoda. All rights reserved.
//

#import "LoginViewController.h"

@interface LoginViewController ()
- (void)onLogin:(QButtonElement *)buttonElement;
- (void)onLoginFacebook:(QButtonElement *)buttonElement;
- (void)onRequestPasswordReset:(QButtonElement *)buttonElement;
- (void)sendPasswordResetEmail:(QButtonElement *)buttonElement;

@property (assign, nonatomic) BOOL isResetingPassword;

@end

@implementation LoginViewController {
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super initWithCoder:aDecoder])) {
        
        self.root = [[QRootElement alloc] initWithJSONFile:@"loginform"];
//        self.root = [[QRootElement alloc] initWithJSONURL:[PresenticeUtitily s3URLWithFileName:@"loginform.json"] andData:nil];
        
        self.root.appearance = [self.root.appearance copy];
        
        ((QEntryElement *)[self.root elementWithKey:@"email"]).delegate = self;
        
        QAppearance *fieldsAppearance = [self.root.appearance copy];
        fieldsAppearance.backgroundColorEnabled = [UIColor colorWithRed:0 green:125.0/255 blue:225.0/255 alpha:1];
        
        QLabelElement *facebookLoginLabel = (QLabelElement*)[self.root elementWithKey:@"facebookLoginLabel"];
        facebookLoginLabel.image = [UIImage imageNamed:@"facebook_icon"];
        [self.root elementWithKey:@"facebookLoginLabel"].appearance = self.root.appearance.copy;
        [self.root elementWithKey:@"facebookLoginLabel"].appearance.backgroundColorEnabled = [UIColor colorWithRed:59.0/255 green:89.0/255 blue:182.0/255 alpha:1];
        
        [self.root elementWithKey:@"loginButton"].appearance = self.root.appearance.copy;
        [self.root elementWithKey:@"loginButton"].appearance = fieldsAppearance;
        
        //hide navigator if in login view
        if (self.isResetingPassword == false) {
            [self.navigationController setNavigationBarHidden:YES animated:YES];
        }
        self.resizeWhenKeyboardPresented = YES;
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    //hide navigator if in login view
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)loginCompleted:(LoginInfo *)info {
    [self loading:NO];
    
    //start loading hub
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    NSString *username = info.email;
    NSString *password = info.password;
    [PFUser logInWithUsernameInBackground:username password:password block:^(PFUser *user, NSError *error) {
        if(!error){
            [PresenticeUtility instantiateHomeScreenFrom:self animated:NO completion:nil];
            
            // subscribe user default channel for notification.
            PFInstallation *currentInstallation = [PFInstallation currentInstallation];
            [currentInstallation addUniqueObject:[NSString stringWithFormat:@"user_%@",[user objectId]] forKey:@"channels"];
            [currentInstallation saveInBackground];
            
        } else {
            UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Login Failed",nil) message:NSLocalizedString(@"Please check your login username and password!",nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil , nil];
            [errorAlert show];
        }
        //dismiss hub
        [MBProgressHUD hideHUDForView:self.view animated:YES];
    }];
    
}

- (void)onLogin:(QButtonElement *)buttonElement {
    
    [[[UIApplication sharedApplication] keyWindow] endEditing:YES];
    [self loading:YES];
    LoginInfo *info = [[LoginInfo alloc] init];
    [self.root fetchValueUsingBindingsIntoObject:info];
    [self performSelector:@selector(loginCompleted:) withObject:info afterDelay:2];
}

- (void)onLoginFacebook:(QButtonElement *)buttonElement {
    [PresenticeUtility loginViaFacebookIn:self];
}

- (void)onRequestPasswordReset:(QButtonElement *)buttonElement {
    self.isResetingPassword = true;
    
    QRootElement *details = [self createResetPasswordRequestForm];
    [self displayViewControllerForRoot:details];
}

- (QRootElement *)createResetPasswordRequestForm {
    QRootElement *details = [[QRootElement alloc] initWithJSONURL:[PresenticeUtility s3URLWithFileName:@"requestResetPasswordForm.json"] andData:nil];
    return details;
}

- (void)sendPasswordResetEmail:(QButtonElement *)buttonElement {
    [[[UIApplication sharedApplication] keyWindow] endEditing:YES];
    [self loading:YES];
    
    EmailInfo *info = [[EmailInfo alloc] init];
    [self.root fetchValueUsingBindingsIntoObject:info];
    
    [self loading:NO];
    NSString *email = info.email;
    [PFUser requestPasswordResetForEmailInBackground:email block:^(BOOL succeeded, NSError *error) {
        if (error) {
            NSString *alertMessage = [NSString stringWithFormat:NSLocalizedString(@"The email address %@ has not been registered.",nil), email];
            UIAlertView *passwordResetAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Email address error!",nil)
                                                                         message:alertMessage
                                                                        delegate:nil
                                                               cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                                               otherButtonTitles:nil];
            [passwordResetAlert show];
        } else {
            NSString *alertMessage = [NSString stringWithFormat:NSLocalizedString(@"An email from our provider Parse has been sent to you. Please check you email: %@",nil), email];
            UIAlertView *passwordResetAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Confirmation email sent",nil)
                                                                         message:alertMessage delegate:nil
                                                               cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                                               otherButtonTitles:nil];
            [passwordResetAlert show];
        }
    }];
}

- (BOOL)QEntryShouldChangeCharactersInRangeForElement:(QEntryElement *)element andCell:(QEntryTableViewCell *)cell {
    NSLog(@"Should change characters");
    return YES;
}

- (void)QEntryEditingChangedForElement:(QEntryElement *)element andCell:(QEntryTableViewCell *)cell {
    NSLog(@"Editing changed");
}


- (void)QEntryMustReturnForElement:(QEntryElement *)element andCell:(QEntryTableViewCell *)cell {
    NSLog(@"Must return");
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    //if user already login, redirect to Home Screen
	if([PFUser currentUser] && [PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]) {
        [PresenticeUtility instantiateHomeScreenFrom:self animated:NO completion:nil];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
