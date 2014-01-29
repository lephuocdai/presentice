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
    
    self.view.backgroundColor = [UIColor colorWithRed:40.0/255 green:40.0/255 blue:50.0/255 alpha:1];
    
    _menuItems = @[@"profile", @"home", @"message"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -
#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    cell.selectedBackgroundView = [[UIView alloc] initWithFrame:cell.bounds] ;
    cell.selectedBackgroundView.backgroundColor = [UIColor colorWithRed:40.0/255 green:40.0/255 blue:50.0/255 alpha:1];
    
    // Get facebook profile picture
    if (indexPath.section == 0 && indexPath.row == 0) {
        UIImage *image = [UIImage imageWithData:
                          [NSData dataWithContentsOfURL:
                           [NSURL URLWithString:
                            [PresenticeUtitily facebookProfilePictureofUser:
                             [PFUser currentUser]]]]];
        if (image != nil) {
            UIImageView *userProfilePicture = (UIImageView *)[cell viewWithTag:100];
            userProfilePicture.image = image;
            userProfilePicture.highlightedImage = image;
            userProfilePicture.layer.cornerRadius = userProfilePicture.frame.size.width / 2;
            userProfilePicture.layer.masksToBounds = YES;
        }
    }
    
    return cell;
}

#pragma mark -
#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        if(indexPath.row == 0) {
            MyProfileViewController *myProfileViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"settingViewController"];
            UINavigationController *centerViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"mainNavigationController"];
            [self.menuContainerViewController setCenterViewController:centerViewController];
            NSArray *controllers = [NSArray arrayWithObject:myProfileViewController];
            centerViewController.viewControllers = controllers;
        } else if (indexPath.row == 1) {
            /**
            // Reset notification badge
            if (![self.notifyNumLabel.text isEqualToString:@"0"]) {
                PFInstallation *currentInstallation = [PFInstallation currentInstallation];
                if (currentInstallation.badge != 0) {
                    currentInstallation.badge = 0;
                    [currentInstallation saveEventually];
                }
                self.notifyNumLabel.text = @"0";
            }
            **/
            MainViewController *mainViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"mainViewController"];
            UINavigationController *mainNavigationController = [[UINavigationController alloc]initWithRootViewController:mainViewController];
            
            QuestionListViewController *questionListViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"questionListViewController"];
            UINavigationController *questionListNavigationController = [[UINavigationController alloc]initWithRootViewController:questionListViewController];
            
            MyListViewController *myListViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"myListViewController"];
            UINavigationController *myListNavigationController = [[UINavigationController alloc]initWithRootViewController:myListViewController];
            
            NotificationListViewController *notificationListViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"notificationListViewController"];
            UINavigationController *notificationListNavigationController = [[UINavigationController alloc]initWithRootViewController:notificationListViewController];
            
            UITabBarController *homeTabBarController = [[UITabBarController alloc] init];
            [homeTabBarController setViewControllers:[NSArray arrayWithObjects:mainNavigationController, questionListNavigationController, myListNavigationController, notificationListNavigationController, nil]];
            [self.menuContainerViewController setCenterViewController:homeTabBarController];
            
            UINavigationController *navigationController = (UINavigationController *)homeTabBarController.selectedViewController;
            NSArray *controllers = [NSArray arrayWithObject:mainViewController];
            navigationController.viewControllers = controllers;
        } else if (indexPath.row == 2) {
            MessageListViewController *messageListViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"messageListViewController"];
            UINavigationController *messageListNavigationController = [[UINavigationController alloc]initWithRootViewController:messageListViewController];

            FriendListViewController *friendListViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"friendListViewController"];
            UINavigationController *friendListNavigationController = [[UINavigationController alloc]initWithRootViewController:friendListViewController];
            
            UITabBarController *messageTabBarController = [[UITabBarController alloc] init];
            [messageTabBarController setViewControllers:[NSArray arrayWithObjects:messageListNavigationController, friendListNavigationController, nil]];
            [self.menuContainerViewController setCenterViewController:messageTabBarController];
            UINavigationController *navigationController = (UINavigationController *)messageTabBarController.selectedViewController;
            NSArray *controllers = [NSArray arrayWithObject:messageListViewController];
            navigationController.viewControllers = controllers;
        }
    }
    [self.menuContainerViewController setMenuState:MFSideMenuStateClosed];
}

@end
