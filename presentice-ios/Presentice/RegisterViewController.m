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

- (id)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super initWithCoder:aDecoder])) {
        self.root = [[QRootElement alloc] initWithJSONFile:@"registerForm"];
        //        self.root = [[QRootElement alloc] initWithJSONURL:[PresenticeUtitily s3URLWithFileName:@"registerForm.json"] andData:nil];
        
        QAppearance *fieldsAppearance = [self.root.appearance copy];
        fieldsAppearance.backgroundColorEnabled = [UIColor colorWithRed:0 green:125.0/255 blue:225.0/255 alpha:1];
        [self.root elementWithKey:@"button"].appearance = fieldsAppearance;
    
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
* load data from facebook
* input automatically to input fields
**/
-(void) loadDataFromFB {
    [FBRequestConnection startForMeWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if(!error){
            fbInfo = (NSDictionary<FBGraphUser> *)result;
            ((QEntryElement *)[self.root elementWithKey:@"email"]).textValue = [fbInfo objectForKey:@"email"];
        }
    }];
}

- (void)onRegister:(QButtonElement *)buttonElement {
    [[[UIApplication sharedApplication] keyWindow] endEditing:YES];
    [self loading:YES];
    RegisterInfo *info = [[RegisterInfo alloc] init];

    [self.root fetchValueIntoObject:info];
    [self performSelector:@selector(registerCompleted:) withObject:info afterDelay:2];
}

- (void)registerCompleted:(RegisterInfo *)info {
    [self loading:NO];
    
    //start loading hub
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    //check email
    if(![Validate NSStringIsValidEmail:info.email]){
        UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Sign Up Error", nil) message:NSLocalizedString(@"Email Invalid. Please check input email again!",nil) delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil , nil];
        [errorAlert show];
        return;
    }
    
    
    //check password
    if(![Validate NSSTringISValidPassword:info.password]){
        UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Sign Up Error", nil) message:NSLocalizedString(@"Password Invalid. Password must be more than 5 digits!",nil) delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil , nil];
        [errorAlert show];
        return;
    }

    //check password
    if(![info.password isEqualToString:info.passwordConfirm]){
        UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Sign Up Error", nil) message:NSLocalizedString(@"Password not matched. Please check input password again!", nil) delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil , nil];
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
    
    
    NSDictionary *pushPermission = [NSDictionary dictionaryWithObjectsAndKeys:@"yes", @"answered", @"yes",  @"reviewed", @"no", @"viewed", @"yes", @"messaged", @"yes", @"followed", @"yes", @"registered", nil];
    [newUser setObject:pushPermission forKey:kUserPushPermission];
    
    if (info.code != nil) {
        [newUser setObject:info.code forKey:kUserReceiveCode];
    } else {
        [newUser setObject:@"noCode" forKey:kUserReceiveCode];
    }
    
    [newUser saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (!error) {
            
            NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
            [params setObject:[newUser objectForKey:kUserReceiveCode] forKey:@"receiveCode"];
            [PFCloud callFunction:@"onRegistered" withParameters:params];
            
            //show succeeded alert
            UIAlertView *succeedAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Sign Up Succeeded", nil) message:NSLocalizedString(@"Congratulations! Let's find some friends who are already on Presentice", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles: nil];
            succeedAlert.tag = 0;
            [succeedAlert show];
            
            // Register registerActivity to Activity Table
            PFObject *registerActivity = [PFObject objectWithClassName:kActivityClassKey];
            [registerActivity setObject:@"register" forKey:kActivityTypeKey];
            [registerActivity setObject:newUser forKey:kActivityFromUserKey];
            [registerActivity setObject:newUser forKey:kActivityToUserKey];
            
            NSMutableDictionary *content = [[NSMutableDictionary alloc] init ];
            [content setObject:[newUser objectForKey:kUserFacebookIdKey] forKey:@"facebookId"];
            [content setObject:[newUser objectForKey:kUserActivatedKey] forKey:@"activated"];
            [registerActivity setObject:content forKey:kActivityContentKey];
            
            NSLog(@"registerActivity = %@", registerActivity);
            [registerActivity saveInBackground];
            
        } else {
            //error message
            NSString *errorString = [error userInfo][@"error"];
            
            //show errored alert
            UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Sign Up Error", nil) message:errorString delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil, nil];
            [errorAlert show];
        }
    }];
    
    // subscribe user default channel for notification.
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation addUniqueObject:[NSString stringWithFormat:@"user_%@",[newUser objectId]] forKey:@"channels"];
    [currentInstallation saveInBackground];
    
}

#pragma alertDelegate
// redirect to Login View Controller
-(void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 0) {
        [PresenticeUtility instantiateFindFriendsFrom:self animated:NO completion:nil];
    }
}

@end
