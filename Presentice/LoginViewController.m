//
//  LoginViewController.m
//  Presentice
//
//  Created by PhuongNQ on 12/21/13.
//  Copyright (c) 2013 Appcoda. All rights reserved.
//

#import "LoginViewController.h"

NSDictionary<FBGraphUser> *me;

@interface LoginViewController ()

@end

@implementation LoginViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //if user already login, redirect to MainViewController
	if([PFUser currentUser] && [PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]){
        [self performSegueWithIdentifier:@"toMainView" sender:self];

    }
}
- (void) viewWillAppear:(BOOL)animated {
    //hide navigator if in login view
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) loginFB {
    // Set permissions required from the facebook user account
    NSArray *permissionsArray = @[ @"user_about_me", @"user_relationships", @"user_birthday", @"user_location", @"email"];
    
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
            if (user.isNew) {
                NSLog(@"User with facebook signed up and logged in!");
            } else {
                NSLog(@"User with facebook logged in!");
            }
            [FBRequestConnection startForMeWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                if(!error){
                    NSDictionary<FBGraphUser> *me = (NSDictionary<FBGraphUser> *)result;
                    // Store the Facebook Id
                    [[PFUser currentUser] setObject:[NSNumber numberWithBool:NO] forKey:@"activated"];
                    [[PFUser currentUser] setObject:me.id forKey:@"facebookId"];
                    [[PFUser currentUser] setObject:me.name forKey:@"displayName"];
                    [[PFUser currentUser] setObject:[me objectForKey:@"email"] forKey:@"email"];
                    [[PFUser currentUser] saveInBackground];
                }
            }];
            [self performSegueWithIdentifier:@"toMainView" sender:self];
        }
    }];
}

- (IBAction)didPressLoginButton:(id)sender {
    NSString *username = self.tbUsername.text;
    NSString *password = self.tbPassword.text;
    
    [PFUser logInWithUsernameInBackground:username password:password block:^(PFUser *user, NSError *error) {
        if(!error){
            NSLog(@"login succeeded!");
        } else {
            NSLog(@"login fail");
        }
    }];
}

- (IBAction)didPressRegisterButton:(id)sender {
    // Set permissions required from the facebook user account
    NSArray *permissionsArray = @[ @"user_about_me", @"user_relationships", @"user_birthday", @"user_location", @"email"];
    
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
            if (user.isNew) {
                NSLog(@"User with facebook signed up and logged in!");
            } else {
                NSLog(@"User with facebook logged in!");
            }
            
            [FBRequestConnection startForMeWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                if(!error){
                    me = (NSDictionary<FBGraphUser> *)result;
                    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
                    RegisterViewController *destViewController = (RegisterViewController *)[storyboard instantiateViewControllerWithIdentifier:@"RegisterViewController"];
                    destViewController.email = [me objectForKey:@"email"];
                    [self.navigationController pushViewController:destViewController animated:YES];
                }
                //dismiss hub
                [MBProgressHUD hideHUDForView:self.view animated:YES];
            }];
        }
    }];
}
- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    //show navigator
    [self.navigationController setNavigationBarHidden:NO animated:YES];
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
@end
