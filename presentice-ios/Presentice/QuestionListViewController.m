//
//  QuestionListViewController.m
//  Presentice
//
//  Created by レー フックダイ on 12/31/13.
//  Copyright (c) 2013 Presentice. All rights reserved.
//

#import "QuestionListViewController.h"

@interface QuestionListViewController ()

#pragma upload question video
@property (nonatomic, strong) S3TransferOperation *uploadDidRecord;
@property (nonatomic, strong) S3TransferOperation *uploadFromLibrary;
@property (nonatomic, strong) NSString *pathForFileFromLibrary;

@end

@implementation QuestionListViewController {
    
    NSArray *searchResults;
    
#pragma upload question video
    NSString *uploadFilename;
    bool isUploadFromLibrary;
    NSString *recordedVideoPath;
}

- (id)initWithCoder:(NSCoder *)aCoder {
    self = [super initWithCoder:aCoder];
    if (self) {
        // Custom the table
        self.parseClassName = kVideoClassKey;
        self.textKey = kVideoURLKey;
        self.pullToRefreshEnabled = YES;
        self.paginationEnabled = NO;
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
            self.tm = [PresenticeUtility getS3TransferManagerForDelegate:self withEndPoint:AP_NORTHEAST_1 andRegion:[S3Region APJapan]];
        } else {
            [PresenticeUtility alertBucketCreatingError];
        }
    }
    
    // Set refreshTable notification
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshTable:)
                                                 name:@"refreshTable"
                                               object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:YES];
    NSLog(@"question list self = %@", self);
    
    // Hid all HUD after all objects appered
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    
    [PresenticeUtility checkCurrentUserActivationIn:self];
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
    PFQuery *questionListQuery = [PFQuery queryWithClassName:kVideoClassKey];
    [questionListQuery whereKey:kVideoTypeKey equalTo:@"question"];
    [questionListQuery includeKey:kVideoUserKey];   // Important: Include "user" key in this query make receiving user info easier

    // If no objects are loaded in memory, we look to the cache first to fill the table
    // and then subsequently do a query against the network.
    if ([self.objects count] == 0) {
        questionListQuery.cachePolicy = kPFCachePolicyCacheThenNetwork;
    }
    
    [questionListQuery orderByAscending:kVideoViewsKey];
    return questionListQuery;
}

#pragma Search Display Controller

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope {
    
    NSPredicate *resultPredicate = ([scope isEqualToString:@"Video Name"]) ? [NSPredicate predicateWithFormat:@"videoName contains[c] %@", searchText] : [NSPredicate predicateWithFormat:@"user.displayName contains[c] %@", searchText];
    
    searchResults = [self.objects filteredArrayUsingPredicate:resultPredicate];
}

-(BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    [self filterContentForSearchText:searchString
                               scope:[[self.searchDisplayController.searchBar scopeButtonTitles]
                                      objectAtIndex:[self.searchDisplayController.searchBar
                                                     selectedScopeButtonIndex]]];
    
    return YES;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (tableView != self.searchDisplayController.searchResultsTableView) ? self.objects.count : searchResults.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 75;
}

// Override to customize the look of a cell representing an object. The default is to display
// a UITableViewCellStyleDefault style cell with the label being the first key in the object.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object {
    
    PFObject *displayObject = (tableView != self.searchDisplayController.searchResultsTableView) ? object : [searchResults objectAtIndex:indexPath.row];
    
    static NSString *simpleTableIdentifier = @"questionListIdentifier";
    QuestionListTableCell *cell = (QuestionListTableCell*)[self.tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    if (cell == nil) {
        cell = [[QuestionListTableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
    }
    
     // Configure the cell
    [PresenticeUtility setImageView:cell.userProfilePicture forUser:[displayObject objectForKey:kVideoUserKey]];
    cell.postedUser.text = [[displayObject objectForKey:kVideoUserKey] objectForKey:kUserDisplayNameKey];
    cell.videoName.text = [PresenticeUtility nameOfVideo:displayObject];
    cell.postedTime.text = [NSString stringWithFormat:@"%@", [[[NSDate alloc] initWithTimeInterval:0 sinceDate:displayObject.createdAt] dateTimeUntilNow]];
    [PresenticeUtility setLabel:cell.viewsNum withKey:kVideoViewsKey forObject:displayObject];
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

        destViewController.movieURL = [PresenticeUtility s3URLForObject:object];
        destViewController.questionVideoObj = object;
    }
}

#pragma Amazon implemented methods

- (IBAction)showLeftMenu:(id)sender {
    [self.menuContainerViewController toggleLeftSideMenuCompletion:nil];
}

- (IBAction)addQuestion:(id)sender {
    NSNumber *canPostQuestion = [[[[PFUser currentUser] objectForKey:kUserPromotionKey] fetchIfNeeded] objectForKey:kPromotionCanPostQuestion];
    bool canPost = [canPostQuestion boolValue];
    
    if (canPost == true) {
        [PresenticeUtility callAlert:alertWillPostQuestion withDelegate:self];
    } else {
        [PresenticeUtility callAlert:alertWillSuggestQuestion withDelegate:self];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == tagWillPostQuestion) {           // Post new question

        self.newQuestionVideoName = [alertView textFieldAtIndex:0].text;
        if (buttonIndex == 1) {         // Upload from library
            isUploadFromLibrary = true;
            [PresenticeUtility startImagePickerFromViewController:self usingDelegate:self withTimeLimit:VIDEO_TIME_LIMIT];
            
        } else if (buttonIndex == 2) {  // Record from camera
            isUploadFromLibrary = false;
            [PresenticeUtility startCameraControllerFromViewController:self usingDelegate:self withTimeLimit:VIDEO_TIME_LIMIT];
            
        }
    } else if (alertView.tag == tagWillSuggestQuestion) {
        if (buttonIndex == 1) {
            PFObject *newSuggest = [PFObject objectWithClassName:kActivityClassKey];
            [newSuggest setObject:@"suggestQuestion" forKey:kActivityTypeKey];
            [newSuggest setObject:[PFUser currentUser] forKey:kActivityFromUserKey];
            [newSuggest setObject:[alertView textFieldAtIndex:0].text forKey:kActivityDescriptionKey];
            [newSuggest saveInBackground];
        }
    } else if (alertView.tag == tagDidSaveVideo) {
        if (buttonIndex == 1) {
            [MBProgressHUD showHUDAddedTo:self.view animated:YES];
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
    } else if (alertView.tag == tagWillAddNote) {
        if (buttonIndex == 1) {
            EditNoteViewController *editNoteViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"editNoteViewController"];
            editNoteViewController.note = [self.newQuestionVideoObj objectForKey:kVideoNoteKey];
            editNoteViewController.videoObj = self.newQuestionVideoObj;
            
            [self.navigationController pushViewController:editNoteViewController animated:YES];
        }
    }
}

#pragma mark - Image Picker Controller delegate methods
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    if (isUploadFromLibrary) {  //upload file from Library
        NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
        if ([mediaType isEqualToString:(NSString *)kUTTypeMovie]) {
            [MBProgressHUD showHUDAddedTo:self.view animated:YES];
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
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
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
        }
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

-(void)video:(NSString*)videoPath didFinishSavingWithError:(NSError*)error contextInfo:(void*)contextInfo {
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    if (error) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"Video Saving Failed", nil)
                                                       delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
        [alert show];
    } else {
        [PresenticeUtility callAlert:alertDidSaveVideo withDelegate:self];
    }
}

- (void)saveToParse {
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    // Register to Parser DB
    PFObject *newVideo = [PFObject objectWithClassName:kVideoClassKey];
    [newVideo setObject:[PFUser currentUser] forKey:kVideoUserKey];
    [newVideo setObject:uploadFilename forKey:kVideoURLKey];
    [newVideo setObject:@"question" forKey:kVideoTypeKey];
    [newVideo setObject:self.newQuestionVideoName forKey:kVideoNameKey];
    [newVideo setObject:@"open" forKey:kVideoVisibilityKey];
    [newVideo setObject:[NSNumber numberWithInt:0] forKey:kVideoViewsKey];
    [newVideo saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (!error) {
            NSLog(@"saved to Parse");
            self.newQuestionVideoObj = newVideo;

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
            
            [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
            
            // Add a note
            [PresenticeUtility callAlert:alertWillAddNote withDelegate:self];
        } else {
            [PresenticeUtility showErrorAlert:error];
        }
    }];
}

#pragma mark - AmazonServiceRequestDelegate

-(void)request:(AmazonServiceRequest *)request didReceiveResponse:(NSURLResponse *)response {
    NSLog(@"didReceiveResponse called: %@", response);
}

-(void)request:(AmazonServiceRequest *)request didSendData:(long long)bytesWritten totalBytesWritten:(long long)totalBytesWritten totalBytesExpectedToWrite:(long long)totalBytesExpectedToWrite {
    if ([MBProgressHUD allHUDsForView:self.view].count == 0)
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    double percent = ((double)totalBytesWritten/(double)totalBytesExpectedToWrite)*100;
    NSLog(@"totalBytesWritten = %.2f%%", percent);
}

-(void)request:(AmazonServiceRequest *)request didCompleteWithResponse:(AmazonServiceResponse *)response {
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    NSLog(@"Upload done!");
    NSLog(@"upload file url: %@", response);
    
    [self saveToParse];
}

-(void)request:(AmazonServiceRequest *)request didFailWithError:(NSError *)error {
    NSLog(@"didFailWithError called: %@", error);
}

-(void)request:(AmazonServiceRequest *)request didFailWithServiceException:(NSException *)exception {
    NSLog(@"didFailWithServiceException called: %@", exception);
}

@end