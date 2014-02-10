//
//  MessageListViewController.m
//  Presentice
//
//  Created by レー フックダイ on 12/26/13.
//  Copyright (c) 2013 Appcoda. All rights reserved.
//

#import "MessageListViewController.h"

@interface MessageListViewController ()

@end

@implementation MessageListViewController {
}

- (id)initWithCoder:(NSCoder *)aCoder {
    self = [super initWithCoder:aCoder];
    if (self) {
        // Custom the table
        self.parseClassName = kMessageClassKey;
        self.textKey = kCreatedAtKey;   // Need to be modified
        self.pullToRefreshEnabled = YES;
        self.paginationEnabled = YES;
        self.objectsPerPage = 10;
    }
    self.tabBarController.hidesBottomBarWhenPushed = YES;
    return self;
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
    
    [self refreshTable:nil];
    
    // Start loading HUD
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    // Set refreshTable notification
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshTable:)
                                                 name:@"refreshTable"
                                               object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    // Hid all HUD after all objects appered
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)refreshTable:(NSNotification *) notification {
    // Reload the recipes
    [self loadObjects];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"refreshTable" object:nil];
}


- (PFQuery *)queryForTable {
    PFQuery *messageListQuery = [PFQuery queryWithClassName:self.parseClassName];
    [messageListQuery whereKey:kMessageUsersKey containsAllObjectsInArray:@[[PFUser currentUser]]];
    [messageListQuery includeKey:kMessageUsersKey];
    [messageListQuery includeKey:kMessageFromUserKey];
    [messageListQuery includeKey:kMessageToUserKey];
    
    // If no objects are loaded in memory, we look to the cache first to fill the table
    // and then subsequently do a query against the network.
    if ([self.objects count] == 0) {
        messageListQuery.cachePolicy = kPFCachePolicyCacheThenNetwork;
    }
    [messageListQuery orderByDescending:kUpdatedAtKey];
    return messageListQuery;
}

#pragma table methods

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object {
    static NSString *cellIdentifier = @"messageListIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    UIImageView *userProfilePicture = (UIImageView *)[cell viewWithTag:100];
    UILabel *userName = (UILabel *)[cell viewWithTag:101];
    UILabel *description = (UILabel *)[cell viewWithTag:102];
    UILabel *postedTime = (UILabel *)[cell viewWithTag:103];
    
    NSMutableArray *users = [[object objectForKey:kMessageUsersKey] mutableCopy];
    NSUInteger currentUserIndex = [self indexOfObjectwithKey:[[PFUser currentUser] objectId] inArray:users];
    [users removeObjectAtIndex:currentUserIndex];
    PFUser *toUser = [users lastObject];
    NSLog(@"toUser = %@", toUser);
    
    if (toUser != (PFUser*)[NSNull null]) {
        [PresenticeUtility setImageView:userProfilePicture forUser:toUser];
        userName.text = [toUser objectForKey:kUserDisplayNameKey];
    } else {
        userName.text = @"Unknown user";
    }
    description.text = [[[object objectForKey:kMessageContentKey] lastObject] objectForKey:@"text"];
    postedTime.text = [NSString stringWithFormat:@"%@", [[[NSDate alloc] initWithTimeInterval:0 sinceDate:[[[object objectForKey:kMessageContentKey] lastObject] objectForKey:@"date"]] dateTimeUntilNow]];
    
    return cell;
}


- (void) objectsDidLoad:(NSError *)error {
    [super objectsDidLoad:error];
    NSLog(@"objectsDidLoad message list error: %@", [error localizedDescription]);
    // Hid all HUD after all objects appered
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
    if (indexPath.row < self.objects.count) {
        PFObject *selectedObject = [self objectAtIndexPath:indexPath];
        NSMutableArray *users = [[selectedObject objectForKey:kMessageUsersKey] mutableCopy];
        NSUInteger currentUserIndex = [self indexOfObjectwithKey:[[PFUser currentUser] objectId] inArray:users];
        [users removeObjectAtIndex:currentUserIndex];
        PFUser *toUser = [users lastObject];
        
        if (toUser != (PFUser*)[NSNull null]) {
            
            MessageDetailViewController *destViewController = [[MessageDetailViewController alloc] init];
            destViewController.toUser = toUser;
            destViewController.messageObj = selectedObject;
            
            // Start loading HUD
            [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            
            destViewController.hidesBottomBarWhenPushed = YES;
            [self.navigationController pushViewController:destViewController animated:YES];
        } else {
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
            UIAlertView *noUserAlert = [[UIAlertView alloc] initWithTitle:@"Unknown user" message:@"This user has resigned or deactivated." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
            [noUserAlert show];
        }
    } else {
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    }
}

- (NSUInteger)indexOfObjectwithKey:(NSString*)key inArray: (NSArray*)array {
    
    for (NSUInteger i = 0; i < [array count]; i++) {
        NSString *objectId = [[array objectAtIndex:i] valueForKey:@"objectId"];
        if ([objectId isEqualToString:key]) {
            return i;
        }
    }
    return 100;
}

- (IBAction)showLeftMenu:(id)sender {
    [self.menuContainerViewController toggleLeftSideMenuCompletion:nil];
}

- (IBAction)showRightMenu:(id)sender {
    [self.menuContainerViewController toggleRightSideMenuCompletion:nil];
}
    
@end
