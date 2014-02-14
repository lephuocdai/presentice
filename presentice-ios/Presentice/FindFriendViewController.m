//
//  FindFriendViewController.m
//  Presentice
//
//  Created by PhuongNQ on 1/18/14.
//  Copyright (c) 2014 Presentice. All rights reserved.
//

#import "FindFriendViewController.h"
typedef enum {
    FindFriendsFollowingNone = 0,    // User isn't following anybody in Friends list
    FindFriendsFollowingAll,         // User is following all Friends
    FindFriendsFollowingSome         // User is following some of their Friends
} FindFriendsFollowStatus;
@interface FindFriendViewController ()
@property (nonatomic, assign) FindFriendsFollowStatus followStatus;
@end

@implementation FindFriendViewController
@synthesize followStatus;

-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if(self){
        self.parseClassName = kUserClassKey;
        self.pullToRefreshEnabled = YES;
        self.paginationEnabled = YES;
        self.objectsPerPage = 15;
        self.followStatus = FindFriendsFollowingSome;
    }
    return self;
}
- (void)viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - PFQueryTableViewController
- (PFQuery *)queryForTable {
    // Use cached facebook friend ids
    NSArray *facebookFriends = [[PresenticeCache sharedCache] facebookFriends];
    // Query for all friends you have on facebook and who are using the app
    PFQuery *query = [PFUser query];
    [query whereKey:kUserFacebookIdKey containedIn:facebookFriends];
    
    query.cachePolicy = kPFCachePolicyNetworkOnly;
    if (self.objects.count == 0) {
        query.cachePolicy = kPFCachePolicyCacheThenNetwork;
    }
    
    [query orderByAscending:kUserDisplayNameKey];
    
    return query;
}

- (void)objectsDidLoad:(NSError *)error {
    [super objectsDidLoad:error];
    
    PFQuery *isFollowingQuery = [PFQuery queryWithClassName:kActivityClassKey];
    [isFollowingQuery whereKey:kActivityFromUserKey equalTo:[PFUser currentUser]];
    [isFollowingQuery whereKey:kActivityTypeKey equalTo:kActivityTypeFollow];
    [isFollowingQuery whereKey:kActivityToUserKey containedIn:self.objects];
    
    [isFollowingQuery countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
        if (!error) {
            if (number == self.objects.count) {
                self.followStatus = FindFriendsFollowingAll;
                [self configureUnfollowAllButton];
                for (PFUser *user in self.objects) {
                    [[PresenticeCache sharedCache] setFollowStatus:YES user:user];
                }
            } else if (number == 0) {
                self.followStatus = FindFriendsFollowingNone;
                [self configureFollowAllButton];
                for (PFUser *user in self.objects) {
                    [[PresenticeCache sharedCache] setFollowStatus:NO user:user];
                }
            } else {
                self.followStatus = FindFriendsFollowingSome;
                [self configureFollowAllButton];
            }
        }
        
        if (self.objects.count == 0) {
            self.followAllBtn = nil;
        }
    }];
    
    if (self.objects.count == 0) {
        self.followAllBtn = nil;
    }
}
#pragma table
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object {
    static NSString *FindFriendCellIdentifier = @"FindFriendCell";
    FindFriendCell *cell = [tableView dequeueReusableCellWithIdentifier:FindFriendCellIdentifier];
    if (cell == nil) {
        cell = [[FindFriendCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:FindFriendCellIdentifier];
    }
    cell.delegate = self;
    
    //asyn to get profile picture
    [PresenticeUtility setImageView:cell.profilePicture forUser:(PFUser*)object];
    
    //username
    cell.facebookName.text = [(PFUser *)object objectForKey:kUserDisplayNameKey];
    
    //follow button
    cell.followBtn.selected = NO;
    cell.tag = indexPath.row;
    NSDictionary *attributes = [[PresenticeCache sharedCache] attributesForUser:(PFUser *)object];
    if (self.followStatus == FindFriendsFollowingSome) {
        if (attributes) {
            [cell.followBtn setSelected:[[PresenticeCache sharedCache] followStatusForUser:(PFUser *)object]];
        } else {
            @synchronized(self) {
                PFQuery *isFollowingQuery = [PFQuery queryWithClassName:kActivityClassKey];
                [isFollowingQuery whereKey:kActivityFromUserKey equalTo:[PFUser currentUser]];
                [isFollowingQuery whereKey:kActivityTypeKey equalTo:kActivityTypeFollow];
                [isFollowingQuery whereKey:kActivityToUserKey equalTo:object];
                
                [isFollowingQuery countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
                    @synchronized(self) {
                        [[PresenticeCache sharedCache] setFollowStatus:(!error && number > 0) user:(PFUser *)object];
                    }
                    if (cell.tag == indexPath.row) {
                        [cell.followBtn setSelected:(!error && number > 0)];
                    }
                }];
            }
        }
    } else {
        [cell.followBtn setSelected:(self.followStatus == FindFriendsFollowingAll)];
    }
    
    //set cell user
    [cell setUser:(PFUser*)object];
    
    return cell;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showUserFromFindFriend"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        UserProfileViewController *destViewController = segue.destinationViewController;
        
        PFUser *userObj = [self.objects objectAtIndex:indexPath.row];

        NSLog(@"user object: %@", userObj);
        destViewController.userObj = userObj;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < self.objects.count) {
        return [FindFriendCell heightForCell];
    } else {
        return 44.0f;
    }
}
- (void)configureFollowAllButton {
    [self.followAllBtn setTitle:NSLocalizedString(@"Follow All",nil) forState:UIControlStateNormal];
    [self.followAllBtn addTarget:self action:@selector(doFollowAllAction:)forControlEvents:UIControlEventTouchDown];
}

- (void)configureUnfollowAllButton {
    [self.followAllBtn setTitle:NSLocalizedString(@"Unfollow All", nil) forState:UIControlStateNormal];
    [self.followAllBtn addTarget:self action:@selector(doUnfollowAllAction:)forControlEvents:UIControlEventTouchDown];
}
- (void)doFollowAllAction:(id)sender {
    [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    self.followStatus = FindFriendsFollowingAll;
    [self configureUnfollowAllButton];
    //set all follow button to not selected state
    NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:self.objects.count];
    for (int r = 0; r < self.objects.count; r++) {
        PFObject *user = [self.objects objectAtIndex:r];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:r inSection:0];
        FindFriendCell *cell = (FindFriendCell *)[self tableView:self.tableView cellForRowAtIndexPath:indexPath object:user];
        cell.followBtn.selected = YES;
        [indexPaths addObject:indexPath];
    }
    [self.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
    [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
    [PresenticeUtility followUsersEventually:self.objects block:^(BOOL succeeded, NSError *error) {
        //todo: add timer
    }];
}
- (void)doUnfollowAllAction:(id)sender {
    [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    self.followStatus = FindFriendsFollowingNone;
    [self configureFollowAllButton];
    //set all follow button to Selected state
    NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:self.objects.count];
    for (int r = 0; r < self.objects.count; r++) {
        PFObject *user = [self.objects objectAtIndex:r];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:r inSection:0];
        FindFriendCell *cell = (FindFriendCell *)[self tableView:self.tableView cellForRowAtIndexPath:indexPath object:user];
        cell.followBtn.selected = NO;
        [indexPaths addObject:indexPath];
    }
    [self.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
    [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
    [PresenticeUtility unfollowUsersEventually:self.objects];
}

//delegate method
- (void)cell:(FindFriendCell *)cellView didTapFollowButton:(PFUser *)aUser {
    PFUser *cellUser = cellView.user;
    if ([cellView.followBtn isSelected]) {
        // Unfollow
        cellView.followBtn.selected = NO;
        [PresenticeUtility unfollowUserEventually:cellUser block:^(BOOL succeeded, NSError *error) {
            if (error) {
                [PresenticeUtility showErrorAlert:error];
            }
        }];
    } else {
        // Follow
        cellView.followBtn.selected = YES;
        [PresenticeUtility followUserEventually:cellUser block:^(BOOL succeeded, NSError *error) {
            if (!error) {
            } else {
                cellView.followBtn.selected = NO;
            }
        }];
    }
}
- (IBAction)showLeftMenu:(id)sender {
    [self.menuContainerViewController toggleLeftSideMenuCompletion:nil];
}

- (IBAction)showRightMenu:(id)sender {
    [self.menuContainerViewController toggleRightSideMenuCompletion:nil];
}
- (IBAction)inviteFriends:(id)sender {
    // Email Subject
    NSString *emailTitle = [NSString stringWithFormat:NSLocalizedString(@"Invitation to Presentice [%@]", nil), [[PFUser currentUser] objectId]];
    // Email Content
    NSString *myCode = [[[[PFUser currentUser] objectForKey:kUserPromotionKey] fetchIfNeeded] objectForKey:kPromotionMyCodeKey];
    NSString *messageBody = [NSString stringWithFormat:NSLocalizedString(@"Hi there, I'm using Presentice and have found it awesome.\nCheck it out if you wanna improve your interview performance: www.presentice.com/?utm_source=Invitation&utm_medium=Email&utm_inviteUser=%@ \nUse this invitation code for registration: %@",nil), [PFUser currentUser].objectId,myCode];
    // To address
    NSArray *toRecipents = [NSArray arrayWithObject:@"info@presentice.com"];
    
    MFMailComposeViewController *mc = [[MFMailComposeViewController alloc] init];
    mc.mailComposeDelegate = self;
    [mc setSubject:emailTitle];
    [mc setMessageBody:messageBody isHTML:NO];
    [mc setCcRecipients:toRecipents];
    
    // Present mail view controller on screen
    [self presentViewController:mc animated:YES completion:NULL];
}
- (void) mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    switch (result) {
        case MFMailComposeResultCancelled:
            NSLog(@"Mail cancelled");
            break;
        case MFMailComposeResultSaved:
            NSLog(@"Mail saved");
            break;
        case MFMailComposeResultSent:
            NSLog(@"Mail sent");
            break;
        case MFMailComposeResultFailed:
            NSLog(@"Mail sent failure: %@", [error localizedDescription]);
            break;
        default:
            break;
    }
    
    // Close the Mail Interface
    [self dismissViewControllerAnimated:YES completion:NULL];
}
@end
