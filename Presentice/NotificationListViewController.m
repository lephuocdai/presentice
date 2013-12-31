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
    NSMutableArray *notificationList;
    AmazonS3Client *s3Client;
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
    
    // Set the side bar button action. When it's tapped, it'll show up the sidebar.
    _sidebarButton.target = self.revealViewController;
    _sidebarButton.action = @selector(revealToggle:);
    
    // Set the gesture
    [self.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
}

/**
 * override function
 * load table for each time load view
 */
- (void) viewWillAppear:(BOOL)animated {
    notificationList = [[NSMutableArray alloc] init];
    [self queryNotificationList];
    [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated {
    // Hid all HUD after all objects appered
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
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
 * list all file of a bucket and push to table
 * param: bucket name
 * param: Parse Video object (JSON)
 **/
- (void) s3DirectoryListing: (NSString *) bucketName :(NSArray *) videos{
    // Init connection with S3Client
    //    s3Client = [[AmazonS3Client alloc] initWithAccessKey:ACCESS_KEY_ID withSecretKey:SECRET_KEY];
    //    @try {
    //        NSLog(@"videos number: %d", [videos count]);
    //        // Add each filename to fileList
    //        for (int x = 0; x < [videos count]; x++) {
    //
    //            // Set the content type so that the browser will treat the URL as an image.
    //            S3ResponseHeaderOverrides *override = [[S3ResponseHeaderOverrides alloc] init];
    //            override.contentType = @" ";
    //
    //            // Request a pre-signed URL to picture that has been uplaoded.
    //            S3GetPreSignedURLRequest *gpsur = [[S3GetPreSignedURLRequest alloc] init];
    //
    //            //video name
    //            gpsur.key     = [NSString stringWithFormat:@"%@",[[videos objectAtIndex:x] objectForKey:@"videoURL"]];
    //            //bucket name
    //            gpsur.bucket  = bucketName;
    //
    //            gpsur.expires = [NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval) 3600]; // Added an hour's worth of seconds to the current time.
    //
    //            gpsur.responseHeaderOverrides = override;
    //
    //            // Get the URL
    //            NSError *error;
    //            NSURL *url = [s3Client getPreSignedURL:gpsur error:&error];
    //
    //            // Add new file to fileList
    //            NSMutableDictionary *file = [NSMutableDictionary dictionary];
    //            file[@"fileName"] = [NSString stringWithFormat:@"%@",[[videos objectAtIndex:x] objectForKey:@"videoURL"]];
    //            file[@"fileURL"] = url;
    //            file[@"userName"] = @"Need to add userName";
    //            [messageList addObject:file];
    //        }
    //        [self.tableView reloadData];
    //    }
    //    @catch (NSException *exception) {
    //        NSLog(@"Cannot list S3 %@",exception);
    //    }
}

#pragma table methods
/**
 * delegage method
 * number of rows of table
 */
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [notificationList count];
}

/**
 * delegate method
 * build table view
 */
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *fileListIdentifier = @"notificationListIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:fileListIdentifier];
    //    if (cell == nil) {
    //        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:fileListIdentifier];
    //    }
    //    cell.textLabel.text = [messageList objectAtIndex:indexPath.row][@"fileName"];
    
    //    cell.textLabel.text = @"Need to put message view here";
    
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
- (void) queryNotificationList {
    //    PFQuery *questionListQuery = [PFQuery queryWithClassName:kVideoClassKey];
    //    [questionListQuery whereKey:kVideoTypeKey equalTo:@"question"];
    //    [questionListQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
    //        if (!error) {
    //            //load videos from S3 with list of name from database
    //            [ self s3DirectoryListing:[Constants transferManagerBucket] :objects];
    //        } else {
    //            NSLog(@"error");
    //        }
    //    }];
}


@end
