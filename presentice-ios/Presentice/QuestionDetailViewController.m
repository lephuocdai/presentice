//
//  QuestionDetailViewController.m
//  Presentice
//
//  Created by レー フックダイ on 1/14/14.
//  Copyright (c) 2014 Presentice. All rights reserved.
//

#import "QuestionDetailViewController.h"

@interface QuestionDetailViewController ()

#pragma upload answer video
@property (nonatomic, strong) S3TransferOperation *uploadDidRecord;
@property (nonatomic, strong) S3TransferOperation *uploadFromLibrary;
@property (nonatomic, strong) NSString *pathForFileFromLibrary;

@end

@implementation QuestionDetailViewController {
    
#pragma upload answer video
    NSString *uploadFilename;
    bool isUploadFromLibrary;
    NSString *recordedVideoPath;
}

@synthesize videoNameLabel;
@synthesize postedUserLabel;
@synthesize noteView;

- (id)initWithCoder:(NSCoder *)aCoder {
    self = [super initWithCoder:aCoder];
    if (self) {
        // Custom the table
        
        // The className to query on
        self.parseClassName = kVideoClassKey;
        
        // The key of the PFObject to display in the label of the default cell style
        self.textKey = kVideoNameKey;
        
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
    
    [PresenticeUtility setImageView:self.userProfilePicture forUser:[self.questionVideoObj objectForKey:kVideoUserKey]];
    postedUserLabel.text = [[self.questionVideoObj objectForKey:kVideoUserKey] objectForKey:kUserDisplayNameKey];
    videoNameLabel.text = [self.questionVideoObj objectForKey:kVideoNameKey];
    noteView.text = [NSString stringWithFormat:@"Note for viewer: \n%@",[self.questionVideoObj objectForKey:kVideoNoteKey]];
    [noteView boldSubstring:@"Note for viewer:"];
    
    // Set tap gesture on noteview
    UITapGestureRecognizer *singleTapForNote = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(actionHandleTapOnNoteView)];
    [singleTapForNote setNumberOfTapsRequired:1];
    noteView.userInteractionEnabled = YES;
    [noteView addGestureRecognizer:singleTapForNote];
    
    // Set tap gesture on user profile picture
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(actionHandleTapOnImageView)];
    [singleTap setNumberOfTapsRequired:1];
    self.userProfilePicture.userInteractionEnabled = YES;
    [self.userProfilePicture addGestureRecognizer:singleTap];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;

#pragma play movie
    // Set up movieController
    self.movieController = [[MPMoviePlayerController alloc] init];
    [self.movieController setContentURL:self.movieURL];
    [self.movieController.view setFrame:CGRectMake(0, 0, 320, 380)];
    [self.videoView addSubview:self.movieController.view];
    
    // Using the Movie Player Notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayBackDidFinish:) name:MPMoviePlayerPlaybackDidFinishNotification object:self.movieController];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterFullScreen:) name:MPMoviePlayerWillEnterFullscreenNotification object:nil];
    
    self.movieController.controlStyle =  MPMovieControlStyleEmbedded;
    self.movieController.shouldAutoplay = YES;
    self.movieController.repeatMode = NO;
    [self.movieController prepareToPlay];
    [self.movieController play];

    
#pragma upload answer video
    // Initiate S3 bucket access
    if(self.tm == nil){
        if(![ACCESS_KEY_ID isEqualToString:@"CHANGE ME"]){
            self.tm = [PresenticeUtility getS3TransferManagerForDelegate:self withEndPoint:AP_NORTHEAST_1 andRegion:[S3Region APJapan]];
        }else {
            [PresenticeUtility alertBucketCreatingError];
        }
    }
    
	// Set refreshTable notification
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshTable:)
                                                 name:@"refreshTable"
                                               object:nil];
}

- (void)actionHandleTapOnNoteView {
    UIAlertView *noteDisplayAlert = [[UIAlertView alloc] initWithTitle:@"Fully display note" message:@"Do you want to view this note fully" delegate:self cancelButtonTitle:@"No, it's ok" otherButtonTitles:@"Yes, show me", nil];
    noteDisplayAlert.tag = 4;
    [noteDisplayAlert show];
}

- (void)actionHandleTapOnImageView {
    UserProfileViewController *userProfileViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"userProfileViewController"];
    userProfileViewController.userObj = [self.questionVideoObj objectForKey:kVideoUserKey];
    [self.navigationController pushViewController:userProfileViewController animated:YES];
}

- (void)viewWillAppear:(BOOL)animated {
    // If currentUser is not the video's owner
    if (![[[PFUser currentUser] objectId] isEqualToString:[[self.questionVideoObj objectForKey:kVideoUserKey] objectId]]) {
        // Send a notification to the device with channel contain questionVideo's userId
        NSLog(@"viewd push = %@", [[[self.questionVideoObj objectForKey:kVideoUserKey] objectForKey:kUserPushPermission] objectForKey:@"viewed"]);
        if ([[[[self.questionVideoObj objectForKey:kVideoUserKey] objectForKey:kUserPushPermission] objectForKey:@"viewed"] isEqualToString:@"yes"]) {
            NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
            [params setObject:[self.questionVideoObj objectForKey:kVideoNameKey] forKey:@"targetVideo"];
            [params setObject:[[self.questionVideoObj objectForKey:kVideoUserKey] objectId] forKey:@"toUser"];
            [params setObject:@"viewed" forKey:@"pushType"];
            [PFCloud callFunction:@"sendPushNotification" withParameters:params];
        }
        
        PFQuery *activityQuery = [PFQuery queryWithClassName:kActivityClassKey];
        [activityQuery whereKey:kActivityTypeKey equalTo:@"view"];
        [activityQuery whereKey:kActivityFromUserKey equalTo:[PFUser currentUser]];
        [activityQuery whereKey:kActivityToUserKey equalTo:[self.questionVideoObj objectForKey:kVideoUserKey]];
        [activityQuery whereKey:kActivityTargetVideoKey equalTo:self.questionVideoObj];
        [activityQuery getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
            if (!error) {
                // Found activity record, so just overwrote it
                NSMutableDictionary *views = [[NSMutableDictionary alloc]initWithDictionary:[object objectForKey:kActivityContentKey]];
                [views setObject:@{@"date": [NSDate date]} forKey:[NSString stringWithFormat:@"%d", [[views allKeys] count]]];
                [object setObject:views forKey:kActivityContentKey];
                [object saveInBackground];
            } else {
                // No activity record, so create a new activity
                PFObject *activity = [PFObject objectWithClassName:kActivityClassKey];
                [activity setObject:@"view" forKey:kActivityTypeKey];
                [activity setObject:[PFUser currentUser] forKey:kActivityFromUserKey];
                [activity setObject:[self.questionVideoObj objectForKey:kVideoUserKey] forKey:kActivityToUserKey];
                [activity setObject:self.questionVideoObj forKey:kActivityTargetVideoKey];
                [activity setObject:@{@"0":@{@"date": [NSDate date]}} forKey:kActivityContentKey];
                [activity saveInBackground];
            }
        }];
        
        
        // Increment views: need to be revised
        int viewsNum = [[self.questionVideoObj objectForKey:kVideoViewsKey] intValue];
        [self.questionVideoObj setObject:[NSNumber numberWithInt:viewsNum+1] forKey:kVideoViewsKey];
        PFQuery *query = [PFQuery queryWithClassName:kVideoClassKey];
        [query getObjectInBackgroundWithId:[self.questionVideoObj objectId] block:^(PFObject *object, NSError *error) {
            [object setObject:[NSNumber numberWithInt:viewsNum+1] forKey:kVideoViewsKey];
            [object saveInBackground];
        }];
        [self.questionVideoObj saveInBackground];
    }
}


- (void)viewDidAppear:(BOOL)animated {
    // Hid all HUD after all objects appered
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
}

-(void) viewWillDisappear:(BOOL)animated {
    //stop playing video
    if([self.navigationController.viewControllers indexOfObject:self] == NSNotFound){
        //Release any retained subviews of the main view.
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"refreshTable" object:nil];
        
        //release movie controller
        [self.movieController stop];
        [self.movieController.view removeFromSuperview];
        self.movieController = nil;
    }
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)refreshTable:(NSNotification *) notification {
    // Reload the recipes
    [self loadObjects];
}

#pragma query table objects

- (PFQuery *)queryForTable {
    PFQuery *answerListQuery = [PFQuery queryWithClassName:self.parseClassName];
    [answerListQuery includeKey:kVideoUserKey];   // Important: Include "user" key in this query make receiving user info easier
    [answerListQuery whereKey:kVideoTypeKey equalTo:@"answer"];
    [answerListQuery whereKey:kVideoAsAReplyTo equalTo:self.questionVideoObj];
    [answerListQuery whereKey:kVideoVisibilityKey containedIn:@[@"open"]];
    
    // If no objects are loaded in memory, we look to the cache first to fill the table
    // and then subsequently do a query against the network.
    if ([self.objects count] == 0) {
        answerListQuery.cachePolicy = kPFCachePolicyCacheThenNetwork;
    }
    [answerListQuery orderByAscending:kUpdatedAtKey];
    return answerListQuery;
}

#pragma play movie

- (void)moviePlayBackDidFinish:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
}

- (void)willEnterFullScreen:(NSNotification *)notification {
    NSLog(@"Enter full screen mode");
}

#pragma mark - Table view data source

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return @"Answers of this challenge";
    } else {
        return @"";
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object {
    static NSString *simpleTableIdentifier = @"answerListIdentifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
    }
    
    // Configure the cell
    UIImageView *userProfilePicture = (UIImageView *)[cell viewWithTag:100];
    UILabel *userName = (UILabel *)[cell viewWithTag:101];
    UILabel *videoName = (UILabel *)[cell viewWithTag:102];
    UILabel *viewsNum = (UILabel *)[cell viewWithTag:103];
    UILabel *reviewNum = (UILabel *)[cell viewWithTag:104];
    
    [PresenticeUtility setImageView:userProfilePicture forUser:[object objectForKey:kVideoUserKey]];
    userName.text = [[object objectForKey:kVideoUserKey] objectForKey:kUserDisplayNameKey];
    videoName.text = [object objectForKey:kVideoNameKey];
    viewsNum.text = [NSString stringWithFormat:@"view: %@",[object objectForKey:kVideoViewsKey]];
    reviewNum.text = [NSString stringWithFormat:@"reviews: %d",[[object objectForKey:kVideoReviewsKey] count]];
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
    if ([segue.identifier isEqualToString:@"showAnswerFromQuestion"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        VideoViewController *destViewController = segue.destinationViewController;
        
        PFObject *object = [self.objects objectAtIndex:indexPath.row];
        NSLog(@"sent object = %@", object);
        destViewController.movieURL = [PresenticeUtility s3URLForObject:object];
        destViewController.answerVideoObj = object;
    }
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}

#pragma upload answer video

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
        self.newAnswerVideoName = [alertView textFieldAtIndex:0].text;
        if (buttonIndex > 0) {
            if (buttonIndex == 1) {
                NSLog(@"Upload from Library");
                isUploadFromLibrary = true;
                [PresenticeUtility startImagePickerFromViewController:self usingDelegate:self withTimeLimit:VIDEO_TIME_LIMIT];
            } else if (buttonIndex == 2) {
                NSLog(@"Record from Camera");
                isUploadFromLibrary = false;
                [PresenticeUtility startCameraControllerFromViewController:self usingDelegate:self withTimeLimit:VIDEO_TIME_LIMIT];
            }
        }
        NSLog(@"cancel, buttonIndex = %d", buttonIndex);
    } else if (alertView.tag == 1) {
        if (buttonIndex == 1) {
            NSLog(@"clicked YES Button");
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
        NSLog(@"alert = %@",[alertView buttonTitleAtIndex:buttonIndex]);
        if (buttonIndex == 0)
            self.newAnswerVideoVisibility = @"open";
        else if (buttonIndex == 1)
            self.newAnswerVideoVisibility = @"friendOnly";
        else
            self.newAnswerVideoVisibility = @"onlyMe";
        NSLog(@"visibility = %@", self.newAnswerVideoVisibility);
        [self saveToParse];
        
    } else if (alertView.tag == 3) {
        if (buttonIndex == 1) {
            EditNoteViewController *editNoteViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"editNoteViewController"];
            editNoteViewController.note = [self.newAnswerVideoObj objectForKey:kVideoNoteKey];
            editNoteViewController.videoObj = self.newAnswerVideoObj;
            
            [self.navigationController pushViewController:editNoteViewController animated:YES];
        }
    } else if (alertView.tag == 4) {
        if (buttonIndex == 1) {
            EditNoteViewController *editNoteViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"editNoteViewController"];
            editNoteViewController.note = [self.questionVideoObj objectForKey:kVideoNoteKey];
            editNoteViewController.videoObj = self.questionVideoObj;
            
            [self.navigationController pushViewController:editNoteViewController animated:YES];
        }
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
                                                        message:@"Saved To Photo Album! Upload Answer to Presentice Server?"
                                                       delegate:self
                                              cancelButtonTitle:@"NO"
                                              otherButtonTitles:@"YES", nil];
        alert.tag = 1;      // Set alert tag is important in case of existence of many alerts
        [alert show];
    }
}

#pragma mark - Helpers

- (void)saveToParse {
    
    // Register to Parser DB
    PFObject *newVideo = [PFObject objectWithClassName:kVideoClassKey];
    [newVideo setObject:[PFUser currentUser] forKey:kVideoUserKey];
    [newVideo setObject:uploadFilename forKey:kVideoURLKey];
    [newVideo setObject:@"answer" forKey:kVideoTypeKey];
    [newVideo setObject:self.newAnswerVideoName forKey:kVideoNameKey];
    [newVideo setObject:self.newAnswerVideoVisibility forKey:kVideoVisibilityKey];
    [newVideo setObject:[NSNumber numberWithInt:0] forKey:kVideoViewsKey];
    [newVideo setObject:self.questionVideoObj forKey:kVideoAsAReplyTo];
    [newVideo setObject:[self.questionVideoObj objectForKey:kVideoUserKey] forKey:kVideoToUserKey];
    [newVideo saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (!error) {
            NSLog(@"saved to Parse");
            self.newAnswerVideoObj = newVideo;
            
            // Send a notification to the device with channel contain video's userId
            NSLog(@"viewd push = %@", [[[self.questionVideoObj objectForKey:kVideoUserKey] objectForKey:kUserPushPermission] objectForKey:@"answered"]);
            if ([[[[self.questionVideoObj objectForKey:kVideoUserKey] objectForKey:kUserPushPermission] objectForKey:@"answered"] isEqualToString:@"yes"]) {
                NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
                [params setObject:[self.questionVideoObj objectForKey:kVideoNameKey] forKey:@"targetVideo"];
                [params setObject:[[self.questionVideoObj objectForKey:kVideoUserKey] objectId] forKey:@"toUser"];
                [params setObject:@"answered" forKey:@"pushType"];
                [PFCloud callFunction:@"sendPushNotification" withParameters:params];
            }
            
            // Register answerActivity in to Activity Table
            PFObject *answerActivity = [PFObject objectWithClassName:kActivityClassKey];
            [answerActivity setObject:@"answer" forKey:kActivityTypeKey];
            [answerActivity setObject:[PFUser currentUser] forKey:kActivityFromUserKey];
            [answerActivity setObject:newVideo forKey:kActivityTargetVideoKey];
            [answerActivity setObject:[self.questionVideoObj objectForKey:kVideoUserKey] forKey:kActivityToUserKey];
            [answerActivity saveInBackground];
            
            // Add a note
            UIAlertView *addNoteAlert = [[UIAlertView alloc] initWithTitle:@"Upload Success" message:@"Your video has been uploaded to Presentice successfully. Do you want to add a note for those who will view this video?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
            addNoteAlert.tag = 3;
            [addNoteAlert show];

        } else {
            [PresenticeUtility showErrorAlert:error];
        }
        
        // Hid all HUD after saved
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    }];
    
    // Increment answers
    int viewsNum = [[self.questionVideoObj objectForKey:kVideoAnswersKey] intValue];
    [self.questionVideoObj setObject:[NSNumber numberWithInt:viewsNum+1] forKey:kVideoAnswersKey];
    PFQuery *query = [PFQuery queryWithClassName:kVideoClassKey];
    [query getObjectInBackgroundWithId:[self.questionVideoObj objectId] block:^(PFObject *object, NSError *error) {
        [object setObject:[NSNumber numberWithInt:viewsNum+1] forKey:kVideoAnswersKey];
        [object saveInBackground];
        [self.questionVideoObj saveInBackground];
    }];
    NSLog(@"after videoObj = %@", self.questionVideoObj);
}

#pragma mark - AmazonServiceRequestDelegate

-(void)request:(AmazonServiceRequest *)request didReceiveResponse:(NSURLResponse *)response {
    NSLog(@"didReceiveResponse called: %@", response);
}

-(void)request:(AmazonServiceRequest *)request didSendData:(long long) bytesWritten totalBytesWritten:(long long)totalBytesWritten totalBytesExpectedToWrite:(long long)totalBytesExpectedToWrite {
    double percent = ((double)totalBytesWritten/(double)totalBytesExpectedToWrite)*100;
    NSLog(@"percent = %.2f%%", percent);
}

-(void)request:(AmazonServiceRequest *)request didCompleteWithResponse:(AmazonServiceResponse *)response {
    NSLog(@"Upload done!");
    NSLog(@"upload file url: %@", response);
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Visibility Selection"
                                                    message:@"Decide who can view this video.\n※You can change it later."
                                                   delegate:self
                                          cancelButtonTitle:@"Open inside Presentice"
                                          otherButtonTitles:@"Only friends who are following me", @"Only Me", nil];
    alert.tag = 2;
    [alert show];
}

-(void)request:(AmazonServiceRequest *)request didFailWithError:(NSError *)error {
    NSLog(@"didFailWithError called: %@", error);
}

-(void)request:(AmazonServiceRequest *)request didFailWithServiceException:(NSException *)exception {
    NSLog(@"didFailWithServiceException called: %@", exception);
}

@end
