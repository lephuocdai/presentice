//
//  VideoViewController.m
//  Presentice
//
//  Created by レー フックダイ on 1/7/14.
//  Copyright (c) 2014 Presentice. All rights reserved.
//

#import "VideoViewController.h"

@interface VideoViewController ()

@end

@implementation VideoViewController {
//    NSMutableArray *actionList;
}

@synthesize videoNameLabel;
@synthesize postedUserLabel;
@synthesize viewNumLabel;

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
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
        self.parseClassName = kReviewClassKey;
        
        // The key of the PFObject to display in the label of the default cell style
        self.textKey = kReviewCommentKey;
        
        // Whether the built-in pull-to-refresh is enabled
        self.pullToRefreshEnabled = YES;
        
        // Whether the built-in pagination is enabled
        self.paginationEnabled = YES;
        
        // The number of objects to show per page
        self.objectsPerPage = 5;
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

    // Start loading HUD
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    videoNameLabel.text = [self.answerVideoObj objectForKey:kVideoNameKey];
    postedUserLabel.text = [[self.answerVideoObj objectForKey:kVideoUserKey] objectForKey:kUserDisplayNameKey];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    // Initiate S3 bucket access
//    if(self.tm == nil){
//        if(![ACCESS_KEY_ID isEqualToString:@"CHANGE ME"]){
//            
//            // Initialize the S3 Client.
//            AmazonS3Client *s3 = [[AmazonS3Client alloc] initWithAccessKey:ACCESS_KEY_ID withSecretKey:SECRET_KEY];
//            s3.endpoint = [AmazonEndpoints s3Endpoint:US_WEST_2];
//            
//            // Initialize the S3TransferManager
//            self.tm = [S3TransferManager new];
//            self.tm.s3 = s3;
//            self.tm.delegate = self;
//            
//            // Create the bucket
//            S3CreateBucketRequest *createBucketRequest = [[S3CreateBucketRequest alloc] initWithName:[Constants transferManagerBucket] andRegion: [S3Region USWest2]];
//            @try {
//                S3CreateBucketResponse *createBucketResponse = [s3 createBucket:createBucketRequest];
//                if(createBucketResponse.error != nil) {
//                    NSLog(@"Error: %@", createBucketResponse.error);
//                }
//            }@catch(AmazonServiceException *exception) {
//                if(![@"BucketAlreadyOwnedByYou" isEqualToString: exception.errorCode]) {
//                    NSLog(@"Unable to create bucket: %@ %@",exception.errorCode, exception.error);
//                }
//            }
//            
//        }else {
//            UIAlertView *message = [[UIAlertView alloc] initWithTitle:CREDENTIALS_ERROR_TITLE
//                                                              message:CREDENTIALS_ERROR_MESSAGE
//                                                             delegate:nil
//                                                    cancelButtonTitle:@"OK"
//                                                    otherButtonTitles:nil];
//            [message show];
//        }
//    }
    
    // Set refreshTable notification
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshTable:)
                                                 name:@"refreshTable"
                                               object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
}

- (void)viewDidAppear:(BOOL)animated {
    
    // Set up movieController
    self.movieController = [[MPMoviePlayerController alloc] init];
    [self.movieController setContentURL:self.movieURL];
    [self.movieController.view setFrame:CGRectMake(0, 0, 320, 380)];
    [self.videoView addSubview:self.movieController.view];
    
    // Using the Movie Player Notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayBackDidFinish:) name:MPMoviePlayerPlaybackDidFinishNotification object:self.movieController];
    self.movieController.controlStyle =  MPMovieControlStyleEmbedded;
    self.movieController.shouldAutoplay = YES;
    self.movieController.repeatMode = NO;
    [self.movieController prepareToPlay];
    [self.movieController play];
    
    // Send a "viewed" notification to the device with channel contain video's userId
    if ([[[[self.answerVideoObj objectForKey:kVideoUserKey] objectForKey:kUserPushPermission] objectForKey:@"viewed"] isEqualToString:@"yes"]) {
        NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
        [params setObject:[self.answerVideoObj objectForKey:kVideoNameKey] forKey:@"targetVideo"];
        [params setObject:[[self.answerVideoObj objectForKey:kVideoUserKey] objectId] forKey:@"toUser"];
        [params setObject:@"viewed" forKey:@"pushType"];
        [PFCloud callFunction:@"sendPushNotification" withParameters:params];
        
        //            NSString *pushMessageFormat = [Constants getConstantbyClass:@"Message" forType:@"Push" withName:@"viewed"];
        //            NSString *pushMessageFormat = @"Your video %@ has been viewed by %@!";
        //            NSLog(@"pushMessageFormat = %@",pushMessageFormat);
        //            NSString *messageContent = [NSString stringWithFormat:pushMessageFormat,
        //                                        [self.videoObj objectForKey:kVideoNameKey],
        //                                        [[PFUser currentUser] objectForKey:kUserDisplayNameKey]];
        //            NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:
        //                                  messageContent, @"alert",
        //                                  @"Increment", @"badge",
        //                                  nil];
        //            [PFPush sendPushDataToChannelInBackground:[[self.videoObj objectForKey:kVideoUserKey] objectId] withData:data];
    }

    // Add activity
    PFObject *activity = [PFObject objectWithClassName:kActivityClassKey];
    [activity setObject:[PFUser currentUser] forKey:kActivityFromUserKey];
    [activity setObject:[self.answerVideoObj objectForKey:kVideoUserKey] forKey:kActivityToUserKey];
    [activity setObject:@"view" forKey:kActivityTypeKey];
    [activity setObject:self.answerVideoObj forKey:kACtivityTargetVideoKey];
    [activity saveInBackground];
    
    // Increment views
    int viewsNum = [[self.answerVideoObj objectForKey:kVideoViewsKey] intValue];
    [self.answerVideoObj setObject:[NSNumber numberWithInt:viewsNum+1] forKey:kVideoViewsKey];
    PFQuery *query = [PFQuery queryWithClassName:kVideoClassKey];
    [query getObjectInBackgroundWithId:[self.answerVideoObj objectId] block:^(PFObject *object, NSError *error) {
        [object setObject:[NSNumber numberWithInt:viewsNum+1] forKey:kVideoViewsKey];
        [object saveInBackground];
    }];
    [self.answerVideoObj saveInBackground];
    NSLog(@"after videoObj = %@", self.answerVideoObj);
    
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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (PFQuery *)queryForTable {
    PFQuery *reviewListQuery = [PFQuery queryWithClassName:self.parseClassName];
    [reviewListQuery includeKey:kReviewFromUserKey];   // Important: Include "fromUser" key in this query make receiving user info easier
    [reviewListQuery includeKey:kReviewToUserKey];
    [reviewListQuery includeKey:kReviewTargetVideoKey];
    [reviewListQuery whereKey:kReviewTargetVideoKey equalTo:self.answerVideoObj];
    
    // If no objects are loaded in memory, we look to the cache first to fill the table
    // and then subsequently do a query against the network.
    if ([self.objects count] == 0) {
        reviewListQuery.cachePolicy = kPFCachePolicyCacheThenNetwork;
    }
    [reviewListQuery orderByAscending:kUpdatedAtKey];
    return reviewListQuery;
}


- (void)moviePlayBackDidFinish:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
}
- (void) viewWillDisappear:(BOOL)animated {
    [self.movieController stop];
    [self.movieController.view removeFromSuperview];
    self.movieController = nil;
}

#pragma mark - Table view data source
/**
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(section == 0) {
        return 1;   // Only one video play
    } else {
        return 3;   // Video info has three row: videoName + postedUser + views/reviews
    }
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section == 0) {
        return 300;
    } else {
        return 50;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *videoTableCellIdentifier = @"videoTableCell";
    UITableViewCell *cell = (UITableViewCell*)[tableView dequeueReusableCellWithIdentifier:videoTableCellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:videoTableCellIdentifier ];
    }
    // Configure the cell...
    
    if (indexPath.section == 0) {
        self.movieController = [[MPMoviePlayerController alloc] init];
        [self.movieController setContentURL:self.movieURL];
        [self.movieController.view setFrame:CGRectMake(0, 0, 320, 300)];
        [cell.contentView addSubview:self.movieController.view];
        
        // Using the Movie Player Notifications
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayBackDidFinish:) name:MPMoviePlayerPlaybackDidFinishNotification object:self.movieController];
        
        self.movieController.controlStyle =  MPMovieControlStyleEmbedded;
        self.movieController.shouldAutoplay = YES;
        self.movieController.repeatMode = NO;
        [self.movieController prepareToPlay];
        
        [self.movieController play];
    } else {
        if (indexPath.row == 0) {
            cell.textLabel.text = [[self.videoObj objectForKey:kVideoUserKey] objectForKey:kUserDisplayNameKey];
        } else if (indexPath.row == 1) {
            cell.textLabel.text = [self.videoObj objectForKey:kVideoNameKey];
        } else {
            cell.textLabel.text = [NSString stringWithFormat:@"View: %@     Reviews: %d",[self.videoObj objectForKey:kVideoViewsKey],[[self.videoObj objectForKey:kVideoReviewsKey] count]];
        }
    }
    return cell;
}
**/

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object {
    static NSString *simpleTableIdentifier = @"reviewListIdentifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
    }
    
    // Configure the cell
    UILabel *userName = (UILabel *)[cell viewWithTag:101];
    UILabel *pointDetail = (UILabel *)[cell viewWithTag:102];
    UILabel *pointSum = (UILabel *)[cell viewWithTag:103];
    UILabel *comment = (UILabel *)[cell viewWithTag:104];
    
    userName.text = [[object objectForKey:kReviewFromUserKey] objectForKey:kUserDisplayNameKey];
    
    NSMutableDictionary *points = [object objectForKey:kReviewContentKey];
    pointDetail.text = [NSString stringWithFormat:@"app: %@, org: %@, und: %@",
                        [points objectForKey:@"apppearance"],
                        [points objectForKey:@"organization"],
                        [points objectForKey:@"understandability"]];
    
    pointSum.text = @"undefined";
    
    comment.text = [object objectForKey:kReviewCommentKey];
    return cell;
}

- (void) objectsDidLoad:(NSError *)error {
    [super objectsDidLoad:error];
    NSLog(@"error: %@", [error localizedDescription]);
}

/**
 * segue for table cell
 * click to direct to video review
 * pass video object
 */

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"toReviewView"]) {
        TakeReviewViewController *destViewController = segue.destinationViewController;
        destViewController.videoObj = self.answerVideoObj;
    }
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
