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
    // List files from S3 Bucket: specify bucket name
    [self s3DirectoryListing:[Constants transferManagerBucket]];
    [self.tableView reloadData];
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

-(void) s3DirectoryListing: (NSString *) bucketName {
    // Init connection with S3Client
    s3Client = [[AmazonS3Client alloc] initWithAccessKey:ACCESS_KEY_ID withSecretKey:SECRET_KEY];
    @try {
        // Get file list
        S3ListObjectsRequest *req = [[S3ListObjectsRequest alloc] initWithName:bucketName];
        S3ListObjectsResponse *res = [s3Client listObjects:req];
        NSMutableArray* objectSummaries = res.listObjectsResult.objectSummaries;
        
        // Add each filename to fileList
        for (int x = 0; x < [objectSummaries count]; x++) {
            
            // Set the content type so that the browser will treat the URL as an image.
            S3ResponseHeaderOverrides *override = [[S3ResponseHeaderOverrides alloc] init];
            override.contentType = @" ";
            
            // Request a pre-signed URL to picture that has been uplaoded.
            S3GetPreSignedURLRequest *gpsur = [[S3GetPreSignedURLRequest alloc] init];
            gpsur.key     = [NSString stringWithFormat:@"%@",[objectSummaries objectAtIndex:x]];
            gpsur.bucket  = bucketName;
            gpsur.expires = [NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval) 3600]; // Added an hour's worth of seconds to the current time.
            gpsur.responseHeaderOverrides = override;
            
            // Get the URL
            NSError *error;
            NSURL *url = [s3Client getPreSignedURL:gpsur error:&error];
            
            // Add new file to fileList
            NSMutableDictionary *file = [NSMutableDictionary dictionary];
            file[@"fileName"] = [NSString stringWithFormat:@"%@",[objectSummaries objectAtIndex:x]];
            file[@"fileURL"] = url;
            [fileList addObject:file];
        }
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
    }
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
