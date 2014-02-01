//
//  UserProfileViewController.m
//  Presentice
//
//  Created by レー フックダイ on 1/16/14.
//  Copyright (c) 2014 Presentice. All rights reserved.
//

#import "UserProfileViewController.h"

@interface UserProfileViewController ()

@end

@implementation UserProfileViewController

- (id)initWithCoder:(NSCoder *)aCoder {
    self = [super initWithCoder:aCoder];
    if (self) {
        // Custom the table
        
        // The className to query on
        self.parseClassName = kVideoClassKey;
        
        // The key of the PFObject to display in the label of the default cell style
        self.textKey = kVideoNameKey;
        
        // Whether the built-in pull-to-refresh is enabled
        self.pullToRefreshEnabled = YES;
        
        // Whether the built-in pagination is enabled
        self.paginationEnabled = YES;
        
        // The number of objects to show per page
        self.objectsPerPage = 5;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Start loading HUD
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    //asyn to get profile picture
    [PresenticeUtility setImageView:self.userProfilePicture forUser:self.userObj];
    
    self.userNameLabel.text = [self.userObj objectForKey:kUserDisplayNameKey];
    
    // Set tap gesture on user profile picture
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(actionHandleTapOnImageView)];
    [singleTap setNumberOfTapsRequired:1];
    self.userProfilePicture.userInteractionEnabled = YES;
    [self.userProfilePicture addGestureRecognizer:singleTap];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
}

- (void)actionHandleTapOnImageView {
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [self.navigationController pushViewController:[PresenticeUtility facebookPageOfUser:self.userObj] animated:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    // Hid all HUD after all objects appered
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
}

-(void) viewWillDisappear:(BOOL)animated {
    //stop playing video
    if([self.navigationController.viewControllers indexOfObject:self] == NSNotFound){
        //Release any retained subviews of the main view.
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"refreshTable" object:nil];
    }
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)refreshTable:(NSNotification *) notification {
    // Reload the recipes
    [self loadObjects];
}

- (PFQuery *)queryForTable {
    PFQuery *videoListQuery = [PFQuery queryWithClassName:self.parseClassName];
    [videoListQuery whereKey:kVideoUserKey equalTo:self.userObj];
    if (self.isFollowing) {
        [videoListQuery whereKey:kVideoVisibilityKey containedIn:@[@"global", @"open", @"friendOnly"]];
    } else {
        [videoListQuery whereKey:kVideoVisibilityKey containedIn:@[@"global", @"open"]];
    }
    [videoListQuery includeKey:kVideoUserKey];   // Important: Include "user" key in this query make receiving user info easier
    [videoListQuery includeKey:kVideoReviewsKey];
    [videoListQuery includeKey:kVideoAsAReplyTo];
    [videoListQuery includeKey:kVideoToUserKey];
    
    // If no objects are loaded in memory, we look to the cache first to fill the table
    // and then subsequently do a query against the network.
    if ([self.objects count] == 0) {
        videoListQuery.cachePolicy = kPFCachePolicyCacheThenNetwork;
    }
    [videoListQuery orderByAscending:kUpdatedAtKey];
    return videoListQuery;
}

#pragma mark - Table view data source

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return @"Videos of this user";
    } else {
        return @"";
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object {
    static NSString *simpleTableIdentifier = @"videoListIdentifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
    }
    
    // Configure the cell
    UILabel *videoType = (UILabel *)[cell viewWithTag:100];
    UILabel *videoName = (UILabel *)[cell viewWithTag:101];
    UILabel *viewsNumLabel = (UILabel *)[cell viewWithTag:102];
    videoType.text = [[object objectForKey:kVideoTypeKey] capitalizedString];
    videoName.text = [[object objectForKey:kVideoNameKey] capitalizedString];
    viewsNumLabel.text = [PresenticeUtility stringNumberOfKey:kVideoViewsKey inObject:object];
    return cell;
}

- (void) objectsDidLoad:(NSError *)error {
    [super objectsDidLoad:error];
    NSLog(@"objectsDidLoad error: %@", [error localizedDescription]);
    
    // check if the currentUser is following this user
    PFQuery *queryIsFollowing = [PFQuery queryWithClassName:kActivityClassKey];
    [queryIsFollowing whereKey:kActivityTypeKey equalTo:kActivityTypeFollow];
    [queryIsFollowing whereKey:kActivityToUserKey equalTo:self.userObj];
    [queryIsFollowing whereKey:kActivityFromUserKey equalTo:[PFUser currentUser]];
    [queryIsFollowing countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
        if (error) {
            NSLog(@"Couldn't determine follow relationship: %@", error);
            self.followBtn = nil;
        } else {
            if (number == 0) {
                self.isFollowing = false;
                NSLog(@"configureFollowButton");
                [self configureFollowButton];
            } else {
                self.isFollowing = true;
                NSLog(@"configureUnfollowButton");
                [self configureUnfollowButton];
            }
        }
    }];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
    if (indexPath.row < [self.objects count] ) {
        PFObject *videoObj = [self.objects objectAtIndex:indexPath.row];
        if ([[videoObj objectForKey:kVideoTypeKey] isEqualToString:@"question"]) {
            NSLog(@"selected question video = %@", videoObj);
            QuestionDetailViewController *destViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"questionDetailViewController"];
            destViewController.movieURL = [PresenticeUtility s3URLForObject:videoObj];
            destViewController.questionVideoObj = videoObj;
            [self.navigationController pushViewController:destViewController animated:YES];
        } else if ([[videoObj objectForKey:kVideoTypeKey] isEqualToString:@"answer"]) {
            NSLog(@"selected answer video = %@", videoObj);
            VideoViewController *destViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"videoViewController"];
            destViewController.movieURL = [PresenticeUtility s3URLForObject:videoObj];
            destViewController.answerVideoObj = videoObj;
            [self.navigationController pushViewController:destViewController animated:YES];
        }
    }
}

- (IBAction)showLeftMenu:(id)sender {
    [self.menuContainerViewController toggleLeftSideMenuCompletion:nil];
}

- (IBAction)showRightMenu:(id)sender {
    [self.menuContainerViewController toggleRightSideMenuCompletion:nil];
}

- (void)doFollowAction:(id)sender {
    //set to unfollow button
    [self configureUnfollowButton];
    //save to parse.com
    [PresenticeUtility followUserEventually:self.userObj block:^(BOOL succeeded, NSError *error){
        if(error){
            //set back to follow button
            [self configureFollowButton];
        }
    }];
}
- (void)doUnfollowAction:(id)sender {
    //set to follow button
    [self configureFollowButton];
    //delete from parse.com
    [PresenticeUtility unfollowUserEventually:self.userObj];
}
- (void)configureFollowButton {
    [self.followBtn setTitle:@"Follow" forState:UIControlStateNormal];
    NSLog(@"self.followBtn.titleLabel.text before = %@", self.followBtn.titleLabel.text);
    [self.followBtn addTarget:self action:@selector(doFollowAction:)forControlEvents:UIControlEventTouchDown];
    NSLog(@"self.followBtn.titleLabel.text after = %@", self.followBtn.titleLabel.text);
}
- (void)configureUnfollowButton {
    [self.followBtn setTitle:@"Following" forState:UIControlStateSelected];
    NSLog(@"self.followBtn.titleLabel.text before = %@", self.followBtn.titleLabel.text);
    [self.followBtn addTarget:self action:@selector(doUnfollowAction:)forControlEvents:UIControlEventTouchDown];
    NSLog(@"self.followBtn.titleLabel.text after = %@", self.followBtn.titleLabel.text);
}

- (IBAction)sendMessage:(id)sender {
    UIAlertView *sendMessageAlert = [[UIAlertView alloc] initWithTitle:@"Send Private Message" message:@"Send to this user a private message" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
    sendMessageAlert.tag = 0;
    [sendMessageAlert show];
}

- (IBAction)reportUser:(id)sender {
    UIAlertView *reportUserAlert = [[UIAlertView alloc] initWithTitle:@"Report this User" message:@"Did you find this user suspicious" delegate:self cancelButtonTitle:@"NO" otherButtonTitles:@"YES", nil];
    [reportUserAlert setAlertViewStyle:UIAlertViewStylePlainTextInput];
    [[reportUserAlert textFieldAtIndex:0] setPlaceholder:@"Reason this person is suspicious"];
    reportUserAlert.tag = 1;
    [reportUserAlert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 0) {
        NSLog(@"ask send message");
        if (buttonIndex == 1) {
            NSLog(@"switch to message detail");
            MessageDetailViewController *messageDetailViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"messageDetailViewController"];
            messageDetailViewController.toUser = self.userObj;
            [self.navigationController pushViewController:messageDetailViewController animated:YES];
        }
    } else if (alertView.tag == 1) {
        NSLog(@"ask report user");
        if (buttonIndex == 1) {
            NSString *reportDescription = [alertView textFieldAtIndex:0].text;
            PFObject *reportActivity = [PFObject objectWithClassName:kActivityClassKey];
            [reportActivity setObject:@"reportUser" forKey:kActivityTypeKey];
            [reportActivity setObject:[PFUser currentUser] forKey:kActivityFromUserKey];
            [reportActivity setObject:self.userObj forKey:kActivityToUserKey];
            [reportActivity setObject:reportDescription forKey:kActivityDescriptionKey];
            [reportActivity saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (!error) {
                    UIAlertView *reportSuccessAlert = [[UIAlertView alloc] initWithTitle:@"Success" message:@"Successfully sent report" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
                    [reportSuccessAlert show];

                } else {
                    [PresenticeUtility showErrorAlert:error];
                }
            }];
        }
    }
}

@end
