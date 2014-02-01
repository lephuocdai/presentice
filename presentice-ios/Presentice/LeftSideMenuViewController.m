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
    UIImageView *userProfilePicture = (UIImageView *)[cell viewWithTag:100];
    [PresenticeUtility setImageView:userProfilePicture forUser:[PFUser currentUser]];
    
    return cell;
}

#pragma mark -
#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        if(indexPath.row == 0) {
            [PresenticeUtility navigateToMyProfileFrom:self];
        } else if (indexPath.row == 1) {
            [PresenticeUtility navigateToHomeScreenFrom:self];
        } else if (indexPath.row == 2) {
            [PresenticeUtility navigateToMessageScreenFrom:self];
        }
    }
}

@end
