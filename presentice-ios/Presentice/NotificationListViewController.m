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
//    NSMutableArray *notificationList;
    AmazonS3Client *s3Client;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
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
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    
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

/**
 * override function
 * load table for each time load view
 */
- (void) viewWillAppear:(BOOL)animated {
//    notificationList = [[NSMutableArray alloc] init];
//    [self queryNotificationList];
//    [self.tableView reloadData];
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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

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

//- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
//    if ([[[self.objects objectAtIndex:indexPath.row] objectForKey:kActivityTypeKey] isEqualToString:@"answer"] ) {
//        return 120;
//    } else if ([[[self.objects objectAtIndex:indexPath.row] objectForKey:kActivityTypeKey] isEqualToString:@"review"]) {
//        return 120;
//    } else if ([[[self.objects objectAtIndex:indexPath.row] objectForKey:kActivityTypeKey] isEqualToString:@"postQuestion"]) {
//        return 120;
//    } else if ([[[self.objects objectAtIndex:indexPath.row] objectForKey:kActivityTypeKey] isEqualToString:@"register"]) {
//        return 120;
//    } else {
//        return 120;
//    }
//}

#pragma table methods
/**
 * delegage method
 * number of rows of table
 */
//- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
//    return [notificationList count];
//}

/**
 * delegate method
 * build table view
 */
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object {
    NSString *simpleTableIdentifier = @"notificationListIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier forIndexPath:indexPath];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
    }
    
    // Configure the cell
    UIImageView *userProfilePicture = (UIImageView *)[cell viewWithTag:100];
    UILabel *description = (UILabel *)[cell viewWithTag:101];
    UILabel *activityType = (UILabel *)[cell viewWithTag:102];
//    UILabel *viewsNum = (UILabel *)[cell viewWithTag:103];
    
    //asyn to get profile picture
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSData *profileImageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:[Constants facebookProfilePictureofUser:[object objectForKey:kActivityFromUserKey]]]];
        dispatch_async(dispatch_get_main_queue(), ^{
            userProfilePicture.image = [UIImage imageWithData:profileImageData];
        });
    });
    
    description.text = [NSString stringWithFormat:@"%@ has %@ed %@!",
                        [[object objectForKey:kActivityFromUserKey] objectForKey:kUserDisplayNameKey],
                        [object objectForKey:kActivityTypeKey],
                        [[object objectForKey:kActivityToUserKey] objectForKey:kUserDisplayNameKey]];
    activityType.text = [NSString stringWithFormat:@"%@", [object objectForKey:kActivityTypeKey]];
//    viewsNum.text = [NSString stringWithFormat:@"view: %@",[[object objectForKey:kActivityTargetVideoKey] objectForKey:kVideoViewsKey]];
    
    return cell;
}

/**
 * segue for table cell
 * click to direct to video play view
 * pass video name, video url
 */
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
//    if ([segue.identifier isEqualToString:@"showQuestionDetail"]) {
//        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
//        QuestionViewController *destViewController = segue.destinationViewController;
//        destViewController.fileName = [questionList objectAtIndex:indexPath.row][@"fileName"];
//        destViewController.movieURL = [questionList objectAtIndex:indexPath.row][@"fileURL"];
//        destViewController.userName = [questionList objectAtIndex:indexPath.row][@"userName"];
//    }
}

#pragma Parse query
/**
 * query question videos
 * question video means Video.type = question
 **/
//- (void) queryNotificationList {
//    //    PFQuery *questionListQuery = [PFQuery queryWithClassName:kVideoClassKey];
//    //    [questionListQuery whereKey:kVideoTypeKey equalTo:@"question"];
//    //    [questionListQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
//    //        if (!error) {
//    //            //load videos from S3 with list of name from database
//    //            [ self s3DirectoryListing:[Constants transferManagerBucket] :objects];
//    //        } else {
//    //            NSLog(@"error");
//    //        }
//    //    }];
//}


- (IBAction)showLeftMenu:(id)sender {
    [self.menuContainerViewController toggleLeftSideMenuCompletion:nil];
}

- (IBAction)showRightMenu:(id)sender {
    [self.menuContainerViewController toggleRightSideMenuCompletion:nil];
}

#pragma mark - AmazonServiceRequestDelegate

//-(void)request:(AmazonServiceRequest *)request didReceiveResponse:(NSURLResponse *)response {
//}
//
//- (void)request:(AmazonServiceRequest *)request didReceiveData:(NSData *)data {
//}
//
//-(void)request:(AmazonServiceRequest *)request didCompleteWithResponse:(AmazonServiceResponse *)response {
//}
//
//-(void)request:(AmazonServiceRequest *)request didFailWithError:(NSError *)error {
//    NSLog(@"didFailWithError called: %@", error);
//}
//
//-(void)request:(AmazonServiceRequest *)request didFailWithServiceException:(NSException *)exception {
//    NSLog(@"didFailWithServiceException called: %@", exception);
//}
//
//#pragma Amazon implemented methods
//
///**
// * list all file of a bucket and push to table
// * param: bucket name
// * param: Parse Video object (JSON)
// **/
//- (void) s3DirectoryListing: (NSString *) bucketName :(NSArray *) videos{
//    // Init connection with S3Client
//    //    s3Client = [[AmazonS3Client alloc] initWithAccessKey:ACCESS_KEY_ID withSecretKey:SECRET_KEY];
//    //    @try {
//    //        NSLog(@"videos number: %d", [videos count]);
//    //        // Add each filename to fileList
//    //        for (int x = 0; x < [videos count]; x++) {
//    //
//    //            // Set the content type so that the browser will treat the URL as an image.
//    //            S3ResponseHeaderOverrides *override = [[S3ResponseHeaderOverrides alloc] init];
//    //            override.contentType = @" ";
//    //
//    //            // Request a pre-signed URL to picture that has been uplaoded.
//    //            S3GetPreSignedURLRequest *gpsur = [[S3GetPreSignedURLRequest alloc] init];
//    //
//    //            //video name
//    //            gpsur.key     = [NSString stringWithFormat:@"%@",[[videos objectAtIndex:x] objectForKey:@"videoURL"]];
//    //            //bucket name
//    //            gpsur.bucket  = bucketName;
//    //
//    //            gpsur.expires = [NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval) 3600]; // Added an hour's worth of seconds to the current time.
//    //
//    //            gpsur.responseHeaderOverrides = override;
//    //
//    //            // Get the URL
//    //            NSError *error;
//    //            NSURL *url = [s3Client getPreSignedURL:gpsur error:&error];
//    //
//    //            // Add new file to fileList
//    //            NSMutableDictionary *file = [NSMutableDictionary dictionary];
//    //            file[@"fileName"] = [NSString stringWithFormat:@"%@",[[videos objectAtIndex:x] objectForKey:@"videoURL"]];
//    //            file[@"fileURL"] = url;
//    //            file[@"userName"] = @"Need to add userName";
//    //            [messageList addObject:file];
//    //        }
//    //        [self.tableView reloadData];
//    //    }
//    //    @catch (NSException *exception) {
//    //        NSLog(@"Cannot list S3 %@",exception);
//    //    }
//}

@end
