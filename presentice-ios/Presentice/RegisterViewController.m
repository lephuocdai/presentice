//
//  RegisterViewController.m
//  Presentice
//
//  Created by PhuongNQ on 12/23/13.
//  Copyright (c) 2013 Appcoda. All rights reserved.
//

#import "RegisterViewController.h"

NSDictionary<FBGraphUser>  *fbInfo;

@interface RegisterViewController ()
- (void)onRegister:(QButtonElement *)buttonElement;

@end

@implementation RegisterViewController

/**
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
**/

- (id)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super initWithCoder:aDecoder])) {
        self.root = [[QRootElement alloc] initWithJSONFile:@"registerForm"];
//        self.root = [[QRootElement alloc] initWithJSONURL:[PresenticeUtitily s3URLWithFileName:@"registerForm.json"] andData:nil];
        self.resizeWhenKeyboardPresented = YES;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //show navigation
	[self.navigationController setNavigationBarHidden:NO animated:YES];
    
    //input data form facebook to text box
    [self loadDataFromFB];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/**
 * end of editing
 * dissmis input keyboard

- (void)touchesEnded: (NSSet *)touches withEvent: (UIEvent *)event {
	for (UIView* view in self.view.subviews) {
		if ([view isKindOfClass:[UITextField class]])
			[view resignFirstResponder];
	}
}
 **/

/**
* load data from facebook
* input automatically to input fields
**/
-(void) loadDataFromFB {
    [FBRequestConnection startForMeWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if(!error){
            fbInfo = (NSDictionary<FBGraphUser> *)result;
//            self.emailField.text = [fbInfo objectForKey:@"email"];
//            QEntryElement *email = (QEntryElement *)[self.root elementWithKey:@"email"];
//            email.textValue = [fbInfo objectForKey:@"email"];
            ((QEntryElement *)[self.root elementWithKey:@"email"]).textValue = [fbInfo objectForKey:@"email"];
        }
    }];
}

- (void)onRegister:(QButtonElement *)buttonElement {
    [[[UIApplication sharedApplication] keyWindow] endEditing:YES];
    [self loading:YES];
    RegisterInfo *info = [[RegisterInfo alloc] init];
//    [self.root fetchValueUsingBindingsIntoObject:info];
    [self.root fetchValueIntoObject:info];
    [self performSelector:@selector(registerCompleted:) withObject:info afterDelay:2];
}

- (void)registerCompleted:(RegisterInfo *)info {
    [self loading:NO];
    
    //start loading hub
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    //check email
    if(![Validate NSStringIsValidEmail:info.email]){
        UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Sign Up Error" message:@"Email Invalid. Please check input email again!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil , nil];
        [errorAlert show];
        return;
    }
    
    
    //check password
    if(![Validate NSSTringISValidPassword:info.password]){
        UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Sign Up Error" message:@"Password Invalid. Password must be more than 5 digits!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil , nil];
        [errorAlert show];
        return;
    }
    NSLog(@"password = %@  confirm = %@", info.password, info.passwordConfirm);
    //check password
    if(![info.password isEqualToString:info.passwordConfirm]){
        UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Sign Up Error" message:@"Password not matched. Please check input password again!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil , nil];
        [errorAlert show];
        return;
    }
    
    PFUser *newUser = [PFUser currentUser];
    newUser.username = info.email;
    newUser.password = info.password;
    newUser.email = info.email;
    
    [newUser setObject:[NSNumber numberWithBool:NO] forKey:kUserActivatedKey];
    [newUser setObject:fbInfo.id forKey:kUserFacebookIdKey];
    [newUser setObject:fbInfo.name forKey:kUserDisplayNameKey];
    [newUser setObject:fbInfo forKey:kUserProfileKey];
    [newUser setObject:[NSNumber numberWithBool:NO] forKey:kUserCanPostQuestion];
    [newUser setObject:[NSNumber numberWithBool:NO] forKey:kUserCanComment];
    [newUser setObject:info.code forKey:kUserReceiveCode];
    
    NSString *alphabet  = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXZY0123456789";
    NSMutableString *code = [NSMutableString stringWithCapacity:20];
    for (NSUInteger i = 0; i < 6; i++) {
        u_int32_t r = arc4random() % [alphabet length];
        unichar c = [alphabet characterAtIndex:r];
        [code appendFormat:@"%C", c];
    }
    
    NSMutableDictionary *pushPermission = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"answered", @"yes", @"reviewed", @"yes", @"viewed", @"no", @"message", @"yes", nil];
    
    [newUser setObject:pushPermission forKey:kUserPushPermission];
    
    [newUser saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (!error) {
            
            NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
            [params setObject:info.code forKey:@"receiveCode"];
            [PFCloud callFunction:@"onRegistered" withParameters:params];
            
            //show succeeded alert
            UIAlertView *succeedAlert = [[UIAlertView alloc] initWithTitle:@"Sign Up Succeeded" message:@"Click OK to go to main screen" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [succeedAlert show];
            
            // Register registerActivity to Actitivy Table
            PFObject *registerActivity = [PFObject objectWithClassName:kActivityClassKey];
            [registerActivity setObject:@"register" forKey:kActivityTypeKey];
            [registerActivity setObject:newUser forKey:kActivityFromUserKey];
            
            NSMutableDictionary *content = [[NSMutableDictionary alloc] init ];
            [content setObject:[newUser objectForKey:kUserFacebookIdKey] forKey:@"facebookId"];
            [content setObject:[newUser objectForKey:kUserActivatedKey] forKey:@"activated"];
//            [content setObject:[newUser objectForKey:kUserTypeKey] forKey:@"type"];
            [registerActivity setObject:content forKey:kActivityContentKey];
            
            NSLog(@"registerActivity = %@", registerActivity);
            [registerActivity saveInBackground];
            
        } else {
            //error message
            NSString *errorString = [error userInfo][@"error"];
            
            //show errored alert
            UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Sign Up Error" message:errorString delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [errorAlert show];
        }
    }];
    
    // subscribe user default channel for notification.
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation addUniqueObject:[newUser objectId] forKey:@"channels"];
    [currentInstallation saveInBackground];
    
}
/**
- (IBAction)didClickRegisterButton:(id)sender {
    //check email
    if(![Validate NSStringIsValidEmail:self.emailField.text]){
        UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Sign Up Error" message:@"Email Invalid. Please check input email again!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil , nil];
        [errorAlert show];
        return;
    }
    
    //check password
    if(![Validate NSSTringISValidPassword:self.passwordField.text]){
        UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Sign Up Error" message:@"Password Invalid. Password must be more than 5 digits!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil , nil];
        [errorAlert show];
        return;
    }
    
    //check password
    if(![self.passwordField.text isEqualToString:self.confirmPasswordField.text]){
        UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Sign Up Error" message:@"Password not matched. Please check input password again!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil , nil];
        [errorAlert show];
        return;
    }

    PFUser *newUser = [PFUser currentUser];
    newUser.username = in;
    newUser.password = self.passwordField.text;
    newUser.email = self.emailField.text;
    [newUser setObject:[NSNumber numberWithBool:NO] forKey:kUserActivatedKey];
    [newUser setObject:fbInfo.id forKey:kUserFacebookIdKey];
    [newUser setObject:fbInfo.name forKey:kUserDisplayNameKey];
    [newUser setObject:fbInfo forKey:kUserProfileKey];
    
    NSMutableDictionary *pushPermission = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"answered", @"yes", @"reviewed", @"yes", @"viewed", @"yes", @"message", @"yes", nil];
    
    [newUser setObject:pushPermission forKey:kUserPushPermission];
    
    [newUser saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (!error) {
            NSLog(@"register succeed!");
            
            //show succeeded alert
            UIAlertView *succeedAlert = [[UIAlertView alloc] initWithTitle:@"Sign Up Succeeded" message:@"Click OK to go to main screen" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [succeedAlert show];
            
            } else {
                //error message
                NSString *errorString = [error userInfo][@"error"];
                
                //show errored alert
                UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Sign Up Error" message:errorString delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                [errorAlert show];
                
            // Register registerActivity to Actitivy Table
                
                
                PFObject *registerActivity = [PFObject objectWithClassName:kActivityClassKey];
                [registerActivity setObject:@"register" forKey:kActivityTypeKey];
                [registerActivity setObject:newUser forKey:kActivityFromUserKey];
                
                NSMutableDictionary *content = [[NSMutableDictionary alloc] init ];
                [content setObject:[newUser objectForKey:kUserFacebookIdKey] forKey:@"facebookId"];
                [content setObject:[newUser objectForKey:kUserActivatedKey] forKey:@"activated"];
                [content setObject:[newUser objectForKey:kUserTypeKey] forKey:@"type"];
                [registerActivity setObject:content forKey:kActivityContentKey];
                
                [registerActivity saveInBackground];
        }
    }];
    
    // subscribe user default channel for notification.
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation addUniqueObject:[newUser objectId] forKey:@"channels"];
    [currentInstallation saveInBackground];

}
 **/

#pragma alertDelegate
// redirect to Login View Controller
-(void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
//    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
//    MainViewController *destViewController = (MainViewController *)[storyboard instantiateViewControllerWithIdentifier:@"mainViewController"];
//    [self.navigationController pushViewController:destViewController animated:YES];
    [self navigateToHomeScreen];
}

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
    [tabBarController setTabBarHidden:NO animated:YES];
    
    LeftSideMenuViewController *leftSideMenuController = [storyboard instantiateViewControllerWithIdentifier:@"leftSideMenuViewController"];
    RightSideMenuViewController *rightSideMenuController = [storyboard instantiateViewControllerWithIdentifier:@"rightSideMenuViewController"];
    
    MFSideMenuContainerViewController *container = [MFSideMenuContainerViewController
                                                    containerWithCenterViewController:tabBarController
                                                    leftMenuViewController:leftSideMenuController
                                                    rightMenuViewController:rightSideMenuController];
    
    [self.navigationController presentViewController:container animated:NO completion:nil];
}


@end
