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
        
        // The className to query on
        self.parseClassName = kMessageClassKey;
        
        // The key of the PFObject to display in the label of the default cell style
        self.textKey = kCreatedAtKey;   // Need to be modified
        
        // Whether the built-in pull-to-refresh is enabled
        self.pullToRefreshEnabled = YES;
        
        // Whether the built-in pagination is enabled
        self.paginationEnabled = YES;
        
        // The number of objects to show per page
        self.objectsPerPage = 5;
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
    
    NSLog(@"get in message list");
    
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

/**
 * override function
 * load table for each time load view
 */
//- (void) viewWillAppear:(BOOL)animated {
//    messageList = [[NSMutableArray alloc] init];
//    [self queryMessageList];
//    [self.tableView reloadData];
//}

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
    
    //asyn to get profile picture
    NSMutableArray *users = [[object objectForKey:kMessageUsersKey] mutableCopy];
//    NSLog(@"users count before = %d", [users count]);
    
    NSUInteger currentUserIndex = [self indexOfObjectwithKey:[[PFUser currentUser] objectId] inArray:users];
//    NSLog(@"currentUserIndex = %lu", (unsigned long)currentUserIndex);
    
    [users removeObjectAtIndex:currentUserIndex];
    
//    NSLog(@"users count after = %d", [users count]);
    PFUser *toUser = [users lastObject];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSData *profileImageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:[PresenticeUtitily facebookProfilePictureofUser:toUser]]];
        dispatch_async(dispatch_get_main_queue(), ^{
            userProfilePicture.image = [UIImage imageWithData:profileImageData];
            userProfilePicture.highlightedImage = [UIImage imageWithData:profileImageData];
            userProfilePicture.layer.cornerRadius = userProfilePicture.frame.size.width / 2;
            userProfilePicture.layer.masksToBounds = YES;
        });
    });
    userName.text = [toUser objectForKey:kUserDisplayNameKey];
    description.text = [[[object objectForKey:kMessageContentKey] lastObject] objectForKey:@"text"];
    
//    cell.textLabel.text = [[[object objectForKey:kMessageContentKey] lastObject] objectForKey:@"text"];
    return cell;
}


- (void) objectsDidLoad:(NSError *)error {
    [super objectsDidLoad:error];
    NSLog(@"objectsDidLoad message list error: %@", [error localizedDescription]);
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    PFObject *selectedObject = [self objectAtIndexPath:indexPath];
    
    MessageDetailViewController *destViewController = [[MessageDetailViewController alloc] init];
    
    NSMutableArray *users = [[selectedObject objectForKey:kMessageUsersKey] mutableCopy];
    NSUInteger currentUserIndex = [self indexOfObjectwithKey:[[PFUser currentUser] objectId] inArray:users];
    [users removeObjectAtIndex:currentUserIndex];
    PFUser *toUser = [users lastObject];
    destViewController.toUser = toUser;
    destViewController.messageObj = selectedObject;
    
    // Start loading HUD
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
//    NSLog(@"destViewController.messageObj = %@",destViewController.messageObj);
    [self.navigationController pushViewController:destViewController animated:YES];
}

- (NSUInteger)indexOfObjectwithKey:(NSString*)key inArray: (NSArray*)array {
//    NSLog(@"key = %@", key);
//    NSLog(@"array = %@", array);
    
    for (NSUInteger i = 0; i < [array count]; i++) {
        NSString *objectId = [[array objectAtIndex:i] valueForKey:@"objectId"];
//        NSLog(@"i = %d objectId = %@", i, objectId);
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
