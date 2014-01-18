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


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        
        // Whether the built-in pull-to-refresh is enabled
        self.pullToRefreshEnabled = YES;
        
        // Whether the built-in pagination is enabled
        self.paginationEnabled = YES;
        
        // The number of objects to show per page
        self.objectsPerPage = 15;
        
        // Used to determine Follow/Unfollow All button status
        self.followStatus = FindFriendsFollowingSome;
        
        [self.tableView setSeparatorColor:[UIColor colorWithRed:210.0f/255.0f green:203.0f/255.0f blue:182.0f/255.0f alpha:1.0]];
    }
    return self;
}
- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
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
//                for (PFUser *user in self.objects) {
//                    [[PresenticeCache sharedCache] setFollowStatus:YES user:user];
//                }
            } else if (number == 0) {
                self.followStatus = FindFriendsFollowingNone;
                [self configureFollowAllButton];
//                for (PFUser *user in self.objects) {
//                    [[PresenticeCache sharedCache] setFollowStatus:NO user:user];
//                }
            } else {
                self.followStatus = FindFriendsFollowingSome;
                [self configureFollowAllButton];
            }
        }
        
        if (self.objects.count == 0) {
            self.navigationItem.rightBarButtonItem = nil;
        }
    }];
    
    if (self.objects.count == 0) {
        self.navigationItem.rightBarButtonItem = nil;
    }
}
#pragma table
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object {
    static NSString *FindFriendCellIdentifier = @"FindFriendCell";
    FindFriendCell *cell = [tableView dequeueReusableCellWithIdentifier:FindFriendCellIdentifier];
    if (cell == nil) {
        cell = [[FindFriendCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:FindFriendCellIdentifier];
    }
    
    [cell setUser:(PFUser*)object];
    
    return cell;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < self.objects.count) {
        return [FindFriendCell heightForCell];
    } else {
        return 44.0f;
    }
}
- (void)configureFollowAllButton {
    [self.followAllBtn setTitle:@"Follow All" forState:UIControlStateNormal];
    [self.followAllBtn addTarget:self action:@selector(doFollowAllAction:)forControlEvents:UIControlEventTouchDown];
}

- (void)configureUnfollowAllButton {
    [self.followAllBtn setTitle:@"Unfollow All" forState:UIControlStateNormal];
    [self.followAllBtn addTarget:self action:@selector(doUnfollowAllAction:)forControlEvents:UIControlEventTouchDown];
}
- (void)doFollowAllAction:(id)sender {
    NSLog(@"doFollowAllAction: %@", self.objects);
    [self configureUnfollowAllButton];
    [PresenticeUtitily followUsersEventually:self.objects block:^(BOOL succeeded, NSError *error) {
        //todo: add timer
    }];
}
- (void)doUnfollowAllAction:(id)sender {
    [self configureFollowAllButton];
    [PresenticeUtitily unfollowUsersEventually:self.objects];
}
- (IBAction)showLeftMenu:(id)sender {
    [self.menuContainerViewController toggleLeftSideMenuCompletion:nil];
}

- (IBAction)showRightMenu:(id)sender {
    [self.menuContainerViewController toggleRightSideMenuCompletion:nil];
}
@end
