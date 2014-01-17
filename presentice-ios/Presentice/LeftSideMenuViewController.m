//
//  LeftSideMenuViewController.m
//  Presentice
//
//  Created by レー フックダイ on 1/12/14.
//  Copyright (c) 2014 Presentice. All rights reserved.
//

#import "LeftSideMenuViewController.h"

@interface LeftSideMenuViewController ()

@property (nonatomic, strong) NSArray *menuItems;

@end

@implementation LeftSideMenuViewController

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor colorWithWhite:0.2f alpha:1.0f];
    self.tableView.backgroundColor = [UIColor colorWithWhite:0.2f alpha:1.0f];
    self.tableView.separatorColor = [UIColor colorWithWhite:0.15f alpha:0.2f];
    
    _menuItems = @[@"title", @"timeline", @"questionList", @"myList", @"notification", @"setting", @"message", @"postQuestion"];
    
    // Set my List videoNum
    self.videoNumLabel.text = @"undefined";
    
    // Set notification badge
    if ([PFInstallation currentInstallation]) {
        self.notifyNumLabel.text = [NSString stringWithFormat:@"%ld",(long)[PFInstallation currentInstallation].badge];
    } else {
        self.notifyNumLabel.text = @"0";
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -
#pragma mark - UITableViewDataSource
/**
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [NSString stringWithFormat:@"Left %d", section];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.menuItems count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
}
**/
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    
    if (indexPath.section == 1 && indexPath.row == 4) {
        UIImageView *userProfilePicture = (UIImageView *)[cell viewWithTag:100];
        UILabel *user = (UILabel *)[cell viewWithTag:101];
        userProfilePicture.image = [UIImage imageWithData:
                                    [NSData dataWithContentsOfURL:
                                     [NSURL URLWithString:
                                      [Constants facebookProfilePictureofUser:
                                       [PFUser currentUser]]]]];
        user.text = [[PFUser currentUser] objectForKey:kUserDisplayNameKey];
    }
    
    return cell;
}

#pragma mark -
#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1) {
        if(indexPath.row == 0){
            MainViewController *mainViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"mainViewController"];
            UINavigationController *centerViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"mainNavigationController"];
            [self.menuContainerViewController setCenterViewController:centerViewController];
            NSArray *controllers = [NSArray arrayWithObject:mainViewController];
            centerViewController.viewControllers = controllers;
        } else if(indexPath.row == 1) {
            QuestionListViewController *questionListViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"questionListViewController"];
            UINavigationController *centerViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"mainNavigationController"];
            [self.menuContainerViewController setCenterViewController:centerViewController];
            NSArray *controllers = [NSArray arrayWithObject:questionListViewController];
            centerViewController.viewControllers = controllers;
        } else if(indexPath.row == 2){
            MyListViewController *myListViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"myListViewController"];
            UINavigationController *centerViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"mainNavigationController"];
            [self.menuContainerViewController setCenterViewController:centerViewController];
            NSArray *controllers = [NSArray arrayWithObject:myListViewController];
            centerViewController.viewControllers = controllers;
        } else if(indexPath.row == 3){
            
            // Reset notification badge
            if (![self.notifyNumLabel.text isEqualToString:@"0"]) {
                PFInstallation *currentInstallation = [PFInstallation currentInstallation];
                if (currentInstallation.badge != 0) {
                    currentInstallation.badge = 0;
                    [currentInstallation saveEventually];
                }
                self.notifyNumLabel.text = @"0";
            }
            
            // Perform the transition
            NotificationListViewController *notificationListViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"notificationListViewController"];
            UINavigationController *centerViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"mainNavigationController"];
            [self.menuContainerViewController setCenterViewController:centerViewController];
            NSArray *controllers = [NSArray arrayWithObject:notificationListViewController];
            centerViewController.viewControllers = controllers;
            
        }else if(indexPath.row == 4){
            SettingViewController *settingViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"settingViewController"];
            UINavigationController *centerViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"mainNavigationController"];
            [self.menuContainerViewController setCenterViewController:centerViewController];
            NSArray *controllers = [NSArray arrayWithObject:settingViewController];
            centerViewController.viewControllers = controllers;
        }
    } else if (indexPath.section == 2) {
        if(indexPath.row == 0){
            MessageListViewController *messageListViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"messageListViewController"];
            UINavigationController *messageListNavigationController = [[UINavigationController alloc]initWithRootViewController:messageListViewController];

            FriendListViewController *friendListViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"friendListViewController"];
            UINavigationController *friendListNavigationController = [[UINavigationController alloc]initWithRootViewController:friendListViewController];
            
            UITabBarController *messageTabBarController = [[UITabBarController alloc] init];
            [messageTabBarController setViewControllers:[NSArray arrayWithObjects:messageListNavigationController, friendListNavigationController, nil]];
            [self.menuContainerViewController setCenterViewController:messageTabBarController];
            UITabBarController *tabBarController = self.menuContainerViewController.centerViewController;
            UINavigationController *navigationController = (UINavigationController *)tabBarController.selectedViewController;
            NSArray *controllers = [NSArray arrayWithObject:messageListViewController];
            navigationController.viewControllers = controllers;
            
        }else if(indexPath.row == 1){
            ShareViewController *shareViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"shareViewController"];
            UINavigationController *centerViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"mainNavigationController"];
            [self.menuContainerViewController setCenterViewController:centerViewController];
            NSArray *controllers = [NSArray arrayWithObject:shareViewController];
            centerViewController.viewControllers = controllers;
        }
    }
    [self.menuContainerViewController setMenuState:MFSideMenuStateClosed];
}

@end
