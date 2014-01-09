//
//  QuestionViewController.m
//  Presentice
//
//  Created by レー フックダイ on 12/24/13.
//  Copyright (c) 2013 Appcoda. All rights reserved.
//

#import "QuestionViewController.h"

@interface QuestionViewController ()

@property (nonatomic, strong) S3TransferOperation *uploadDidRecord;
@property (nonatomic, strong) S3TransferOperation *uploadFromLibrary;
@property (nonatomic, strong) NSString *pathForFileFromLibrary;

@end

@implementation QuestionViewController {
    NSString *uploadFilename;
    bool isUploadFromLibrary;
    NSString *recordedVideoPath;
}

@synthesize fileLabel;
//@synthesize fileName;
@synthesize userLabel;
//@synthesize userName;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.scrollView setScrollEnabled:YES];
    [self.scrollView setContentSize:(CGSizeMake(320, 860))];

    fileLabel.text = [self.questionVideoObj objectForKey:kVideoURLKey];
    userLabel.text = [[self.questionVideoObj objectForKey:kVideoUserKey] objectForKey:kUserDisplayNameKey];
    
    // Initiate S3 bucket access
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated {
    
    // Set up movieController
    self.movieController = [[MPMoviePlayerController alloc] init];
    [self.movieController setContentURL:self.movieURL];
    [self.movieController.view setFrame:CGRectMake(0, 130, 320, 400)];
    [self.scrollView addSubview:self.movieController.view];
    
    // Using the Movie Player Notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayBackDidFinish:) name:MPMoviePlayerPlaybackDidFinishNotification object:self.movieController];
    
    self.movieController.controlStyle =  MPMovieControlStyleEmbedded;
    self.movieController.shouldAutoplay = YES;
    self.movieController.repeatMode = NO;
    [self.movieController prepareToPlay];
    [self.movieController play];
    
    // Send a notification to the device with channel contain questionVideo's userId
    NSString *pushMessageFormat = [Constants getConstantbyClass:@"Message" forType:@"Push" withName:@"viewed"];
    NSLog(@"pushMessageFormat = %@",pushMessageFormat);
    [PFPush sendPushMessageToChannelInBackground:[[self.questionVideoObj objectForKey:kVideoUserKey] objectId]
                                     withMessage:[NSString stringWithFormat:pushMessageFormat,[self.questionVideoObj objectForKey:kVideoNameKey], [[PFUser currentUser] objectForKey:kUserDisplayNameKey]]];
    
    // Add activity
    PFObject *activity = [PFObject objectWithClassName:kActivityClassKey];
    [activity setObject:[PFUser currentUser] forKey:kActivityFromUserKey];
    [activity setObject:[self.questionVideoObj objectForKey:kVideoUserKey] forKey:kActivityToUserKey];
    [activity setObject:@"view" forKey:kActivityTypeKey];
    [activity setObject:self.questionVideoObj forKey:kACtivityTargetVideoKey];
    [activity saveInBackground];
    
    
    // Increment views
    int viewsNum = [[self.questionVideoObj objectForKey:kVideoViewsKey] intValue];
    [self.questionVideoObj setObject:[NSNumber numberWithInt:viewsNum+1] forKey:kVideoViewsKey];
    PFQuery *query = [PFQuery queryWithClassName:kVideoClassKey];
    [query getObjectInBackgroundWithId:[self.questionVideoObj objectId] block:^(PFObject *object, NSError *error) {
        [object setObject:[NSNumber numberWithInt:viewsNum+1] forKey:kVideoViewsKey];
        [object saveInBackground];
    }];
    [self.questionVideoObj saveInBackground];
    
    // Hid all HUD after all objects appered
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
}

- (void)moviePlayBackDidFinish:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
}
- (void) viewWillDisappear:(BOOL)animated {
    [self.movieController stop];
    [self.movieController.view removeFromSuperview];
    self.movieController = nil;
}

- (IBAction)takeAnswer:(id)sender {
    NSLog(@"push Take Answer");
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Answer this question!"
                                                    message:@"After viewing the question, you can answer it by the following options."
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:@"Upload from Library", @"Record from Camera", nil];
    alert.tag = 0;      // Set alert tag is important in case of existence of many alerts
    [alert setAlertViewStyle:UIAlertViewStylePlainTextInput];
    [[alert textFieldAtIndex:0] setPlaceholder:@"Video Name"];
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if(alertView.tag == 0){
        NSLog(@"clickedButton");
        NSLog(@"Text field 1: %@", [alertView textFieldAtIndex:0].text);
        self.answerVideoName = [alertView textFieldAtIndex:0].text;
        if (buttonIndex == 1) {
            NSLog(@"Upload from Library");
            isUploadFromLibrary = true;
            UIImagePickerController *picker = [[UIImagePickerController alloc] init];
            picker.delegate = self;
            picker.allowsEditing = YES;
            picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            picker.mediaTypes = [NSArray arrayWithObject:(NSString *)kUTTypeMovie];
        
            [self presentViewController:picker animated:YES completion:NULL];
        } else if (buttonIndex == 2) {
            NSLog(@"Record from Camera");
            [self startCameraControllerFromViewController:self usingDelegate:self];
        }
        
        // Call another alert after this alert executed
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Seclect Visibility!"
                                                        message:@"Decide who can view this video"
                                                       delegate:self
                                              cancelButtonTitle:@"open"
                                              otherButtonTitles:@"friendOnly", @"onlyMe", nil];
        alert.tag = 2;  // Set alert tag is important in case of existence of many alerts
        [alert show];
    } else if (alertView.tag == 1) {
        NSLog(@"clickedButton");
        NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
        if ([title isEqualToString:@"YES"]) {
            NSLog(@"Wait to upload to server!");
            
            self.pathForFileFromLibrary = recordedVideoPath;
            // Format date to string
            
            NSDate *date = [NSDate date];
            NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
            [dateFormat setDateFormat: @"yyyy-MM-dd HH:mm:ss"];
            NSString *stringFromDate = [dateFormat stringFromDate:date];
            
            uploadFilename = [NSString stringWithFormat:@"%@_%@_%@_%@.mov",[[PFUser currentUser] objectId],[[PFUser currentUser] objectForKey:kUserNameKey], [self.questionVideoObj objectId],stringFromDate];
            
            if(self.uploadFromLibrary == nil || (self.uploadFromLibrary.isFinished && !self.uploadFromLibrary.isPaused)){
                self.uploadFromLibrary = [self.tm uploadFile:self.pathForFileFromLibrary bucket: [Constants transferManagerBucket] key: uploadFilename];
            }
        }
    } else if (alertView.tag == 2) {
        NSLog(@"clickedButton");
        NSLog(@"alert = %@",[alertView buttonTitleAtIndex:buttonIndex]);
        self.answerVideoVisibility = [alertView buttonTitleAtIndex:buttonIndex];
        NSLog(@"visibility = %@", self.answerVideoVisibility);
    }
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
            self.pathForFileFromLibrary = filePath;
            
            // Format date to string
            NSDate *date = [NSDate date];
            NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
            [dateFormat setDateFormat: @"yyyy-MM-dd HH:mm:ss"];
            NSString *stringFromDate = [dateFormat stringFromDate:date];
            
            uploadFilename = [NSString stringWithFormat:@"%@_%@_%@_%@.mov",[[PFUser currentUser] objectId],[[PFUser currentUser] objectForKey:kUserNameKey], [self.questionVideoObj objectId],stringFromDate];
            [picker dismissViewControllerAnimated:YES completion:NULL];
            
            if(self.uploadFromLibrary == nil || (self.uploadFromLibrary.isFinished && !self.uploadFromLibrary.isPaused)){
                self.uploadFromLibrary = [self.tm uploadFile:self.pathForFileFromLibrary bucket: [Constants transferManagerBucket] key: uploadFilename];
            }
        }
    } else {    //capture a video
        NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
        [self dismissViewControllerAnimated:NO completion:nil];
        // Handle a movie capture
        if (CFStringCompare ((__bridge_retained CFStringRef) mediaType, kUTTypeMovie, 0) == kCFCompareEqualTo) {
            NSString *moviePath = [[info objectForKey:UIImagePickerControllerMediaURL] path];
            if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(moviePath)) {
                UISaveVideoAtPathToSavedPhotosAlbum(moviePath, self, @selector(video:didFinishSavingWithError:contextInfo:), nil);
            }
            recordedVideoPath = moviePath;
            // NSLog(moviePath);
        }
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:NULL];
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
                                                        message:@"Saved To Photo Album! Upload Answer to Server?"
                                                       delegate:self
                                              cancelButtonTitle:@"NO"
                                              otherButtonTitles:@"YES", nil];
        alert.tag = 1;      // Set alert tag is important in case of existence of many alerts
        [alert show];
    }
}

#pragma mark - AmazonServiceRequestDelegate

-(void)request:(AmazonServiceRequest *)request didReceiveResponse:(NSURLResponse *)response {
    NSLog(@"didReceiveResponse called: %@", response);
}

-(void)request:(AmazonServiceRequest *)request didSendData:(long long) bytesWritten totalBytesWritten:(long long)totalBytesWritten totalBytesExpectedToWrite:(long long)totalBytesExpectedToWrite {
    double percent = ((double)totalBytesWritten/(double)totalBytesExpectedToWrite)*100;
    self.putObjectTextField.text = [NSString stringWithFormat:@"%.2f%%", percent];
}

-(void)request:(AmazonServiceRequest *)request didCompleteWithResponse:(AmazonServiceResponse *)response {
    self.putObjectTextField.text = @"Done";

    NSLog(@"upload file url: %@", response);
    
    // Register to Parser DB
    PFObject *newVideo = [PFObject objectWithClassName:kVideoClassKey];
    [newVideo setObject:[PFUser currentUser] forKey:kVideoUserKey];
    [newVideo setObject:uploadFilename forKey:kVideoURLKey];
    [newVideo setObject:@"answer" forKey:kVideoTypeKey];
    [newVideo setObject:self.answerVideoName forKey:kVideoNameKey];
    [newVideo setObject:self.answerVideoVisibility forKey:kVideoVisibilityKey];
    
    NSLog(@"%@", [[PFQuery queryWithClassName:kVideoClassKey] getObjectWithId:[self.questionVideoObj objectId]]);
    [newVideo setObject:[[PFQuery queryWithClassName:kVideoClassKey] getObjectWithId:[self.questionVideoObj objectId]] forKey:kVideoAsAReplyTo];
    [newVideo saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        NSLog(@"saved to Parse");
        
        // Send a notification to the device with channel contain video's userId
        NSString *pushMessageFormat = [Constants getConstantbyClass:@"Message" forType:@"Push" withName:@"answered"];
        NSLog(@"pushMessageFormat = %@",pushMessageFormat);
        [PFPush sendPushMessageToChannelInBackground:[[self.questionVideoObj objectForKey:kVideoUserKey] objectId]
                                         withMessage:[NSString stringWithFormat:pushMessageFormat,[self.questionVideoObj objectForKey:kVideoNameKey], [[PFUser currentUser] objectForKey:kUserDisplayNameKey]]];
        
    }];
    
    // Increment answers
    int viewsNum = [[self.questionVideoObj objectForKey:kVideoAnswersKey] intValue];
    [self.questionVideoObj setObject:[NSNumber numberWithInt:viewsNum+1] forKey:kVideoAnswersKey];
    PFQuery *query = [PFQuery queryWithClassName:kVideoClassKey];
    [query getObjectInBackgroundWithId:[self.questionVideoObj objectId] block:^(PFObject *object, NSError *error) {
        [object setObject:[NSNumber numberWithInt:viewsNum+1] forKey:kVideoAnswersKey];
        [object saveInBackground];
    }];
    [self.questionVideoObj saveInBackground];
    NSLog(@"after videoObj = %@", self.questionVideoObj);
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

@end
