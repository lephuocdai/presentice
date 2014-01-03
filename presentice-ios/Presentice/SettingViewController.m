//
//  PhotoViewController.m
//  SidebarDemo
//
//  Created by Simon on 30/6/13.
//  Copyright (c) 2013 Appcoda. All rights reserved.
//

#import "SettingViewController.h"

@interface SettingViewController ()

@property (nonatomic, strong) NSMutableArray *menuItems;

@end


@implementation SettingViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Start loading HUD
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    // Set the side bar button action. When it's tapped, it'll show up the sidebar.
    _sidebarButton.target = self.revealViewController;
    _sidebarButton.action = @selector(revealToggle:);
    
    // Set the gesture
    [self.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];
    
    // Set the menu's display
    self.menuItems = [[NSMutableArray alloc] init];
    [self setMenuItems];
}

- (void)viewDidAppear:(BOOL)animated {
    // Hid all HUD after all objects appered
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
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
    
    static NSString *simpleTableIdentifier = @"info";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
    }
    
    // // Configure the cell
    
    UIImageView *thumbnailImageView = (UIImageView *)[cell viewWithTag:100];
    thumbnailImageView.image = [UIImage imageNamed:[[self.menuItems objectAtIndex:indexPath.row] objectForKey:@"image"]];
    
    UILabel *info = (UILabel *)[cell viewWithTag:101];
    info.text = [[self.menuItems objectAtIndex:indexPath.row] objectForKey:@"info"];
    
//    UILabel *email = (UILabel *)[cell viewWithTag:102];
    
    return cell;
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"toLoginView"]) {
        [PFUser logOut];
    }
}

- (void) setMenuItems {
    
    NSMutableDictionary *username = [[NSMutableDictionary alloc] init];
    [username setObject:[[PFUser currentUser] objectForKey:kUserDisplayNameKey] forKey:@"info"];
    [username setObject:@"myList.jpeg" forKey:@"image"];
    [self.menuItems addObject:username];
    
    NSMutableDictionary *email = [[NSMutableDictionary alloc] init];
    [email setObject:[[PFUser currentUser] objectForKey:kUserEmailKey] forKey:@"info"];
    [email setObject:@"email.jpeg" forKey:@"image"];
    [self.menuItems addObject:email];
    
    NSMutableDictionary *location = [[NSMutableDictionary alloc] init];
    [location setObject:[[[[PFUser currentUser] objectForKey:kUserProfileKey] objectForKey:@"location"] objectForKey:@"name"]  forKey:@"info"];
    [location setObject:@"map.png" forKey:@"image"];
    [self.menuItems addObject:location];
    
    NSMutableDictionary *hometown = [[NSMutableDictionary alloc] init];
    [hometown setObject:[[[[PFUser currentUser] objectForKey:kUserProfileKey] objectForKey:@"hometown"] objectForKey:@"name"]  forKey:@"info"];
    [hometown setObject:@"map.png" forKey:@"image"];
    [self.menuItems addObject:hometown];
    
}

@end
