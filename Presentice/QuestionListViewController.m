//
//  QuestionListViewController.m
//  Presentice
//
//  Created by レー フックダイ on 12/31/13.
//  Copyright (c) 2013 Presentice. All rights reserved.
//

#import "QuestionListViewController.h"

@interface QuestionListViewController ()

@end

@implementation QuestionListViewController {
    // NSMutableArray *questionList;
    AmazonS3Client *s3Client;
}

/**
 * This function cause error, be careful
 - (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
 
 self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
 if (self) {
 // Custom the table
 
 // The className to query on
 self.parseClassName = kVideoClassKey;
 
 // The key of the PFObject to display in the label of the default cell style
 self.textKey = kVideoURLKey;
 
 // Whether the built-in pull-to-refresh is enabled
 self.pullToRefreshEnabled = YES;
 
 // Whether the built-in pagination is enabled
 self.paginationEnabled = YES;
 
 // The number of objects to show per page
 self.objectsPerPage = 10;    }
 return self;
 }
**/

- (id)initWithCoder:(NSCoder *)aCoder {
    self = [super initWithCoder:aCoder];
    if (self) {
        // Custom the table
        
        // The className to query on
        self.parseClassName = kVideoClassKey;
        
        // The key of the PFObject to display in the label of the default cell style
        self.textKey = kVideoURLKey;
        
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
    
    // Set the side bar button action. When it's tapped, it'll show up the sidebar.
    _sidebarButton.target = self.revealViewController;
    _sidebarButton.action = @selector(revealToggle:);
    
    // Set the gesture
    [self.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];
    
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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (PFQuery *)queryForTable {
    PFQuery *questionListQuery = [PFQuery queryWithClassName:self.parseClassName];
    [questionListQuery includeKey:kVideoUserKey];   // Important: Include "user" key in this query make receiving user info easier
    [questionListQuery whereKey:kVideoTypeKey equalTo:@"question"];
    
    // If no objects are loaded in memory, we look to the cache first to fill the table
    // and then subsequently do a query against the network.
    if ([self.objects count] == 0) {
        questionListQuery.cachePolicy = kPFCachePolicyCacheThenNetwork;
    }
    [questionListQuery orderByAscending:kUpdatedAtKey];
    return questionListQuery;
}
// Override to customize the look of a cell representing an object. The default is to display
// a UITableViewCellStyleDefault style cell with the label being the first key in the object.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object {
    static NSString *simpleTableIdentifier = @"questionListIdentifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
    }
    
    // Configure the cell
    UILabel *postedUser = (UILabel *)[cell viewWithTag:100];
    postedUser.text = [[object objectForKey:kVideoUserKey] objectForKey:kUserDisplayNameKey];
    
    UILabel *postedTime = (UILabel *)[cell viewWithTag:101];
    postedTime.text = [object objectForKey:kVideoURLKey];
    
    UILabel *isTakenAnswer = (UILabel *)[cell viewWithTag:102];
    
    // Need a better way to check answeredStatus
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        PFQuery *myAnswer = [PFQuery queryWithClassName:kVideoClassKey];
        [myAnswer includeKey:kVideoUserKey];
        [myAnswer whereKey:kVideoUserKey equalTo:[PFUser currentUser]];
        [myAnswer whereKey:kVideoAsAReplyTo equalTo:object];
        [myAnswer findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if(!error && objects.count != 0){
                isTakenAnswer.text = @"Already Answered";
            } else {
                isTakenAnswer.text = @"Not Answered Yet";
            }
        }];
    });
    return cell;
}

- (void) objectsDidLoad:(NSError *)error {
    [super objectsDidLoad:error];
    NSLog(@"error: %@", [error localizedDescription]);
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSLog(@"HERE %@", self.objects);
    //[self s3DirectoryListing:[Constants transferManagerBucket] :self.objects];
    if ([segue.identifier isEqualToString:@"showQuestionDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        QuestionViewController *destViewController = segue.destinationViewController;
        
        PFObject *object = [self.objects objectAtIndex:indexPath.row];
        NSLog(@"sent object = %@", object);
        destViewController.fileName = [object objectForKey:kVideoURLKey];
        destViewController.movieURL = [self s3URL:[Constants transferManagerBucket] :object];
        destViewController.userName = [[object objectForKey:kVideoUserKey] objectForKey:kUserDisplayNameKey];
        destViewController.questionVideoId = [object objectId];
    }
}

#pragma Amazon implemented methods

/**
 * list all file of a bucket and push to table
 * param: bucket name
 * param: Parse Video object (JSON)
 * We don't need this function now

- (void) s3DirectoryListing: (NSString *) bucketName :(NSArray *) videos{
    // Init connection with S3Client
    s3Client = [[AmazonS3Client alloc] initWithAccessKey:ACCESS_KEY_ID withSecretKey:SECRET_KEY];
    @try {
        // Add each filename to fileList
        for (int x = 0; x < [videos count]; x++) {

            // Set the content type so that the browser will treat the URL as an image.
            S3ResponseHeaderOverrides *override = [[S3ResponseHeaderOverrides alloc] init];
            override.contentType = @" ";

            // Request a pre-signed URL to picture that has been uplaoded.
            S3GetPreSignedURLRequest *gpsur = [[S3GetPreSignedURLRequest alloc] init];

            //video name
            gpsur.key     = [NSString stringWithFormat:@"%@",[[videos objectAtIndex:x] objectForKey:@"videoURL"]];
            //bucket name
            gpsur.bucket  = bucketName;

            gpsur.expires = [NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval) 3600]; // Added an hour's worth of seconds to the current time.

            gpsur.responseHeaderOverrides = override;

            // Get the URL
            NSError *error;
            NSURL *url = [s3Client getPreSignedURL:gpsur error:&error];

            // Add new file to fileList
            NSMutableDictionary *file = [NSMutableDictionary dictionary];
            file[@"fileName"] = [NSString stringWithFormat:@"%@",[[videos objectAtIndex:x] objectForKey:@"videoURL"]];
            file[@"fileURL"] = url;

            PFObject *questionVideo = [videos objectAtIndex:x];                 // Get video from
            PFUser *postedUser = [questionVideo objectForKey:kVideoUserKey];    // Get the postedUser

            file[@"questionVideo"] = [questionVideo objectId];
            file[@"userName"] = [postedUser objectForKey:kUserDisplayNameKey];

            file[@"videoObj"] = questionVideo;
            //file[@"answeredLabel"] = [self alreadyAnswerQuestion:questionVideo] ?  @"Already Answered" : @"Not Answered Yet";

            [questionList addObject:file];

        }
        [self.tableView reloadData];
    }
    @catch (NSException *exception) {
        NSLog(@"Cannot list S3 %@",exception);
    }
}
**/

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