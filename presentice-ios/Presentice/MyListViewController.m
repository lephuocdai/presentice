//
//  MyListViewController.m
//  Presentice
//
//  Created by レー フックダイ on 12/31/13.
//  Copyright (c) 2013 Presentice. All rights reserved.
//

#import "MyListViewController.h"

@interface MyListViewController ()

@end

@implementation MyListViewController {
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
    PFQuery *myListQuery = [PFQuery queryWithClassName:self.parseClassName];
    [myListQuery includeKey:kVideoReviewsKey];
    [myListQuery includeKey:kVideoAsAReplyTo];
    [myListQuery includeKey:kVideoToUserKey];
    [myListQuery whereKey:kVideoUserKey equalTo:[PFUser currentUser]];
    [myListQuery whereKey:kVideoTypeKey equalTo:@"answer"]; //only get list of answers
    
    // If no objects are loaded in memory, we look to the cache first to fill the table
    // and then subsequently do a query against the network.
    if ([self.objects count] == 0) {
        myListQuery.cachePolicy = kPFCachePolicyCacheThenNetwork;
    }
    [myListQuery orderByDescending:kVideoViewsKey];
    return myListQuery;
}

// Override to customize the look of a cell representing an object. The default is to display
// a UITableViewCellStyleDefault style cell with the label being the first key in the object.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object {
    static NSString *simpleTableIdentifier = @"myListIdentifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
    }
    
    // Configure the cell
    UILabel *postedUser = (UILabel *)[cell viewWithTag:100];
    UILabel *postedTime = (UILabel *)[cell viewWithTag:101];
    UILabel *reviewsNum = (UILabel *)[cell viewWithTag:102];
    UILabel *viewsNum = (UILabel *)[cell viewWithTag:103];
    UILabel *visibility = (UILabel *)[cell viewWithTag:104];
    
    postedUser.text = [[PFUser currentUser] objectForKey:kUserDisplayNameKey];
    postedTime.text = [object objectForKey:kVideoURLKey];
    viewsNum.text = [NSString stringWithFormat:@"view: %@",[object objectForKey:kVideoViewsKey]];
    reviewsNum.text = [NSString stringWithFormat:@"review: %d", [[object objectForKey:kVideoReviewsKey] count]];
    visibility.text = [NSString stringWithFormat:@"%@", [object objectForKey:kVideoVisibilityKey]];
    return cell;
}

- (void) objectsDidLoad:(NSError *)error {
    [super objectsDidLoad:error];
    NSLog(@"error: %@", [error localizedDescription]);
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
//    NSLog(@"HERE %@", self.objects);
    //[self s3DirectoryListing:[Constants transferManagerBucket] :self.objects];
    if ([segue.identifier isEqualToString:@"showAnswerDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        MyAnswerViewController *destViewController = segue.destinationViewController;
        
        PFObject *object = [self.objects objectAtIndex:indexPath.row];
        NSLog(@"sent object = %@", object);
//        destViewController.movieURL = [self s3URL:[Constants transferManagerBucket] :object];
        destViewController.movieURL = [PresenticeUtitily s3URLForObject:object];
        destViewController.answerVideoObj = object;
        destViewController.questionPostedUser = [object objectForKey:kVideoToUserKey];
        destViewController.questionVideoObj = [object objectForKey:kVideoAsAReplyTo];
    }
}

/**
 * get the URL from S3
 * param: bucket name
 * param: Parse Video object (JSON)
 * This one is the modified one of the commented-out above
 
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
 **/



- (IBAction)showLeftMenu:(id)sender {
    [self.menuContainerViewController toggleLeftSideMenuCompletion:nil];
}

- (IBAction)showRightMenu:(id)sender {
    [self.menuContainerViewController toggleRightSideMenuCompletion:nil];
}
@end
