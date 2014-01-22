//
//  UserProfileViewController.m
//  Presentice
//
//  Created by レー フックダイ on 1/16/14.
//  Copyright (c) 2014 Presentice. All rights reserved.
//

#import "UserProfileViewController.h"

@interface UserProfileViewController ()

@end

@implementation UserProfileViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = [self.userObj objectForKey:kUserDisplayNameKey];
    
    // Start loading HUD
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    // Set the menu's display
    self.menuItems = [[NSMutableArray alloc] init];
    [self setMenuItems];
    
    // check if the currentUser is following this user
    PFQuery *queryIsFollowing = [PFQuery queryWithClassName:kActivityClassKey];
    [queryIsFollowing whereKey:kActivityTypeKey equalTo:kActivityTypeFollow];
    [queryIsFollowing whereKey:kActivityToUserKey equalTo:self.userObj];
    [queryIsFollowing whereKey:kActivityFromUserKey equalTo:[PFUser currentUser]];
    [queryIsFollowing countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
        if (error) {
            NSLog(@"Couldn't determine follow relationship: %@", error);
            self.followBtn = nil;
        } else {
            if (number == 0) {
                NSLog(@"configureFollowButton");
                [self configureFollowButton];
            } else {
                NSLog(@"configureUnfollowButton");
                [self configureUnfollowButton];
            }
        }
    }];
}
- (void)viewDidAppear:(BOOL)animated {
    // Hid all HUD after all objects appered
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [self.menuItems count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"info";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    UIImageView *thumbnailImageView = (UIImageView *)[cell viewWithTag:100];
    
    if ([[[[self.menuItems objectAtIndex:indexPath.row] objectForKey:@"image"] lowercaseString] hasPrefix:@"http://"]) {
        thumbnailImageView.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[[self.menuItems objectAtIndex:indexPath.row] objectForKey:@"image"]]]];
        thumbnailImageView.highlightedImage = thumbnailImageView.image;
    } else {
        thumbnailImageView.image = [UIImage imageNamed:[[self.menuItems objectAtIndex:indexPath.row] objectForKey:@"image"]];
        thumbnailImageView.highlightedImage = thumbnailImageView.image;
    }
    
    thumbnailImageView.layer.cornerRadius = thumbnailImageView.frame.size.width / 2;
    thumbnailImageView.layer.masksToBounds = YES;
    
    UILabel *info = (UILabel *)[cell viewWithTag:101];
    NSLog(@"%@",[self.menuItems objectAtIndex:indexPath.row]);
    if([[self.menuItems objectAtIndex:indexPath.row] objectForKey:@"info"] != nil) {
        info.text = [[self.menuItems objectAtIndex:indexPath.row] objectForKey:@"info"];
//        [info setTextAlignment:NSTextAlignmentLeft];
//        info.lineBreakMode = NSLineBreakByWordWrapping;
        [info setNumberOfLines:0];
        [info sizeToFit];
    }
    return cell;
}

- (void) setMenuItems {
    
    if([self.userObj objectForKey:kUserDisplayNameKey] != nil){
        NSMutableDictionary *username = [[NSMutableDictionary alloc] init];
        [username setObject:@"username" forKey:@"type"];
        [username setObject:[self.userObj objectForKey:kUserDisplayNameKey] forKey:@"info"];
        [username setObject:[PresenticeUtitily facebookProfilePictureofUser:self.userObj] forKey:@"image"];
        [self.menuItems addObject:username];
    }
    
    if([self.userObj objectForKey:kUserEmailKey]){
        NSMutableDictionary *email = [[NSMutableDictionary alloc] init];
        [email setObject:@"email" forKey:@"type"];
        [email setObject:[self.userObj objectForKey:kUserEmailKey] forKey:@"info"];
        [email setObject:@"email.jpeg" forKey:@"image"];
        [self.menuItems addObject:email];
    }
    
    if([[self.userObj objectForKey:kUserProfileKey] objectForKey:@"location"]){
        NSMutableDictionary *location = [[NSMutableDictionary alloc] init];
        [location setObject:@"location" forKey:@"type"];
        [location setObject:[[[self.userObj objectForKey:kUserProfileKey] objectForKey:@"location"] objectForKey:@"name"]  forKey:@"info"];
        [location setObject:@"map.png" forKey:@"image"];
        [self.menuItems addObject:location];
    }
    
    if([[self.userObj objectForKey:kUserProfileKey] objectForKey:@"hometown"]){
        NSMutableDictionary *hometown = [[NSMutableDictionary alloc] init];
        [hometown setObject:@"hometown" forKey:@"type"];
        [hometown setObject:[[[self.userObj objectForKey:kUserProfileKey] objectForKey:@"hometown"] objectForKey:@"name"]  forKey:@"info"];
        [hometown setObject:@"map.png" forKey:@"image"];
        [self.menuItems addObject:hometown];
    }
    
}

- (IBAction)showLeftMenu:(id)sender {
    [self.menuContainerViewController toggleLeftSideMenuCompletion:nil];
}

- (IBAction)showRightMenu:(id)sender {
    [self.menuContainerViewController toggleRightSideMenuCompletion:nil];
}

- (void)doFollowAction:(id)sender {
    //set to unfollow button
    [self configureUnfollowButton];
    //save to parse.com
    [PresenticeUtitily followUserEventually:self.userObj block:^(BOOL succeeded, NSError *error){
        if(error){
            //set back to follow button
            [self configureFollowButton];
        }
    }];
}
- (void)doUnfollowAction:(id)sender {
    //set to follow button
    [self configureFollowButton];
    //delete from parse.com
    [PresenticeUtitily unfollowUserEventually:self.userObj];
}
- (void)configureFollowButton {
    [self.followBtn setTitle:@"Follow" forState:UIControlStateNormal];
    [self.followBtn addTarget:self action:@selector(doFollowAction:)forControlEvents:UIControlEventTouchDown];
}

- (void)configureUnfollowButton {
    [self.followBtn setTitle:@"Unfollow" forState:UIControlStateNormal];
    [self.followBtn addTarget:self action:@selector(doUnfollowAction:)forControlEvents:UIControlEventTouchDown];
}

- (IBAction)sendMessage:(id)sender {
    UIAlertView *sendMessageAlert = [[UIAlertView alloc] initWithTitle:@"Send Private Message" message:@"Send to this user a private message" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
    sendMessageAlert.tag = 0;
    [sendMessageAlert show];
}

- (IBAction)reportUser:(id)sender {
    UIAlertView *reportUserAlert = [[UIAlertView alloc] initWithTitle:@"Report this User" message:@"Did you find this user suspicious" delegate:self cancelButtonTitle:@"NO" otherButtonTitles:@"YES", nil];
    [reportUserAlert setAlertViewStyle:UIAlertViewStylePlainTextInput];
    [[reportUserAlert textFieldAtIndex:0] setPlaceholder:@"Reason this person is suspicious"];
    reportUserAlert.tag = 1;
    [reportUserAlert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 0) {
        NSLog(@"ask send message");
        if (buttonIndex == 1) {
            NSLog(@"switch to message detail");
            MessageDetailViewController *messageDetailViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"messageDetailViewController"];
            messageDetailViewController.toUser = self.userObj;
            [self.navigationController pushViewController:messageDetailViewController animated:YES];
        }
    } else if (alertView.tag == 1) {
        NSLog(@"ask report user");
        if (buttonIndex == 1) {
            NSString *reportDescription = [alertView textFieldAtIndex:0].text;
            PFObject *reportActivity = [PFObject objectWithClassName:kActivityClassKey];
            [reportActivity setObject:@"reportUser" forKey:kActivityTypeKey];
            [reportActivity setObject:[PFUser currentUser] forKey:kActivityFromUserKey];
            [reportActivity setObject:self.userObj forKey:kActivityToUserKey];
            [reportActivity setObject:reportDescription forKey:kActivityDescriptionKey];
            [reportActivity saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (error) {
                    UIAlertView *reportErrorAlert = [[UIAlertView alloc] initWithTitle:@"Report sending error" message:@"Something went wrong! Please try it agaiin" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
                    reportErrorAlert.tag = 2;
                    [reportErrorAlert show];
                } else {
                    UIAlertView *reportSuccessAlert = [[UIAlertView alloc] initWithTitle:@"Success" message:@"Successfully sent report" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
                    reportSuccessAlert.tag = 2;
                    [reportSuccessAlert show];
                }
            }];
        }
    }
}

@end
