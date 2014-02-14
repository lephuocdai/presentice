//
//  NotificationListViewController.m
//  Presentice
//
//  Created by レー フックダイ on 12/26/13.
//  Copyright (c) 2013 Appcoda. All rights reserved.
//

#import "NotificationListViewController.h"

@interface NotificationListViewController ()

@end

@implementation NotificationListViewController {
}

- (id)initWithCoder:(NSCoder *)aCoder {
    self = [super initWithCoder:aCoder];
    if (self) {
        // Custom the table
        self.parseClassName = kActivityClassKey;
        self.textKey = kActivityTypeKey;
        self.pullToRefreshEnabled = YES;
        self.paginationEnabled = YES;
        self.objectsPerPage = 10;
    }
    
    if ([PFInstallation currentInstallation].badge > 0) {
            [self.tabBarItem setBadgeValue:[NSString stringWithFormat:@"%ld",(long)[PFInstallation currentInstallation].badge]];
        }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Start loading HUD
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    // Reset badge
    if ([self.tabBarItem badgeValue]) {
        PFInstallation *currentInstallation = [PFInstallation currentInstallation];
        if (currentInstallation.badge != 0) {
            currentInstallation.badge = 0;
            [currentInstallation saveEventually];
        }
        [self.tabBarItem setBadgeValue:nil];
    }
    
    // Set refreshTable notification
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshTable:)
                                                 name:@"refreshTable"
                                               object:nil];
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

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:YES];
    
    // Hid all HUD after all objects appered
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    
    [PresenticeUtility checkCurrentUserActivationIn:self];
}

#pragma Parse query
/**
 * query notifications from Activity Table
 * acitivity.toUse = currentUser
**/

- (PFQuery *)queryForTable {
    PFQuery *activitiesQuery = [PFQuery queryWithClassName:self.parseClassName];
    [activitiesQuery whereKey:kActivityTypeKey containedIn:@[@"answer", @"review", @"postQuestion", @"view", @"follow", @"invalidCode", @"suggestReview"]];
    [activitiesQuery includeKey:kActivityFromUserKey];
    [activitiesQuery includeKey:kActivityTargetVideoKey];
    [activitiesQuery includeKey:@"targetVideo.user"];
    [activitiesQuery includeKey:@"targetVideo.asAReplyTo"];
    [activitiesQuery includeKey:@"targetVideo.toUser"];
    [activitiesQuery includeKey:kActivityToUserKey];
    [activitiesQuery whereKey:kActivityToUserKey equalTo:[PFUser currentUser]];
    
    // If no objects are loaded in memory, we look to the cache first to fill the table
    // and then subsequently do a query against the network.
    if ([self.objects count] == 0) {
        activitiesQuery.cachePolicy = kPFCachePolicyCacheThenNetwork;
    }
    
    [activitiesQuery orderByDescending:kUpdatedAtKey];
    return activitiesQuery;
}

// Override to customize the look of a cell representing an object. The default is to display
// a UITableViewCellStyleDefault style cell with the label being the first key in the object.

#pragma mark - UITableViewDataSource

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == self.objects.count) {
        return 50;
    } else {
        PFObject *activity = [self.objects objectAtIndex:indexPath.row];
        if ([[activity objectForKey:kActivityTypeKey] isEqualToString:@"suggestReview"])
            return 55;
        else
            return 50;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object {
    static NSString *simpleTableIdentifier = @"notificationListIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier forIndexPath:indexPath];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
    }
    
    // Configure the cell
    UIImageView *userProfilePicture = (UIImageView *)[cell viewWithTag:100];
    UILabel *description = (UILabel *)[cell viewWithTag:101];
    UILabel *postedTime = (UILabel *)[cell viewWithTag:102];
    //asyn to get profile picture
    [PresenticeUtility setImageView:userProfilePicture forUser:[object objectForKey:kActivityFromUserKey]];
    
    NSString *type = [object objectForKey:kActivityTypeKey];
    if ([type isEqualToString:@"invalidCode"]) {
        description.text = [object objectForKey:kActivityDescriptionKey];
        
    } else if ([type isEqualToString:@"postQuestion"]) {
        description.text = [NSString stringWithFormat:NSLocalizedString(@"%@ has posted a new question %@", nil),
                            [[object objectForKey:kActivityFromUserKey] objectForKey:kUserDisplayNameKey],
                            [[object objectForKey:kActivityTargetVideoKey] objectForKey:kVideoNameKey]];
        [description boldSubstring:[NSString stringWithFormat:@"%@",[[object objectForKey:kActivityFromUserKey] objectForKey:kUserDisplayNameKey]]];
        [description boldSubstring:[NSString stringWithFormat:@"%@",[[object objectForKey:kActivityTargetVideoKey] objectForKey:kVideoNameKey]]];
        
    } else if ([type isEqualToString:@"follow"]) {
        description.text = [NSString stringWithFormat:NSLocalizedString(@"%@ has followed you", nil),
                            [[object objectForKey:kActivityFromUserKey] objectForKey:kUserDisplayNameKey]];
        [description boldSubstring:[NSString stringWithFormat:@"%@",[[object objectForKey:kActivityFromUserKey] objectForKey:kUserDisplayNameKey]]];
        
    }else if ([type isEqualToString:@"suggestReview"]) {
        description.frame = CGRectMake(50, 5, 185, 45);
        NSString *suggester = ([object objectForKey:kActivityFromUserKey] == nil) ? @"Presentice" : [[object objectForKey:kActivityFromUserKey] objectForKey:kUserDisplayNameKey];
        description.text = [NSString stringWithFormat:NSLocalizedString(@"Recommendation from %@: Would you like to review %@'s %@", nil),
                            suggester,
                            [[[object objectForKey:kActivityTargetVideoKey] objectForKey:kVideoToUserKey] objectForKey:kUserDisplayNameKey],
                            [[object objectForKey:kActivityTargetVideoKey] objectForKey:kVideoNameKey]];
        [description boldSubstring:[NSString stringWithFormat:@"%@",suggester]];
        [description boldSubstring:[NSString stringWithFormat:@"%@",[[[object objectForKey:kActivityTargetVideoKey] objectForKey:kVideoToUserKey] objectForKey:kUserDisplayNameKey]]];
        [description boldSubstring:[NSString stringWithFormat:@"%@",[[object objectForKey:kActivityTargetVideoKey] objectForKey:kVideoNameKey]]];
        
    } else if ([type isEqualToString:@"answer"]) {
        description.text = [NSString stringWithFormat:NSLocalizedString(@"%@ has answered your %@", nil),
                            [[object objectForKey:kActivityFromUserKey] objectForKey:kUserDisplayNameKey],
                            [[[object objectForKey:kActivityTargetVideoKey] objectForKey:kVideoAsAReplyTo] objectForKey:kVideoNameKey]];
        [description boldSubstring:[NSString stringWithFormat:@"%@",[[object objectForKey:kActivityFromUserKey] objectForKey:kUserDisplayNameKey]]];
        [description boldSubstring:[NSString stringWithFormat:@"%@",[[[object objectForKey:kActivityTargetVideoKey] objectForKey:kVideoAsAReplyTo] objectForKey:kVideoNameKey]]];
    
    } else if ([type isEqualToString:@"review"]){
        description.text = [NSString stringWithFormat:NSLocalizedString(@"%@ has reviewed your %@", nil),
                            [[object objectForKey:kActivityFromUserKey] objectForKey:kUserDisplayNameKey],
                            [[object objectForKey:kActivityTargetVideoKey] objectForKey:kVideoNameKey]];
        [description boldSubstring:[NSString stringWithFormat:@"%@",[[object objectForKey:kActivityFromUserKey] objectForKey:kUserDisplayNameKey]]];
        [description boldSubstring:[NSString stringWithFormat:@"%@",[[object objectForKey:kActivityTargetVideoKey] objectForKey:kVideoNameKey]]];
    } else if ([type isEqualToString:@"view"]) {
        description.text = [NSString stringWithFormat:NSLocalizedString(@"%@ has viewed your %@", nil),
                            [[object objectForKey:kActivityFromUserKey] objectForKey:kUserDisplayNameKey],
                            [[object objectForKey:kActivityTargetVideoKey] objectForKey:kVideoNameKey]];
        [description boldSubstring:[NSString stringWithFormat:@"%@",[[object objectForKey:kActivityFromUserKey] objectForKey:kUserDisplayNameKey]]];
        [description boldSubstring:[NSString stringWithFormat:@"%@",[[object objectForKey:kActivityTargetVideoKey] objectForKey:kVideoNameKey]]];
    }
    
    
    postedTime.text = [NSString stringWithFormat:@"%@", [[[NSDate alloc] initWithTimeInterval:0 sinceDate:object.updatedAt] dateTimeUntilNow]];
    
    return cell;
}

- (void) objectsDidLoad:(NSError *)error {
    [super objectsDidLoad:error];
    // Hid all HUD after all objects appered
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
}

/**
 * segue for table cell
 * click to direct to video play view
 * pass video name, video url
 */

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
    if (indexPath.row < [self.objects count] ) {
        PFObject *notificationObj = [self.objects objectAtIndex:indexPath.row];
        if ([[notificationObj objectForKey:kActivityTypeKey] isEqualToString:@"answer"]) {
            
            [PresenticeUtility navigateToVideoView:[notificationObj objectForKey:kActivityTargetVideoKey] from:self];
            
        } else if ([[notificationObj objectForKey:kActivityTypeKey] isEqualToString:@"review"]) {
            
            [PresenticeUtility navigateToVideoView:[notificationObj objectForKey:kActivityTargetVideoKey] from:self];
            
        } else if ([[notificationObj objectForKey:kActivityTypeKey] isEqualToString:@"postQuestion"]) {
            
            [PresenticeUtility navigateToVideoView:[notificationObj objectForKey:kActivityTargetVideoKey] from:self];
            
        } else if ([[notificationObj objectForKey:kActivityTypeKey] isEqualToString:@"register"]) {
            
            [PresenticeUtility navigateToUserProfile:[notificationObj objectForKey:kActivityFromUserKey] from:self];
            
        } else if ([[notificationObj objectForKey:kActivityTypeKey] isEqualToString:@"follow"]) {
            
            [PresenticeUtility navigateToUserProfile:[notificationObj objectForKey:kActivityFromUserKey] from:self];
            
        } else if ([[notificationObj objectForKey:kActivityTypeKey] isEqualToString:@"view"]) {
            
            [PresenticeUtility navigateToUserProfile:[notificationObj objectForKey:kActivityFromUserKey] from:self];
            
        } else if ([[notificationObj objectForKey:kActivityTypeKey] isEqualToString:@"invalidCode"]) {
        }
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    } else {
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    }
}

- (IBAction)showLeftMenu:(id)sender {
    [self.menuContainerViewController toggleLeftSideMenuCompletion:nil];
}

- (IBAction)showRightMenu:(id)sender {
    [self.menuContainerViewController toggleRightSideMenuCompletion:nil];
}

#pragma mark - AmazonServiceRequestDelegate

-(void)request:(AmazonServiceRequest *)request didReceiveResponse:(NSURLResponse *)response {
}

- (void)request:(AmazonServiceRequest *)request didReceiveData:(NSData *)data {
}

-(void)request:(AmazonServiceRequest *)request didCompleteWithResponse:(AmazonServiceResponse *)response {
}

-(void)request:(AmazonServiceRequest *)request didFailWithError:(NSError *)error {
    NSLog(@"didFailWithError called: %@", error);
}

-(void)request:(AmazonServiceRequest *)request didFailWithServiceException:(NSException *)exception {
    NSLog(@"didFailWithServiceException called: %@", exception);
}

#pragma Amazon implemented methods

@end
