//
//  MyProfileViewController.m
//  Presentice
//
//  Created by レー フックダイ on 1/9/14.
//  Copyright (c) 2014 Presentice. All rights reserved.
//

#import "MyProfileViewController.h"

@interface MyProfileViewController ()
@end

@implementation MyProfileViewController {
//    NSString *profilePictureURL;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = [[PFUser currentUser] objectForKey:kUserDisplayNameKey];
    
    // Start loading HUD
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    //load information in background
    dispatch_async(dispatch_get_main_queue(), ^{
        // Set the menu's display
        self.menuItems = [[NSMutableArray alloc] init];
        [self setMenuItems];
        [self.tableView reloadData];
        // Hid all HUD after all objects appered
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    });
}

- (void)viewDidAppear:(BOOL)animated {
    // Hid all HUD after all objects appered
    //[MBProgressHUD hideAllHUDsForView:self.view animated:YES];
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
    if (indexPath.row == 0) {
        NSString *simpleTableIdentifier = @"facebook";
        
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
        }
        
        // Configure the cell
        UIImageView *thumbnailImageView = (UIImageView *)[cell viewWithTag:100];
        if ([[[[self.menuItems objectAtIndex:indexPath.row] objectForKey:@"image"] lowercaseString] hasPrefix:@"http://"]) {
            thumbnailImageView.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[[self.menuItems objectAtIndex:indexPath.row] objectForKey:@"image"]]]];
        } else {
            thumbnailImageView.image = [UIImage imageNamed:[[self.menuItems objectAtIndex:indexPath.row] objectForKey:@"image"]];
        }
        thumbnailImageView.highlightedImage = thumbnailImageView.image;
        
        UILabel *info = (UILabel *)[cell viewWithTag:101];
        NSLog(@"%@",[self.menuItems objectAtIndex:indexPath.row]);
        if([[self.menuItems objectAtIndex:indexPath.row] objectForKey:@"info"] != nil) {
            info.text = [[self.menuItems objectAtIndex:indexPath.row] objectForKey:@"info"];
            [info setTextAlignment:NSTextAlignmentLeft];
            info.lineBreakMode = NSLineBreakByWordWrapping;
            [info setNumberOfLines:0];
            [info sizeToFit];
        }
        return cell;
        
    } else if (indexPath.row == 1) {
        NSString *simpleTableIdentifier = @"changePassword";
        
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
        }
        return cell;
        
    } else {
        NSString *simpleTableIdentifier = @"otherInfo";
        
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
        }
        
        UILabel *type = (UILabel *)[cell viewWithTag:300];
        UILabel *content = (UILabel *)[cell viewWithTag:301];
        
        if([[self.menuItems objectAtIndex:indexPath.row] objectForKey:@"info"] != nil) {
            type.text = [[self.menuItems objectAtIndex:indexPath.row] objectForKey:@"type"];
            content.text = [[self.menuItems objectAtIndex:indexPath.row] objectForKey:@"info"];
            [content setTextAlignment:NSTextAlignmentLeft];
            content.lineBreakMode = NSLineBreakByWordWrapping;
            [content setNumberOfLines:0];
            [content sizeToFit];
        }
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString *cellType = [[self.menuItems objectAtIndex:indexPath.row] objectForKey:@"type"];
    NSLog(@"cellType = %@", cellType);
    if ([cellType isEqualToString:@"username"]) {
        [self.navigationController pushViewController:[PresenticeUtitily facebookPageOfUser:[PFUser currentUser]] animated:YES];
    } else if ([cellType isEqual:@"pushPermission"] ) {
        NSLog(@"get in side");
        PushPermissionViewController *destViewController = [[PushPermissionViewController alloc] initWithStyle:UITableViewStyleGrouped];
        if ([destViewController isKindOfClass:[PushPermissionViewController class]]) {
            destViewController.delegate = self;
        }
        destViewController.pushPermission = [[NSMutableDictionary alloc] initWithDictionary:[[PFUser currentUser] objectForKey:@"pushPermission"]];
        [self.navigationController pushViewController:destViewController animated:YES];
    }
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"toLoginView"]) {
        [PFUser logOut];
    } else if ([segue.identifier isEqualToString:@"changePassword"]){
        [PFUser requestPasswordResetForEmailInBackground:[PFUser currentUser].email block:^(BOOL succeeded, NSError *error) {
            if (error) {
                NSString *alertMessage = @"Sorry for the inconvenience, please contact us at: info@presentice.com";
                UIAlertView *passwordResetAlert = [[UIAlertView alloc] initWithTitle:@"Something went wrong" message:alertMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
                passwordResetAlert.tag = 0;
                [passwordResetAlert show];
            } else {
                NSString *alertMessage = [NSString stringWithFormat:@"An email from our provider Parse has been sent to you. Please check you email: %@", [PFUser currentUser].email];
                UIAlertView *passwordResetAlert = [[UIAlertView alloc] initWithTitle:@"Confirmation email sent" message:alertMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
                passwordResetAlert.tag = 1;
                [passwordResetAlert show];
                [PFUser logOut];
            }
        }];
    }
}

- (void) setMenuItems {
    
    if([[PFUser currentUser] objectForKey:kUserDisplayNameKey] != nil){
        NSMutableDictionary *username = [[NSMutableDictionary alloc] init];
        [username setObject:@"username" forKey:@"type"];
        [username setObject:[[PFUser currentUser] objectForKey:kUserDisplayNameKey] forKey:@"info"];
        [username setObject:[PresenticeUtitily facebookProfilePictureofUser:[PFUser currentUser]] forKey:@"image"];
        [self.menuItems addObject:username];
     
        
        NSMutableDictionary *changePassword = [[NSMutableDictionary alloc] init];
        [changePassword setObject:@"changePassword" forKey:@"type"];
        [changePassword setObject:@"Change Password" forKey:@"info"];
        [self.menuItems addObject:changePassword];
    }
    
    if([[PFUser currentUser] objectForKey:kUserEmailKey]){
        NSMutableDictionary *email = [[NSMutableDictionary alloc] init];
        [email setObject:@"email" forKey:@"type"];
        [email setObject:[[PFUser currentUser] objectForKey:kUserEmailKey] forKey:@"info"];
        [email setObject:@"email.jpeg" forKey:@"image"];
        [self.menuItems addObject:email];
    }

    if([[[PFUser currentUser] objectForKey:kUserProfileKey] objectForKey:@"location"]){
        NSMutableDictionary *location = [[NSMutableDictionary alloc] init];
        [location setObject:@"location" forKey:@"type"];
        [location setObject:[[[[PFUser currentUser] objectForKey:kUserProfileKey] objectForKey:@"location"] objectForKey:@"name"]  forKey:@"info"];
        [location setObject:@"map.png" forKey:@"image"];
        [self.menuItems addObject:location];
    }

    if([[[PFUser currentUser] objectForKey:kUserProfileKey] objectForKey:@"hometown"]){
        NSMutableDictionary *hometown = [[NSMutableDictionary alloc] init];
        [hometown setObject:@"hometown" forKey:@"type"];
        [hometown setObject:[[[[PFUser currentUser] objectForKey:kUserProfileKey] objectForKey:@"hometown"] objectForKey:@"name"]  forKey:@"info"];
        [hometown setObject:@"map.png" forKey:@"image"];
        [self.menuItems addObject:hometown];
    }
    
    if([[PFUser currentUser] objectForKey:@"pushPermission"]){
        NSDictionary *permission = [[PFUser currentUser] objectForKey:@"pushPermission"];
        NSMutableDictionary *pushPermission = [[NSMutableDictionary alloc] init];
        [pushPermission setObject:@"pushPermission" forKey:@"type"];
        [pushPermission setObject:[NSString stringWithFormat:@"viewed:%@, reviewed:%@, answered:%@, message:%@",
                                   [permission objectForKey:@"viewed"],
                                   [permission objectForKey:@"reviewed"],
                                   [permission objectForKey:@"answered"],
                                   [permission objectForKey:@"message"]] forKey:@"info"];
        [pushPermission setObject:@"map.png" forKey:@"image"];
        [self.menuItems addObject:pushPermission];
    }
}

- (IBAction)showLeftMenu:(id)sender {
    [self.menuContainerViewController toggleLeftSideMenuCompletion:nil];
}

- (void)receiveData:(NSMutableDictionary *)permission {
    [self.menuItems removeObjectAtIndex:4];
    
    NSMutableDictionary *pushPermission = [[NSMutableDictionary alloc] init];
    [pushPermission setObject:@"pushPermission" forKey:@"type"];
    [pushPermission setObject:[NSString stringWithFormat:@"viewed:%@, reviewed:%@, answered:%@, message:%@",
                               [permission objectForKey:@"viewed"],
                               [permission objectForKey:@"reviewed"],
                               [permission objectForKey:@"answered"],
                               [permission objectForKey:@"message"]] forKey:@"info"];
    [pushPermission setObject:@"map.png" forKey:@"image"];
    [self.menuItems insertObject:pushPermission atIndex:4];    
    [self.tableView reloadData];
}

@end
