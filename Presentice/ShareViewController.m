//
//  MapViewController.m
//  SidebarDemo
//
//  Created by Simon on 30/6/13.
//  Copyright (c) 2013 Appcoda. All rights reserved.
//

#import "ShareViewController.h"

@interface ShareViewController ()

@property (nonatomic, strong) S3TransferOperation *uploadDidRecord;
@property (nonatomic, strong) S3TransferOperation *uploadFromLibary;
@property (nonatomic, strong) NSString *pathForFileFromLibary;

@end

@implementation ShareViewController {
    NSString *uploadFilename;
    bool isUploadFromLibrary;
    NSString *recordedVideoPath;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Change button color
    //_sidebarButton.tintColor = [UIColor colorWithWhite:0.96f alpha:0.2f];
    
    // Set the side bar button action. When it's tapped, it'll show up the sidebar.
    _sidebarButton.target = self.revealViewController;
    _sidebarButton.action = @selector(revealToggle:);
    
    // Set the gesture
    [self.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];
    
    if(self.tm == nil){
        if(![ACCESS_KEY_ID isEqualToString:@"CHANGE ME"]){
            
            // Initialize the S3 Client.
            AmazonS3Client *s3 = [[AmazonS3Client alloc] initWithAccessKey:ACCESS_KEY_ID withSecretKey:SECRET_KEY];
            s3.endpoint = [AmazonEndpoints s3Endpoint:US_WEST_2];
            
            // Initialize the S3TransferManager
            self.tm = [S3TransferManager new];
            self.tm.s3 = s3;
            self.tm.delegate = self;
            
            // Create the bucket
            S3CreateBucketRequest *createBucketRequest = [[S3CreateBucketRequest alloc] initWithName:[Constants transferManagerBucket] andRegion: [S3Region USWest2]];
            @try {
                S3CreateBucketResponse *createBucketResponse = [s3 createBucket:createBucketRequest];
                if(createBucketResponse.error != nil) {
                    NSLog(@"Error: %@", createBucketResponse.error);
                }
            }@catch(AmazonServiceException *exception) {
                if(![@"BucketAlreadyOwnedByYou" isEqualToString: exception.errorCode]) {
                    NSLog(@"Unable to create bucket: %@ %@",exception.errorCode, exception.error);
                }
            }
            
        }else {
            UIAlertView *message = [[UIAlertView alloc] initWithTitle:CREDENTIALS_ERROR_TITLE
                                                              message:CREDENTIALS_ERROR_MESSAGE
                                                             delegate:nil
                                                    cancelButtonTitle:@"OK"
                                                    otherButtonTitles:nil];
            [message show];
        }
    }
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)upload:(id)sender {
    isUploadFromLibrary = true;
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = YES;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.mediaTypes = [NSArray arrayWithObject:(NSString *)kUTTypeMovie];
    
    [self presentViewController:picker animated:YES completion:NULL];
}

- (IBAction)record:(id)sender {
    [self startCameraControllerFromViewController:self usingDelegate:self];
}

#pragma mark - Image Picker Controller delegate methods
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    if (isUploadFromLibrary) {  //upload file from Library
        NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
        if ([mediaType isEqualToString:(NSString *)kUTTypeMovie]) {
            NSURL *urlVideo = [info objectForKey:UIImagePickerControllerMediaURL];
            
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
            NSString *cachesDirectory = [paths objectAtIndex:0];
            
            NSString* filePath = [NSString stringWithFormat:@"%@/imageTemp.mov",cachesDirectory];
            NSData *videoData = [NSData dataWithContentsOfURL:urlVideo];
            [videoData writeToFile:filePath atomically:YES];
            self.pathForFileFromLibary = filePath;
            
            // Format date to string
            NSDate *date = [NSDate date];
            NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
            [dateFormat setDateFormat: @"yyyy-MM-dd HH:mm:ss"];
            NSString *stringFromDate = [dateFormat stringFromDate:date];
            
            uploadFilename = [NSString stringWithFormat:@"%@.mov", stringFromDate];
            [picker dismissViewControllerAnimated:YES completion:NULL];
            
            if(self.uploadFromLibary == nil || (self.uploadFromLibary.isFinished && !self.uploadFromLibary.isPaused)){
                self.uploadFromLibary = [self.tm uploadFile:self.pathForFileFromLibary bucket: [Constants transferManagerBucket] key: uploadFilename];
            }
        }
    } else {    //capture a video
        NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
        [self dismissViewControllerAnimated:NO completion:nil];
        // Handle a movie capture
        if (CFStringCompare ((__bridge_retained CFStringRef) mediaType, kUTTypeMovie, 0) == kCFCompareEqualTo) {
            NSString *moviePath = [[info objectForKey:UIImagePickerControllerMediaURL] path];
            if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(moviePath)) {
                UISaveVideoAtPathToSavedPhotosAlbum(moviePath, self,
                                                    @selector(video:didFinishSavingWithError:contextInfo:), nil);
            }
            recordedVideoPath = moviePath;
            // NSLog(moviePath);
        }
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    
    [picker dismissViewControllerAnimated:YES completion:NULL];
    
}

#pragma mark - AmazonServiceRequestDelegate

-(void)request:(AmazonServiceRequest *)request didReceiveResponse:(NSURLResponse *)response {
    NSLog(@"didReceiveResponse called: %@", response);
}

-(void)request:(AmazonServiceRequest *)request didSendData:(long long) bytesWritten totalBytesWritten:(long long)totalBytesWritten totalBytesExpectedToWrite:(long long)totalBytesExpectedToWrite {
    if([((S3PutObjectRequest *)request).key isEqualToString:uploadFilename]){
        double percent = ((double)totalBytesWritten/(double)totalBytesExpectedToWrite)*100;
        self.putObjectTextField.text = [NSString stringWithFormat:@"%.2f%%", percent];
    }
    else if([((S3PutObjectRequest *)request).key isEqualToString:kKeyForBigFile]) {
        double percent = ((double)totalBytesWritten/(double)totalBytesExpectedToWrite)*100;
        self.multipartObjectTextField.text = [NSString stringWithFormat:@"%.2f%%", percent];
    }
}

-(void)request:(AmazonServiceRequest *)request didCompleteWithResponse:(AmazonServiceResponse *)response {
    if([((S3PutObjectRequest *)request).key isEqualToString:uploadFilename]){
        self.putObjectTextField.text = @"Done";
    }
    else if([((S3PutObjectRequest *)request).key isEqualToString:kKeyForBigFile]) {
        self.multipartObjectTextField.text = @"Done";
    }
    NSLog(@"upload file url: %@", response);
    
    // Register to Parser DB
    PFObject *newVideo = [PFObject objectWithClassName:@"Video"];
    [newVideo setObject:[PFUser currentUser] forKey:@"user"];
    [newVideo setObject:uploadFilename forKey:@"videoURL"];
    [newVideo setObject:@"question" forKey:@"type"];
    [newVideo saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        NSLog(@"saved to Parse");
    }];
}

-(void)request:(AmazonServiceRequest *)request didFailWithError:(NSError *)error {
    NSLog(@"didFailWithError called: %@", error);
}

-(void)request:(AmazonServiceRequest *)request didFailWithServiceException:(NSException *)exception {
    NSLog(@"didFailWithServiceException called: %@", exception);
}

#pragma mark - Helpers

-(NSString *)generateTempFile: (NSString *)filename : (long long)approximateFileSize {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString * filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:filename];
    if (![fm fileExistsAtPath:filePath]) {
        NSOutputStream * os= [NSOutputStream outputStreamToFileAtPath:filePath append:NO];
        NSString * dataString = @"S3TransferManager_V2 ";
        const uint8_t *bytes = [dataString dataUsingEncoding:NSUTF8StringEncoding].bytes;
        long fileSize = 0;
        [os open];
        while(fileSize < approximateFileSize){
            [os write:bytes maxLength:dataString.length];
            fileSize += dataString.length;
        }
        [os close];
    }
    return filePath;
}



- (BOOL)startCameraControllerFromViewController:(UIViewController *)controller usingDelegate:(id)delegate {
    // Validations
    if (([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] == NO)
        || (delegate == nil)
        || (controller == nil)) {
        return NO;
    }
    
    // Get imagePicker
    UIImagePickerController *cameraUI = [[UIImagePickerController alloc] init];
    cameraUI.sourceType = UIImagePickerControllerSourceTypeCamera;
    
    // Display a controller that allows user to choose movie capture
    cameraUI.mediaTypes = [[NSArray alloc] initWithObjects:(NSString *) kUTTypeMovie, nil];
    
    // Hides the controls for moving & scaling pictures, or for trimming movies. To instead show the controls, use YES.
    cameraUI.allowsEditing = NO;
    cameraUI.delegate = delegate;
    
    // Display image picker
    [controller presentViewController:cameraUI animated:YES completion:nil];
    return YES;
}

-(void)video:(NSString*)videoPath didFinishSavingWithError:(NSError*)error contextInfo:(void*)contextInfo {
    if (error) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Video Saving Failed"
                                                       delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Video Saved"
                                                        message:@"Saved To Photo Album! Upload to Server?"
                                                       delegate:self
                                              cancelButtonTitle:@"NO"
                                              otherButtonTitles:@"YES", nil];
        [alert show];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
    if ([title isEqualToString:@"YES"]) {
        NSLog(@"Wait to upload to server!");
        
        self.pathForFileFromLibary = recordedVideoPath;
        // Format date to string
        
        NSDate *date = [NSDate date];
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
        [dateFormat setDateFormat: @"yyyy-MM-dd HH:mm:ss"];
        NSString *stringFromDate = [dateFormat stringFromDate:date];
        
        uploadFilename = [NSString stringWithFormat:@"%@.mov", stringFromDate];
        
        if(self.uploadFromLibary == nil || (self.uploadFromLibary.isFinished && !self.uploadFromLibary.isPaused)){
            self.uploadFromLibary = [self.tm uploadFile:self.pathForFileFromLibary bucket: [Constants transferManagerBucket] key: uploadFilename];
        }
    }
}

@end
