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
    return cell;
}

#pragma mark -
#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1) {
        if(indexPath.row == 0){
            MainViewController *mainViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"mainViewController"];
            UINavigationController *navigationController = self.menuContainerViewController.centerViewController;
            NSArray *controllers = [NSArray arrayWithObject:mainViewController];
            navigationController.viewControllers = controllers;
        } else if(indexPath.row == 1) {
            QuestionListViewController *questionListViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"questionListViewController"];
            UINavigationController *navigationController = self.menuContainerViewController.centerViewController;
            NSArray *controllers = [NSArray arrayWithObject:questionListViewController];
            navigationController.viewControllers = controllers;
        } else if(indexPath.row == 2){
            MyListViewController *myListViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"myListViewController"];
            UINavigationController *navigationController = self.menuContainerViewController.centerViewController;
            NSArray *controllers = [NSArray arrayWithObject:myListViewController];
            navigationController.viewControllers = controllers;
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
            MessageListViewController *messageListViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"notificationListViewController"];
            UINavigationController *navigationController = self.menuContainerViewController.centerViewController;
            NSArray *controllers = [NSArray arrayWithObject:messageListViewController];
            navigationController.viewControllers = controllers;
            
        }else if(indexPath.row == 4){
            NotificationListViewController *notificationListViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"settingViewController"];
            UINavigationController *navigationController = self.menuContainerViewController.centerViewController;
            NSArray *controllers = [NSArray arrayWithObject:notificationListViewController];
            navigationController.viewControllers = controllers;
        }
    } else if (indexPath.section == 2) {
        if(indexPath.row == 0){
            ShareViewController *shareViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"messageListViewController"];
            UINavigationController *navigationController = self.menuContainerViewController.centerViewController;
            NSArray *controllers = [NSArray arrayWithObject:shareViewController];
            navigationController.viewControllers = controllers;
        }else if(indexPath.row == 1){
            SettingViewController *settingViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"shareViewController"];
            UINavigationController *navigationController = self.menuContainerViewController.centerViewController;
            NSArray *controllers = [NSArray arrayWithObject:settingViewController];
            navigationController.viewControllers = controllers;
        }
    }
    [self.menuContainerViewController setMenuState:MFSideMenuStateClosed];
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

 */

@end
