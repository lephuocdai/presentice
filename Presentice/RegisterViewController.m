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

@end

@implementation RegisterViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/**
 * end of editing
 * dissmis input keyboard
 **/
- (void)touchesEnded: (NSSet *)touches withEvent: (UIEvent *)event {
	for (UIView* view in self.view.subviews) {
		if ([view isKindOfClass:[UITextField class]])
			[view resignFirstResponder];
	}
}

/**
* load data from facebook
* input automatically to input fields
**/
-(void) loadDataFromFB {
    [FBRequestConnection startForMeWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if(!error){
            fbInfo = (NSDictionary<FBGraphUser> *)result;
            self.emailField.text = [fbInfo objectForKey:@"email"];
            
        }
        
    }];
}

- (IBAction)didClickRegisterButton:(id)sender {
    
    //check password
    if(![self.passwordField.text isEqualToString:self.confirmPasswordField.text]){
        UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Sign Up Error" message:@"Password not matched. Please check inputed password again!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil , nil];
        [errorAlert show];
        return;
    }
    
    PFUser *newUser = [PFUser user];
    newUser.username = self.emailField.text;
    newUser.password = self.passwordField.text;
    newUser.email = self.emailField.text;
    [newUser setObject:[NSNumber numberWithBool:NO] forKey:kUserActivatedKey];
    [newUser setObject:fbInfo.id forKey:kUserFacebookIdKey];
    [newUser setObject:fbInfo.name forKey:kUserDisplayNameKey];
    [newUser setObject:fbInfo forKey:kUserProfileKey];
    
    [newUser signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (!error) {
            NSLog(@"register succeed!");
            
            //show succeeded alert
            UIAlertView *succeedAlert = [[UIAlertView alloc] initWithTitle:@"Sign Up Succeeded" message:@"Click OK to go to login screen" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [succeedAlert show];
            
            } else {
                //error message
                NSString *errorString = [error userInfo][@"error"];
                
                //show errored alert
                UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Sign Up Error" message:errorString delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                [errorAlert show];
        }
    }];
}

#pragma alertDelegate
// redirect to Login View Controller
-(void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
    RegisterViewController *destViewController = (RegisterViewController *)[storyboard instantiateViewControllerWithIdentifier:@"LoginViewController"];
    [self.navigationController pushViewController:destViewController animated:YES];

}
@end
