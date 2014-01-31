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
//- (void)onAbout;

@property (assign, nonatomic) BOOL isResetingPassword;

@end

@implementation LoginViewController {
//    BOOL isResetingPassword;
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
            NSLog(@"fuck you reseting again %hhd", self.isResetingPassword);
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
    
//    self.navigationController.navigationBar.tintColor = nil;
//    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"About" style:UIBarButtonItemStylePlain target:self action:@selector(onAbout)];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    NSLog(@"fuck you out of Login View Controller");
}

- (void)loginCompleted:(LoginInfo *)info {
    [self loading:NO];
    
    //start loading hub
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    NSString *username = info.email;
    NSString *password = info.password;
    [PFUser logInWithUsernameInBackground:username password:password block:^(PFUser *user, NSError *error) {
        if(!error){
            
            [self navigateToHomeScreen];
            
            // subscribe user default channel for notification.
            PFInstallation *currentInstallation = [PFInstallation currentInstallation];
            [currentInstallation addUniqueObject:[user objectId] forKey:@"channels"];
            [currentInstallation saveInBackground];
            
        } else {
            UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Login Failed" message:@"Please check your login username and password!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil , nil];
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
    // Set permissions required from the facebook user account
    NSArray *permissionsArray = @[ @"user_about_me", @"user_relationships", @"user_birthday", @"user_location"];
    
    //start loading hub
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    // Login PFUser using facebook
    [PFFacebookUtils logInWithPermissions:permissionsArray block:^(PFUser *user, NSError *error) {
        if (!user) {
            if (!error) {
                NSLog(@"Uh oh. The user cancelled the Facebook login.");
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Log In Error" message:@"Uh oh. The user cancelled the Facebook login." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Dismiss", nil];
                [alert show];
            } else {
                NSLog(@"Uh oh. An error occurred: %@", error);
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Log In Error" message:[error description] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Dismiss", nil];
                [alert show];
            }
        } else {
            // check if user already registered with facebook
            [FBRequestConnection startForMeWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                if(!error){
                    //get email from facebook
                    NSDictionary<FBGraphUser> *me = (NSDictionary<FBGraphUser> *)result;
                    NSLog(@"%@", me);
                    NSString *email = [me objectForKey:@"email"];
                    NSString *facebookId = [me objectForKey:@"id"];
                    //query User with email
                    PFQuery *queryUser = [PFUser query];
                    
                    if(email != nil && ![email isEqual:@""]){
                        [queryUser whereKey:kUserNameKey equalTo:email];
                    } else {
                        [queryUser whereKey:kUserFacebookIdKey equalTo:facebookId];
                    }
                    [queryUser findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                        //if email/facebookId already registered, redirect to main view
                        if (!error && [objects count] != 0) {
                            //redirect using storyboard
                            //if user already login, redirect to MainViewController
                            if([PFUser currentUser] && [PFFacebookUtils isLinkedWithUser:[PFUser currentUser]])
                                [self navigateToHomeScreen];
                            
                        } else {
                            //redirecto to register screen using storyboard
                            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
                            RegisterViewController *destViewController = (RegisterViewController *)[storyboard instantiateViewControllerWithIdentifier:@"RegisterViewController"];
                            [self.navigationController pushViewController:destViewController animated:YES];
                        }
                        
                        // subscribe user default channel for notification.
                        PFInstallation *currentInstallation = [PFInstallation currentInstallation];
                        [currentInstallation addUniqueObject:[user objectId] forKey:@"channels"];
                        [currentInstallation saveInBackground];
                        
                        NSLog(@"currentInstallation: %@", currentInstallation);
                        
                        // dismiss hub
                        [MBProgressHUD hideHUDForView:self.view animated:YES];
                    }];
                    
                }
            }];
        }
    }];
}

- (void)onRequestPasswordReset:(QButtonElement *)buttonElement {
    self.isResetingPassword = true;
    
    QRootElement *details = [self createResetPasswordRequestForm];
    [self displayViewControllerForRoot:details];
}

- (QRootElement *)createResetPasswordRequestForm {
    QRootElement *details = [[QRootElement alloc] initWithJSONURL:[PresenticeUtitily s3URLWithFileName:@"requestResetPasswordForm.json"] andData:nil];
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
            NSString *alertMessage = [NSString stringWithFormat:@"The email address %@ has not been registered.", email];
            UIAlertView *passwordResetAlert = [[UIAlertView alloc] initWithTitle:@"Email address error!" message:alertMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
            passwordResetAlert.tag = 0;
            [passwordResetAlert show];
        } else {
            NSString *alertMessage = [NSString stringWithFormat:@"An email from our provider Parse has been sent to you. Please check you email: %@", email];
            UIAlertView *passwordResetAlert = [[UIAlertView alloc] initWithTitle:@"Confirmation email sent" message:alertMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
            passwordResetAlert.tag = 1;
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
    //if user already login, redirect to MainViewController
	if([PFUser currentUser] && [PFFacebookUtils isLinkedWithUser:[PFUser currentUser]])
        [self navigateToHomeScreen];
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/**
* Set side menu navigation
**/

- (void)navigateToHomeScreen {
    //get main storyboard
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
    
    //create side menu
    MainViewController *mainViewController = [storyboard instantiateViewControllerWithIdentifier:@"mainViewController"];
    UINavigationController *mainNavigationController = [[UINavigationController alloc]initWithRootViewController:mainViewController];
    
    QuestionListViewController *questionListViewController = [storyboard instantiateViewControllerWithIdentifier:@"questionListViewController"];
    UINavigationController *questionListNavigationController = [[UINavigationController alloc]initWithRootViewController:questionListViewController];
    
    MyListViewController *myListViewController = [storyboard instantiateViewControllerWithIdentifier:@"myListViewController"];
    UINavigationController *myListNavigationController = [[UINavigationController alloc]initWithRootViewController:myListViewController];
    
    NotificationListViewController *notificationListViewController = [storyboard instantiateViewControllerWithIdentifier:@"notificationListViewController"];
    UINavigationController *notificationListNavigationController = [[UINavigationController alloc]initWithRootViewController:notificationListViewController];
    
    UITabBarController *tabBarController = [[UITabBarController alloc] init];
    [tabBarController setViewControllers:[NSArray arrayWithObjects:mainNavigationController, questionListNavigationController, myListNavigationController, notificationListNavigationController, nil]];
    
    LeftSideMenuViewController *leftSideMenuController = [storyboard instantiateViewControllerWithIdentifier:@"leftSideMenuViewController"];
    RightSideMenuViewController *rightSideMenuController = [storyboard instantiateViewControllerWithIdentifier:@"rightSideMenuViewController"];
    
    MFSideMenuContainerViewController *container = [MFSideMenuContainerViewController
                                                    containerWithCenterViewController:tabBarController
                                                    leftMenuViewController:leftSideMenuController
                                                    rightMenuViewController:rightSideMenuController];
    
    [self.navigationController presentViewController:container animated:NO completion:nil];
}

@end
