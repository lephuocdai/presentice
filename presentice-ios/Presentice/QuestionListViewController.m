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
    UILabel *videoName = (UILabel *)[cell viewWithTag:101];
    UIImageView *userProfilePicture = (UIImageView *)[cell viewWithTag:102];
    UILabel *viewsNum = (UILabel *)[cell viewWithTag:103];
    UILabel *answersNum = (UILabel *)[cell viewWithTag:104];
    
    postedUser.text = [[object objectForKey:kVideoUserKey] objectForKey:kUserDisplayNameKey];
    videoName.text = [object objectForKey:kVideoNameKey];
    viewsNum.text = [NSString stringWithFormat:@"view: %@",[object objectForKey:kVideoViewsKey]];
    answersNum.text = [NSString stringWithFormat:@"answers: %@", [object objectForKey:kVideoAnswersKey]];
    userProfilePicture.image = [UIImage imageWithData:
                                [NSData dataWithContentsOfURL:
                                 [NSURL URLWithString:
                                  [Constants facebookProfilePictureofUser:
                                   [object objectForKey:kVideoUserKey]]]]];
    userProfilePicture.layer.cornerRadius = userProfilePicture.frame.size.width / 2;
    userProfilePicture.layer.masksToBounds = YES;
    return cell;
}

- (void) objectsDidLoad:(NSError *)error {
    [super objectsDidLoad:error];
    NSLog(@"error: %@", [error localizedDescription]);
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

    if ([segue.identifier isEqualToString:@"showQuestionDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
//        QuestionViewController *destViewController = segue.destinationViewController;
        QuestionDetailViewController *destViewController = segue.destinationViewController;
        
        PFObject *object = [self.objects objectAtIndex:indexPath.row];
        NSLog(@"sent object = %@", object);
        destViewController.movieURL = [self s3URL:[Constants transferManagerBucket] :object];
//        destViewController.questionVideoId = [object objectId];
        destViewController.questionVideoObj = object;
    }
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
- (IBAction)showLeftMenu:(id)sender {
    [self.menuContainerViewController toggleLeftSideMenuCompletion:nil];
}

//- (IBAction)showRightMenu:(id)sender {
//    [self.menuContainerViewController toggleRightSideMenuCompletion:nil];
//}

- (IBAction)addQuestion:(id)sender {
    BOOL canPostQuestion = (BOOL)[[PFUser currentUser] objectForKey:kUserCanPostQuestion];
    if (canPostQuestion) {
        UIAlertView *postAlert = [[UIAlertView alloc] initWithTitle:@"Post new challenge!" message:@"Do you want to add more challenges to the list?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles: nil];
        postAlert.tag = 0;
        [postAlert show];
    } else {
        UIAlertView *suggestAlert = [[UIAlertView alloc] initWithTitle:@"Suggest new challenge!" message:@"Suggest a challenge and we will consider making it" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles: nil];
        suggestAlert.tag = 1;
        [suggestAlert show];
    }
}

@end