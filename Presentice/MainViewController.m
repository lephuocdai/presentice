//
//  ViewController.m
//  SidebarDemo
//
//  Created by Simon on 28/6/13.
//  Copyright (c) 2013 Appcoda. All rights reserved.
//

#import "MainViewController.h"

@interface MainViewController ()

@property (nonatomic, strong) S3TransferOperation *downloadFileOperation;
@property (nonatomic) double totalBytesWritten;
@property (nonatomic) long long expectedTotalBytes;
@property (nonatomic) NSString * filePath;

@end

@implementation MainViewController {
    NSMutableArray *fileList;
    AmazonS3Client *s3Client;
}

#pragma UIViewController

- (void)viewDidLoad{
    [super viewDidLoad];
    
    // Set the side bar button action. When it's tapped, it'll show up the sidebar.
    _sidebarButton.target = self.revealViewController;
    _sidebarButton.action = @selector(revealToggle:);
    
    // Set the gesture
    [self.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];
}

- (void)viewWillAppear:(BOOL)animated {
    fileList = [[NSMutableArray alloc] init];
    [self queryVideoList];

}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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

/**
 * list all file of a bucket and push to table
 * param: bucket name
 * param: Parse Video object (JSON)
 **/
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
            
            [fileList addObject:file];
            
        }
        [self.tableView reloadData];
    }
    @catch (NSException *exception) {
        NSLog(@"Cannot list S3 %@",exception);
    }
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [fileList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *fileListIdentifier = @"fileListIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:fileListIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:fileListIdentifier];
    }
    cell.textLabel.text = [fileList objectAtIndex:indexPath.row][@"fileName"];
    return cell;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showFileDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        FileViewController *destViewController = segue.destinationViewController;
        destViewController.fileName = [fileList objectAtIndex:indexPath.row][@"fileName"];
        destViewController.movieURL = [fileList objectAtIndex:indexPath.row][@"fileURL"];
        destViewController.videoObj = [fileList objectAtIndex:indexPath.row][@"videoObj"];
    }
}




#pragma Parse query
/**
 * query question videos
 * question video means Video.type = question
 **/
- (void) queryVideoList {
    PFQuery *videoList = [PFQuery queryWithClassName:kVideoClassKey];
    [videoList includeKey:kVideoUserKey];   // Important: Include "user" key in this query make receiving user info easier
    [videoList findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            //load videos from S3 with list of name from database
            [ self s3DirectoryListing:[Constants transferManagerBucket] :objects];
        } else {
            NSLog(@"error");
        }
    }];
}
@end
