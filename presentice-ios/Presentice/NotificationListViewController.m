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
    AmazonS3Client *s3Client;
}

- (id)initWithCoder:(NSCoder *)aCoder {
    self = [super initWithCoder:aCoder];
    if (self) {
        // Custom the table
        
        // The className to query on
        //        self.parseClassName = kVideoClassKey;
        self.parseClassName = kActivityClassKey;
        
        // The key of the PFObject to display in the label of the default cell style
        //        self.textKey = kVideoURLKey;
        self.textKey = kActivityTypeKey;
        
        // Whether the built-in pull-to-refresh is enabled
        self.pullToRefreshEnabled = YES;
        
        // Whether the built-in pagination is enabled
        self.paginationEnabled = YES;
        
        // The number of objects to show per page
        self.objectsPerPage = 5;
    }
    
    if ([PFInstallation currentInstallation].badge > 0) {
            [self.tabBarItem setBadgeValue:[NSString stringWithFormat:@"%ld",(long)[PFInstallation currentInstallation].badge]];
        }
    
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
    
//    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    
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
    
    if ([self.tabBarItem badgeValue]) {
        PFInstallation *currentInstallation = [PFInstallation currentInstallation];
        if (currentInstallation.badge != 0) {
               currentInstallation.badge = 0;
               [currentInstallation saveEventually];
        }
        [self.tabBarItem setBadgeValue:nil];
    }
    
    // Hid all HUD after all objects appered
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
}

/**
 * override function
 * load table for each time load view
 
- (void) viewWillAppear:(BOOL)animated {
    notificationList = [[NSMutableArray alloc] init];
    [self queryNotificationList];
    [self.tableView reloadData];
}
 
 */

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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

#pragma Parse query
/**
 * query notifications from Activity Table
 * acitivity.toUse = currentUser
**/

- (PFQuery *)queryForTable {
    PFQuery *activitiesQuery = [PFQuery queryWithClassName:self.parseClassName];
    [activitiesQuery whereKey:kActivityTypeKey containedIn:@[@"answer", @"review", @"postQuestion", @"view", @"follow"]];
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
#pragma table methods
/**
 * delegage method
 * number of rows of table
 */

/**

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if ([[[self.objects objectAtIndex:indexPath.row] objectForKey:kActivityTypeKey] isEqualToString:@"answer"] ) {
        return 120;
    } else if ([[[self.objects objectAtIndex:indexPath.row] objectForKey:kActivityTypeKey] isEqualToString:@"review"]) {
        return 120;
    } else if ([[[self.objects objectAtIndex:indexPath.row] objectForKey:kActivityTypeKey] isEqualToString:@"postQuestion"]) {
        return 120;
    } else if ([[[self.objects objectAtIndex:indexPath.row] objectForKey:kActivityTypeKey] isEqualToString:@"register"]) {
        return 120;
    } else {
        return 120;
    }
}
 
**/

/**
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.objects count] + 1;
}
**/

/**
 * delegate method
 * build table view
 */
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object {
    static NSString *simpleTableIdentifier = @"notificationListIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier forIndexPath:indexPath];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
    }
    
    // Configure the cell
    UIImageView *userProfilePicture = (UIImageView *)[cell viewWithTag:100];
    UILabel *description = (UILabel *)[cell viewWithTag:101];
    
    //asyn to get profile picture
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSData *profileImageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:[Constants facebookProfilePictureofUser:[object objectForKey:kActivityFromUserKey]]]];
        dispatch_async(dispatch_get_main_queue(), ^{
            userProfilePicture.image = [UIImage imageWithData:profileImageData];
            userProfilePicture.highlightedImage = [UIImage imageWithData:profileImageData];
            userProfilePicture.layer.cornerRadius = userProfilePicture.frame.size.width / 2;
            userProfilePicture.layer.masksToBounds = YES;
        });
    });
    
    NSString *type = [object objectForKey:kActivityTypeKey];
    if ([type isEqualToString:@"postQuestion"]) {
        description.text = [NSString stringWithFormat:@"%@ has posted new question %@!",
                            [[object objectForKey:kActivityFromUserKey] objectForKey:kUserDisplayNameKey],
                            [[object objectForKey:kActivityTargetVideoKey] objectForKey:kVideoNameKey]];
        [description boldSubstring:[NSString stringWithFormat:@"%@",[[object objectForKey:kActivityFromUserKey] objectForKey:kUserDisplayNameKey]]];
        [description boldSubstring:[NSString stringWithFormat:@"%@",[[object objectForKey:kActivityTargetVideoKey] objectForKey:kVideoNameKey]]];
    } else if ([type isEqualToString:@"follow"]) {
        description.text = [NSString stringWithFormat:@"%@ has followed you!",
                            [[object objectForKey:kActivityFromUserKey] objectForKey:kUserDisplayNameKey]];
        [description boldSubstring:[NSString stringWithFormat:@"%@",[[object objectForKey:kActivityFromUserKey] objectForKey:kUserDisplayNameKey]]];
    } else {
        description.text = [NSString stringWithFormat:@"%@ has %@ed your %@!",
                            [[object objectForKey:kActivityFromUserKey] objectForKey:kUserDisplayNameKey],
                            [object objectForKey:kActivityTypeKey],
                            [[object objectForKey:kActivityTargetVideoKey] objectForKey:kVideoNameKey]];
        [description boldSubstring:[NSString stringWithFormat:@"%@",[[object objectForKey:kActivityFromUserKey] objectForKey:kUserDisplayNameKey]]];
        [description boldSubstring:[NSString stringWithFormat:@"%@",[[object objectForKey:kActivityTargetVideoKey] objectForKey:kVideoNameKey]]];
    }
    return cell;
}

- (void) objectsDidLoad:(NSError *)error {
    [super objectsDidLoad:error];
    NSLog(@"error: %@", [error localizedDescription]);
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
            VideoViewController *destViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"videoViewController"];
            PFObject *videoObj = [notificationObj objectForKey:kActivityTargetVideoKey];
            
            destViewController.movieURL = [self s3URL:[Constants transferManagerBucket] :videoObj];
            destViewController.answerVideoObj = videoObj;
            
            [self.navigationController pushViewController:destViewController animated:YES];
            
        } else if ([[notificationObj objectForKey:kActivityTypeKey] isEqualToString:@"review"]) {
            VideoViewController *destViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"videoViewController"];
            PFObject *videoObj = [notificationObj objectForKey:kActivityTargetVideoKey];
            
            destViewController.movieURL = [self s3URL:[Constants transferManagerBucket] :videoObj];
            destViewController.answerVideoObj = videoObj;
            
            [self.navigationController pushViewController:destViewController animated:YES];
            
        } else if ([[notificationObj objectForKey:kActivityTypeKey] isEqualToString:@"postQuestion"]) {
            QuestionDetailViewController *destViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"questionDetailViewController"];
            PFObject *videoObj = [notificationObj objectForKey:kActivityTargetVideoKey];
            
            destViewController.movieURL = [self s3URL:[Constants transferManagerBucket] :videoObj];
            destViewController.questionVideoObj = videoObj;
            
            [self.navigationController pushViewController:destViewController animated:YES];
            
        } else if ([[notificationObj objectForKey:kActivityTypeKey] isEqualToString:@"register"]) {
            UserProfileViewController *destViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"userProfileViewController"];
            destViewController.userObj = [notificationObj objectForKey:kActivityFromUserKey];
            
            [self.navigationController pushViewController:destViewController animated:YES];
            
        } else if ([[notificationObj objectForKey:kActivityTypeKey] isEqualToString:@"follow"]) {
            UserProfileViewController *destViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"userProfileViewController"];
            destViewController.userObj = [notificationObj objectForKey:kActivityFromUserKey];
            
            [self.navigationController pushViewController:destViewController animated:YES];
            
        } else if ([[notificationObj objectForKey:kActivityTypeKey] isEqualToString:@"view"]) {
            UserProfileViewController *destViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"userProfileViewController"];
            destViewController.userObj = [notificationObj objectForKey:kActivityFromUserKey];
            
            [self.navigationController pushViewController:destViewController animated:YES];
        }
    }
}

/**
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showQuestionDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        QuestionViewController *destViewController = segue.destinationViewController;
        destViewController.fileName = [questionList objectAtIndex:indexPath.row][@"fileName"];
        destViewController.movieURL = [questionList objectAtIndex:indexPath.row][@"fileURL"];
        destViewController.userName = [questionList objectAtIndex:indexPath.row][@"userName"];
    }
}
**/



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

/**
 * get the URL from S3
 * param: bucket name
 * param: Parse Video object (JSON)
 * This one is the modified one of the commented-out above
**/

- (NSURL*)s3URL: (NSString*)bucketName :(PFObject*)object {
    // Init connection with S3Client
    s3Client = [[AmazonS3Client alloc] initWithAccessKey:ACCESS_KEY_ID withSecretKey:SECRET_KEY];
    @try {
        // Set the content type so that the browser will treat the URL as an image.
        S3ResponseHeaderOverrides *override = [[S3ResponseHeaderOverrides alloc] init];
        override.contentType = @" ";
        // Request a pre-signed URL to picture that has been uplaoded.
        S3GetPreSignedURLRequest *gpsur = [[S3GetPreSignedURLRequest alloc] init];
        // Video name
        gpsur.key = [NSString stringWithFormat:@"%@", [object objectForKey:kVideoURLKey]];
        //bucket name
        gpsur.bucket  = bucketName;
        // Added an hour's worth of seconds to the current time.
        gpsur.expires = [NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval) 3600];
        
        gpsur.responseHeaderOverrides = override;
        
        // Get the URL
        NSError *error;
        NSURL *url = [s3Client getPreSignedURL:gpsur error:&error];
        return url;
    }
    @catch (NSException *exception) {
        NSLog(@"Cannot list S3 %@",exception);
    }
}
@end
