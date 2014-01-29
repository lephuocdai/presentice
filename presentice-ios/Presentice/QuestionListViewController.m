//
//  QuestionListViewController.m
//  Presentice
//
//  Created by レー フックダイ on 12/31/13.
//  Copyright (c) 2013 Presentice. All rights reserved.
//

#import "QuestionListViewController.h"

@interface QuestionListViewController ()

@property (nonatomic, strong) S3TransferOperation *uploadDidRecord;
@property (nonatomic, strong) S3TransferOperation *uploadFromLibrary;
@property (nonatomic, strong) NSString *pathForFileFromLibrary;

@end

@implementation QuestionListViewController {
    NSString *uploadFilename;
    bool isUploadFromLibrary;
    NSString *recordedVideoPath;
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
    
    // Initiate S3 bucket access
    if(self.tm == nil){
        if(![ACCESS_KEY_ID isEqualToString:@"CHANGE ME"]){
            self.tm = [PresenticeUtitily getS3TransferManagerForDelegate:self withEndPoint:AP_NORTHEAST_1 andRegion:[S3Region APJapan]];
        } else {
            [PresenticeUtitily alertBucketCreatingError];
        }
    }
    
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
    UIImageView *userProfilePicture = (UIImageView *)[cell viewWithTag:100];
    UILabel *postedUser = (UILabel *)[cell viewWithTag:101];
    UILabel *postedTime = (UILabel *)[cell viewWithTag:102];
    UILabel *videoName = (UILabel *)[cell viewWithTag:103];
    UILabel *viewsNum = (UILabel *)[cell viewWithTag:104];
    UILabel *answersNum = (UILabel *)[cell viewWithTag:105];
    
    [PresenticeUtitily setImageView:userProfilePicture forUser:[object objectForKey:kVideoUserKey]];
    postedUser.text = [[object objectForKey:kVideoUserKey] objectForKey:kUserDisplayNameKey];
    videoName.text = [object objectForKey:kVideoNameKey];
    postedTime.text = [NSString stringWithFormat:@"%@", [[[NSDate alloc] initWithTimeInterval:0 sinceDate:object.createdAt] dateTimeUntilNow]];
    viewsNum.text = [PresenticeUtitily stringNumberOfKey:kVideoViewsKey inObject:object];
    answersNum.text = [PresenticeUtitily stringNumberOfKey:kVideoAnswersKey inObject:object];
    
    return cell;
}

- (void) objectsDidLoad:(NSError *)error {
    [super objectsDidLoad:error];
    NSLog(@"error: %@", [error localizedDescription]);
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

    if ([segue.identifier isEqualToString:@"showQuestionDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        QuestionDetailViewController *destViewController = segue.destinationViewController;
        
        PFObject *object = [self.objects objectAtIndex:indexPath.row];
        NSLog(@"sent object = %@", object);
        destViewController.movieURL = [PresenticeUtitily s3URLForObject:object];
        destViewController.questionVideoObj = object;
    }
}

#pragma Amazon implemented methods

- (IBAction)showLeftMenu:(id)sender {
    [self.menuContainerViewController toggleLeftSideMenuCompletion:nil];
}

- (IBAction)addQuestion:(id)sender {
    NSNumber *canPostQuestion = [[PFUser currentUser] objectForKey:kUserCanPostQuestion];
    bool canPost = [canPostQuestion boolValue];
//    NSLog(@"canPostQuestion = %hhd", canPost);
    
    if (canPost == true) {
        UIAlertView *postAlert = [[UIAlertView alloc] initWithTitle:@"Post a new challenge"
                                                        message:@"You can add new challenge by the following options."
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:@"Upload from Library", @"Record from Camera", nil];
        postAlert.tag = 0;      // Set alert tag is important in case of existence of many alerts
        [postAlert setAlertViewStyle:UIAlertViewStylePlainTextInput];
        [[postAlert textFieldAtIndex:0] setPlaceholder:@"Title of the challenge"];
        [postAlert show];
    } else {
        UIAlertView *suggestAlert = [[UIAlertView alloc] initWithTitle:@"Suggest new challenge!" message:@"Suggest a challenge and we will consider making it" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Post", nil];
        suggestAlert.tag = 1;
        [suggestAlert setAlertViewStyle:UIAlertViewStylePlainTextInput];
        [[suggestAlert textFieldAtIndex:0] setPlaceholder:@"Details"];
        [suggestAlert show];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 0) {           // Post new question
        NSLog(@"postQuestion started");
        self.questionVideoName = [alertView textFieldAtIndex:0].text;
        if (buttonIndex == 1) {         // Upload from library
            NSLog(@"Upload from Library");
            isUploadFromLibrary = true;
            [PresenticeUtitily startImagePickerFromViewController:self usingDelegate:self withTimeLimit:VIDEO_TIME_LIMIT];
        } else if (buttonIndex == 2) {  // Record from camera
            NSLog(@"Record from Camera");
            isUploadFromLibrary = false;
            [PresenticeUtitily startCameraControllerFromViewController:self usingDelegate:self withTimeLimit:VIDEO_TIME_LIMIT];
        }
    } else if (alertView.tag == 1) {
        if (buttonIndex == 1) {
            NSLog(@"clicked Post Button");
            PFObject *newSuggest = [PFObject objectWithClassName:kActivityClassKey];
            [newSuggest setObject:@"suggestQuestion" forKey:kActivityTypeKey];
            [newSuggest setObject:[PFUser currentUser] forKey:kActivityFromUserKey];
            [newSuggest setObject:[alertView textFieldAtIndex:0].text forKey:kActivityDescriptionKey];
            [newSuggest saveInBackground];
        }
    } else if (alertView.tag == 2) {
        if (buttonIndex == 1) {
            NSLog(@"clicked YES Button");
            NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
            if ([title isEqualToString:@"YES"]) {
                NSLog(@"Wait to upload to server!");
                
                self.pathForFileFromLibrary = recordedVideoPath;
                // Format date to string
                
                NSDate *date = [NSDate date];
                NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
                [dateFormat setDateFormat: @"yyyy-MM-dd HH:mm:ss"];
                NSString *stringFromDate = [dateFormat stringFromDate:date];
                
                uploadFilename = [NSString stringWithFormat:@"%@_%@_question_%@.mov",[[PFUser currentUser] objectId],[[PFUser currentUser] objectForKey:kUserNameKey], stringFromDate];
                
                if(self.uploadFromLibrary == nil || (self.uploadFromLibrary.isFinished && !self.uploadFromLibrary.isPaused)){
                    self.uploadFromLibrary = [self.tm uploadFile:self.pathForFileFromLibrary bucket:[Constants transferManagerBucket] key:uploadFilename];
                }
            }
        }
    }
}

#pragma mark - Image Picker Controller delegate methods
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    if (isUploadFromLibrary) {  //upload file from Library
        NSLog(@"upload from library");
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
            
            uploadFilename = [NSString stringWithFormat:@"%@_%@_question_%@.mov",[[PFUser currentUser] objectId],[[PFUser currentUser] objectForKey:kUserNameKey], stringFromDate];
            
            [picker dismissViewControllerAnimated:YES completion:NULL];
            
            if(self.uploadFromLibrary == nil || (self.uploadFromLibrary.isFinished && !self.uploadFromLibrary.isPaused)){
                self.uploadFromLibrary = [self.tm uploadFile:self.pathForFileFromLibrary bucket: [Constants transferManagerBucket] key: uploadFilename];
            }
        }
    } else {    //capture a video
        NSLog(@"call camera");
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
        alert.tag = 2;      // Set alert tag is important in case of existence of many alerts
        [alert show];
    }
}

#pragma mark - AmazonServiceRequestDelegate

-(void)request:(AmazonServiceRequest *)request didReceiveResponse:(NSURLResponse *)response {
    NSLog(@"didReceiveResponse called: %@", response);
}

-(void)request:(AmazonServiceRequest *)request didSendData:(long long) bytesWritten totalBytesWritten:(long long)totalBytesWritten totalBytesExpectedToWrite:(long long)totalBytesExpectedToWrite {
    double percent = ((double)totalBytesWritten/(double)totalBytesExpectedToWrite)*100;
    NSLog(@"totalBytesWritten = %.2f%%", percent);
}

-(void)request:(AmazonServiceRequest *)request didCompleteWithResponse:(AmazonServiceResponse *)response {
    
    NSLog(@"upload file url: %@", response);
    
    // Register to Parser DB
    PFObject *newVideo = [PFObject objectWithClassName:kVideoClassKey];
    [newVideo setObject:[PFUser currentUser] forKey:kVideoUserKey];
    [newVideo setObject:uploadFilename forKey:kVideoURLKey];
    [newVideo setObject:@"question" forKey:kVideoTypeKey];
    [newVideo setObject:self.questionVideoName forKey:kVideoNameKey];
    [newVideo setObject:@"open" forKey:kVideoVisibilityKey];
    
    [newVideo saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        NSLog(@"saved to Parse");
        UIAlertView *savedToParseSuccess = [[UIAlertView alloc] initWithTitle:@"Upload Success" message:@"Your video has been uploaded successfully" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [savedToParseSuccess show];
/**
        // Send a notification to the device with channel contain video's userId
        NSLog(@"viewd push = %@", [[[self.questionVideoObj objectForKey:kVideoUserKey] objectForKey:kUserPushPermission] objectForKey:@"answered"]);
        if ([[[[self.questionVideoObj objectForKey:kVideoUserKey] objectForKey:kUserPushPermission] objectForKey:@"answered"] isEqualToString:@"yes"]) {
            NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
            [params setObject:[self.questionVideoObj objectForKey:kVideoNameKey] forKey:@"targetVideo"];
            [params setObject:[[self.questionVideoObj objectForKey:kVideoUserKey] objectId] forKey:@"toUser"];
            [params setObject:@"answered" forKey:@"pushType"];
            [PFCloud callFunction:@"sendPushNotification" withParameters:params];
        }
**/
        
        // Register postQuestionActivity in to Activity Table
        PFObject *postQuestionActivity = [PFObject objectWithClassName:kActivityClassKey];
        [postQuestionActivity setObject:@"postQuestion" forKey:kActivityTypeKey];
        [postQuestionActivity setObject:[PFUser currentUser] forKey:kActivityFromUserKey];
        [postQuestionActivity setObject:newVideo forKey:kActivityTargetVideoKey];
        [postQuestionActivity saveInBackground];
    }];
}

-(void)request:(AmazonServiceRequest *)request didFailWithError:(NSError *)error {
    NSLog(@"didFailWithError called: %@", error);
}

-(void)request:(AmazonServiceRequest *)request didFailWithServiceException:(NSException *)exception {
    NSLog(@"didFailWithServiceException called: %@", exception);
}

@end