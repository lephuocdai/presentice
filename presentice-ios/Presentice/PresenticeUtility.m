//
//  PresenticeUtitily.m
//  Presentice
//
//  Created by レー フックダイ on 1/9/14.
//  Copyright (c) 2014 Presentice. All rights reserved.
//

#import "PresenticeUtility.h"

@implementation PresenticeUtility

#pragma mark - PresenticeUtitily
#pragma mark Shadow Rendering

+ (void)drawSideAndBottomDropShadowForRect:(CGRect)rect inContext:(CGContextRef)context {
    // Push the context
    CGContextSaveGState(context);
    
    // Set the clipping path to remove the rect drawn by drawing the shadow
    CGRect boundingRect = CGContextGetClipBoundingBox(context);
    CGContextAddRect(context, boundingRect);
    CGContextAddRect(context, rect);
    CGContextEOClip(context);
    // Also clip the top and bottom
    CGContextClipToRect(context, CGRectMake(rect.origin.x - 10.0f, rect.origin.y, rect.size.width + 20.0f, rect.size.height + 10.0f));
    
    // Draw shadow
    [[UIColor blackColor] setFill];
    CGContextSetShadow(context, CGSizeMake(0.0f, 0.0f), 7.0f);
    CGContextFillRect(context, CGRectMake(rect.origin.x,
                                          rect.origin.y - 5.0f,
                                          rect.size.width,
                                          rect.size.height + 5.0f));
    // Save context
    CGContextRestoreGState(context);
}

#pragma mark User Following
+ (void)followUserEventually:(PFUser *)user block:(void (^)(BOOL succeeded, NSError *error))completionBlock {
    if ([[user objectId] isEqualToString:[[PFUser currentUser] objectId]]) {
        return;
    }
    
    PFObject *followActivity = [PFObject objectWithClassName:kActivityClassKey];
    [followActivity setObject:[PFUser currentUser] forKey:kActivityFromUserKey];
    [followActivity setObject:user forKey:kActivityToUserKey];
    [followActivity setObject:kActivityTypeFollow forKey:kActivityTypeKey];
    
    PFACL *followACL = [PFACL ACLWithUser:[PFUser currentUser]];
    [followACL setPublicReadAccess:YES];
    followActivity.ACL = followACL;
    
    [followActivity saveEventually:completionBlock];
}

+ (void)followUsersEventually:(NSArray *)users block:(void (^)(BOOL succeeded, NSError *error))completionBlock {
    for (PFUser *user in users) {
        [PresenticeUtility followUserEventually:user block:completionBlock];
        //[[PresenticeCache sharedCache] setFollowStatus:YES user:user];
    }
}

+ (void)unfollowUserEventually:(PFUser *)user block:(void (^)(BOOL succeeded, NSError *error))completionBlock{
    PFQuery *query = [PFQuery queryWithClassName:kActivityClassKey];
    [query whereKey:kActivityFromUserKey equalTo:[PFUser currentUser]];
    [query whereKey:kActivityToUserKey equalTo:user];
    [query whereKey:kActivityTypeKey equalTo:kActivityTypeFollow];
    [query findObjectsInBackgroundWithBlock:^(NSArray *followActivities, NSError *error1) {
        // While normally there should only be one follow activity returned, we can't guarantee that.
        if (!error1) {
            for (PFObject *followActivity in followActivities) {
                [followActivity deleteInBackgroundWithBlock:completionBlock];
            }
        }
    }];
}

+ (void)unfollowUsersEventually:(NSArray *)users {
    PFQuery *query = [PFQuery queryWithClassName:kActivityClassKey];
    [query whereKey:kActivityFromUserKey equalTo:[PFUser currentUser]];
    [query whereKey:kActivityToUserKey containedIn:users];
    [query whereKey:kActivityTypeKey equalTo:kActivityTypeFollow];
    [query findObjectsInBackgroundWithBlock:^(NSArray *activities, NSError *error) {
        for (PFObject *activity in activities) {
            [activity deleteEventually];
        }
    }];
}


+ (PFQuery*)followingFriendsOfUser:(PFUser *)aUser {
    PFQuery *followingFriendQuery = [PFQuery queryWithClassName:kActivityClassKey];
    [followingFriendQuery whereKey:kActivityTypeKey equalTo:kActivityTypeFollow];
    [followingFriendQuery whereKey:kActivityFromUserKey equalTo:aUser];
    [followingFriendQuery includeKey:kActivityToUserKey];
    [followingFriendQuery orderByDescending:kUpdatedAtKey];
    followingFriendQuery.limit = 1000;
    return followingFriendQuery;
}

+ (PFQuery*)activitiesRelatedToFriendsOfUser:(PFUser *)aUser {
    // Query all followActivities where toUser is followed by aUser
    PFQuery *followingFriendQuery = [PresenticeUtility followingFriendsOfUser:aUser];
    
    // Query all the activities where fromUser is followingFriend
    PFQuery *followingFromUserQuery = [PFQuery queryWithClassName:kActivityClassKey];
    [followingFromUserQuery whereKey:kActivityFromUserKey matchesKey:kActivityToUserKey inQuery:followingFriendQuery];
    [followingFromUserQuery whereKey:kActivityToUserKey notEqualTo:aUser];
    
    // Query all the activities where toUser is followingFriend
    PFQuery *followingToUserQuery = [PFQuery queryWithClassName:kActivityClassKey];
    [followingToUserQuery whereKey:kActivityToUserKey matchesKey:kActivityToUserKey inQuery:followingFriendQuery];
    [followingToUserQuery whereKey:kActivityFromUserKey notEqualTo:aUser];
    
    // Combine the two queries above
    PFQuery *activitiesQuery = [PFQuery orQueryWithSubqueries:[NSArray arrayWithObjects:followingToUserQuery, followingFromUserQuery, nil]];
//    activitiesQuery.limit = 1000;
    return activitiesQuery;
}

+ (PFQuery*)videosCanBeViewedByUser:(PFUser *)aUser {
    PFQuery *followingFriendQuery = [self followingFriendsOfUser:aUser];
    
    PFQuery *friendOnlyVideoQuery = [PFQuery queryWithClassName:kVideoClassKey];
    [friendOnlyVideoQuery whereKey:kVideoVisibilityKey equalTo:@"friendOnly"];
    [friendOnlyVideoQuery whereKey:kVideoUserKey matchesKey:kActivityToUserKey inQuery:followingFriendQuery];
    
    PFQuery *openVideoQuery = [PFQuery queryWithClassName:kVideoClassKey];
    [openVideoQuery whereKey:kVideoVisibilityKey containedIn:@[@"open", @"global"]];
    
    PFQuery *videosQuery = [PFQuery orQueryWithSubqueries:[NSArray arrayWithObjects:friendOnlyVideoQuery, openVideoQuery, nil]];
    videosQuery.cachePolicy = kPFCachePolicyCacheThenNetwork;
    [videosQuery orderByDescending:kUpdatedAtKey];
    
    videosQuery.limit = 1000;
    return videosQuery;
}

+ (BOOL)isUser:(PFUser *)userA followUser:(PFUser *)userB {
    PFQuery *followingFriendQuery = [PFQuery queryWithClassName:kActivityClassKey];
    [followingFriendQuery whereKey:kActivityTypeKey equalTo:kActivityTypeFollow];
    [followingFriendQuery whereKey:kActivityFromUserKey equalTo:userA];
    [followingFriendQuery whereKey:kActivityToUserKey equalTo:userB];
    if ([followingFriendQuery countObjects] > 0)
        return true;
    else
        return false;
}

+ (BOOL)canUser:(PFUser *)aUser viewVideo:(PFObject *)aVideo {
    if ([@[@"open", @"global"] containsObject:[aVideo objectForKey:kVideoVisibilityKey]]) {
        return true;
    } else if ([[aVideo objectForKey:kVideoVisibilityKey] isEqualToString:@"friendOnly"]) {
        return [self isUser:aUser followUser:[aVideo objectForKey:kVideoUserKey]];
    } else {
        return false;
    }
}

+ (NSString*)facebookProfilePictureofUser:(PFUser*)user{
    NSString* userFBID = [user objectForKey:kUserFacebookIdKey];
    return [NSString stringWithFormat:@"http://graph.facebook.com/%@/picture?type=square", userFBID];
}

+ (UIViewController *)facebookPageOfUser:(PFUser*)aUser {
    UIViewController *webViewController = [[UIViewController alloc] init];
    
    UIWebView *uiWebView = [[UIWebView alloc] initWithFrame: CGRectMake(0,0,320,568)];
    NSURL *facebooURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://www.facebook.com/%@/", [aUser objectForKey:kUserFacebookIdKey]]];
    [uiWebView loadRequest:[NSURLRequest requestWithURL:facebooURL]];
    
    [webViewController.view addSubview:uiWebView];
    
    return webViewController;
}

+ (S3TransferManager *)getS3TransferManagerForDelegate:(id)delegate withEndPoint:(AmazonRegion)endPoint andRegion:(S3Region *)region {
   // Initialize the S3 Client.
   AmazonS3Client *s3 = [[AmazonS3Client alloc] initWithAccessKey:ACCESS_KEY_ID withSecretKey:SECRET_KEY];
   s3.endpoint = [AmazonEndpoints s3Endpoint:endPoint];
   
   // Initialize the S3TransferManager
   S3TransferManager *manager = [S3TransferManager new];
   manager.s3 = s3;
   manager.delegate = delegate;
   
   // Create the bucket
   S3CreateBucketRequest *createBucketRequest = [[S3CreateBucketRequest alloc] initWithName:[Constants transferManagerBucket] andRegion:region];
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
    return manager;
}

+ (void)alertBucketCreatingError {
    UIAlertView *message = [[UIAlertView alloc] initWithTitle:CREDENTIALS_ERROR_TITLE
                                                      message:CREDENTIALS_ERROR_MESSAGE
                                                     delegate:nil
                                            cancelButtonTitle:@"OK"
                                            otherButtonTitles:nil];
    [message show];
}

#pragma Amazon implemented methods
/**
 * get the URL from S3
 * param: bucket name
 * param: Parse Video object (JSON)
 * This one is the modified one of the commented-out above
**/
+ (NSURL*)s3URLForObject:(PFObject *)object {
    // Init connection with S3Client
    AmazonS3Client *s3Client = [[AmazonS3Client alloc] initWithAccessKey:ACCESS_KEY_ID withSecretKey:SECRET_KEY];
    @try {
        // Set the content type so that the browser will treat the URL as an image.
        S3ResponseHeaderOverrides *override = [[S3ResponseHeaderOverrides alloc] init];
        override.contentType = @" ";
        // Request a pre-signed URL to picture that has been uploaded.
        S3GetPreSignedURLRequest *gpsur = [[S3GetPreSignedURLRequest alloc] init];
        // Video name
        gpsur.key = [NSString stringWithFormat:@"%@", [object objectForKey:kVideoURLKey]];
        //bucket name
        gpsur.bucket  = [Constants transferManagerBucket];
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

+ (NSURL*)s3URLWithFileName:(NSString *)filename {
    // Init connection with S3Client
    AmazonS3Client *s3Client = [[AmazonS3Client alloc] initWithAccessKey:ACCESS_KEY_ID withSecretKey:SECRET_KEY];
    @try {
        // Set the content type so that the browser will treat the URL as an image.
        S3ResponseHeaderOverrides *override = [[S3ResponseHeaderOverrides alloc] init];
        override.contentType = @" ";
        // Request a pre-signed URL to picture that has been uplaoded.
        S3GetPreSignedURLRequest *gpsur = [[S3GetPreSignedURLRequest alloc] init];
        // Video name
        gpsur.key = [NSString stringWithFormat:@"%@", filename];
        //bucket name
        gpsur.bucket  = [Constants transferManagerBucket];
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

+ (BOOL)startCameraControllerFromViewController:(UIViewController *)controller usingDelegate:(id)delegate withTimeLimit:(NSTimeInterval)timeLimit {
    // Validations
    if (([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] == NO)
        || (delegate == nil)
        || (controller == nil)) {
        return NO;
    }
    
    // Get imagePicker
    UIImagePickerController *cameraUI = [[UIImagePickerController alloc] init];
    [cameraUI setVideoMaximumDuration:timeLimit];
    
    cameraUI.sourceType = UIImagePickerControllerSourceTypeCamera;
    cameraUI.cameraDevice = UIImagePickerControllerCameraDeviceFront;
    
    // Display a controller that allows user to choose movie capture
    cameraUI.mediaTypes = [[NSArray alloc] initWithObjects:(NSString *) kUTTypeMovie, nil];
    
    // Hides the controls for moving & scaling pictures, or for trimming movies. To instead show the controls, use YES.
    cameraUI.allowsEditing = NO;
    cameraUI.delegate = delegate;
    
    // Display image picker
    [controller presentViewController:cameraUI animated:YES completion:nil];
    return YES;
}

+ (void)startImagePickerFromViewController:(UIViewController *)controller usingDelegate:(id)delegate withTimeLimit:(NSTimeInterval)timeLimit {
    
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    [picker setVideoMaximumDuration:timeLimit];
    picker.delegate = delegate;
    picker.allowsEditing = YES;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.mediaTypes = [NSArray arrayWithObject:(NSString *)kUTTypeMovie];
    
    [controller presentViewController:picker animated:YES completion:NULL];
}

+ (NSString*)stringNumberOfKey:(NSString *)key inObject:(PFObject *)object {
    if ([key isEqualToString:kVideoAnswersKey]) {
        PFRelation *relation = [object relationforKey:kVideoAnswersKey];
        PFQuery *query = relation.query;
        int count = [query countObjects];
        return [NSString stringWithFormat:@"%@: %d", NSLocalizedString([key capitalizedString], nil) , count];
    } else {
        if ([object objectForKey:key]) {
            return [NSString stringWithFormat:@"%@: %@", NSLocalizedString([key capitalizedString], nil), [object objectForKey:key]];
        } else {
            return [NSString stringWithFormat:@"%@: 0", NSLocalizedString([key capitalizedString], nil)];
        }
    }
}

+ (NSString*)visibilityOfVideo:(PFObject *)videoObj {
    NSString *visibility = [videoObj objectForKey:kVideoVisibilityKey];
    
    if ([visibility isEqualToString:@"open"])
        return NSLocalizedString(@"Open in Presentice", nil);
    else if ([visibility isEqualToString:@"friendOnly"])
        return NSLocalizedString(@"Friends can view", nil);
    else if ([visibility isEqualToString:@"onlyMe"])
        return NSLocalizedString(@"Only me can view", nil);
    else if ([visibility isEqualToString:@"global"])    // Can be viewed outside of Presentice through a link
        return NSLocalizedString(@"Globally viewable", nil);
    else
        return NSLocalizedString(@"Have not set yet", nil);
}

+ (NSString*)nameOfVideo:(PFObject *)videoObj {
    if ([[videoObj objectForKey:kVideoTypeKey] isEqualToString:@"question"])
        return [NSString stringWithFormat:NSLocalizedString(@"Question: %@", nil), [videoObj objectForKey:kVideoNameKey]];
    else
        return [NSString stringWithFormat:NSLocalizedString(@"Answer: %@", nil), [videoObj objectForKey:kVideoNameKey]];
}

+ (void)setImageView:(UIImageView *)imageView forUser:(PFUser *)user {
    //asyn to get image
    if ([user objectForKey:kUserFacebookIdKey]) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            NSData *profileImageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:[PresenticeUtility facebookProfilePictureofUser:user]]];
            dispatch_async(dispatch_get_main_queue(), ^{
                imageView.image = [UIImage imageWithData:profileImageData];
                imageView.highlightedImage = imageView.image;
                imageView.layer.cornerRadius = imageView.frame.size.width / 2;
                imageView.layer.masksToBounds = YES;
            });
        });
    } else {
        imageView.image = [UIImage imageNamed:@"ico_profile_on.png"];
    }
}


/**
 * Set side menu navigation
 **/
+ (void)navigateToMyProfileFrom:(UIViewController *)currentViewController{
    //get main storyboard
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
    
    MyProfileViewController *myProfileViewController = [storyboard instantiateViewControllerWithIdentifier:@"myProfileViewController"];
    UINavigationController *centerViewController = [[UINavigationController alloc]initWithRootViewController:myProfileViewController];
    
    [currentViewController.menuContainerViewController setCenterViewController:centerViewController];
    [currentViewController.menuContainerViewController setMenuState:MFSideMenuStateClosed];
}

+ (void)navigateToUserProfile:(PFUser *)aUser from:(UIViewController *)currentViewController {
    if (aUser == nil) {
        UIAlertView *noObjectAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"User profile not found",nil) message:NSLocalizedString(@"This user has been deleted or set to private. Please contact us at info@presentice.com for further information.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles: nil];
        [noObjectAlert show];
        [MBProgressHUD hideAllHUDsForView:currentViewController.view animated:YES];
    } else {
        //get main storyboard
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
        UserProfileViewController *destViewController = [storyboard instantiateViewControllerWithIdentifier:@"userProfileViewController"];
        destViewController.userObj = aUser;
        [currentViewController.navigationController pushViewController:destViewController animated:YES];
    }
}


+ (void)navigateToHomeScreenFrom:(UIViewController*)currentViewController {
    //get main storyboard
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
    
    MainViewController *mainViewController = [storyboard instantiateViewControllerWithIdentifier:@"mainViewController"];
    UINavigationController *mainNavigationController = [[UINavigationController alloc]initWithRootViewController:mainViewController];
    
    QuestionListViewController *questionListViewController = [storyboard instantiateViewControllerWithIdentifier:@"questionListViewController"];
    UINavigationController *questionListNavigationController = [[UINavigationController alloc]initWithRootViewController:questionListViewController];
    
    MyListViewController *myListViewController = [storyboard instantiateViewControllerWithIdentifier:@"myListViewController"];
    UINavigationController *myListNavigationController = [[UINavigationController alloc]initWithRootViewController:myListViewController];
    
    NotificationListViewController *notificationListViewController = [storyboard instantiateViewControllerWithIdentifier:@"notificationListViewController"];
    UINavigationController *notificationListNavigationController = [[UINavigationController alloc]initWithRootViewController:notificationListViewController];
    
    UITabBarController *homeTabBarController = [[UITabBarController alloc] init];
    [homeTabBarController setViewControllers:[NSArray arrayWithObjects:mainNavigationController, questionListNavigationController, myListNavigationController, notificationListNavigationController, nil]];
    [currentViewController.menuContainerViewController setCenterViewController:homeTabBarController];
    
    UINavigationController *navigationController = (UINavigationController *)homeTabBarController.selectedViewController;
    NSArray *controllers = [NSArray arrayWithObject:mainViewController];
    navigationController.viewControllers = controllers;
    
    [currentViewController.menuContainerViewController setMenuState:MFSideMenuStateClosed];
}

+ (void)navigateToMyLibraryFrom:(UIViewController *)currentViewController {
    //get main storyboard
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
    
    MainViewController *mainViewController = [storyboard instantiateViewControllerWithIdentifier:@"mainViewController"];
    UINavigationController *mainNavigationController = [[UINavigationController alloc]initWithRootViewController:mainViewController];
    
    QuestionListViewController *questionListViewController = [storyboard instantiateViewControllerWithIdentifier:@"questionListViewController"];
    UINavigationController *questionListNavigationController = [[UINavigationController alloc]initWithRootViewController:questionListViewController];
    
    MyListViewController *myListViewController = [storyboard instantiateViewControllerWithIdentifier:@"myListViewController"];
    UINavigationController *myListNavigationController = [[UINavigationController alloc]initWithRootViewController:myListViewController];
    
    NotificationListViewController *notificationListViewController = [storyboard instantiateViewControllerWithIdentifier:@"notificationListViewController"];
    UINavigationController *notificationListNavigationController = [[UINavigationController alloc]initWithRootViewController:notificationListViewController];
    
    UITabBarController *homeTabBarController = [[UITabBarController alloc] init];
    [homeTabBarController setViewControllers:[NSArray arrayWithObjects:mainNavigationController, questionListNavigationController, myListNavigationController, notificationListNavigationController, nil]];
    [currentViewController.menuContainerViewController setCenterViewController:homeTabBarController];
    
    UINavigationController *navigationController = (UINavigationController *)homeTabBarController.selectedViewController;
    NSArray *controllers = [NSArray arrayWithObject:myListViewController];
    navigationController.viewControllers = controllers;
    
    [currentViewController.menuContainerViewController setMenuState:MFSideMenuStateClosed];
}

+ (void)navigateToMessageScreenFrom:(UIViewController *)currentViewController{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
    
    MessageListViewController *messageListViewController = [storyboard instantiateViewControllerWithIdentifier:@"messageListViewController"];
    UINavigationController *messageListNavigationController = [[UINavigationController alloc]initWithRootViewController:messageListViewController];
    
    FriendListViewController *friendListViewController = [storyboard instantiateViewControllerWithIdentifier:@"friendListViewController"];
    UINavigationController *friendListNavigationController = [[UINavigationController alloc]initWithRootViewController:friendListViewController];
    
    UITabBarController *messageTabBarController = [[UITabBarController alloc] init];
    [messageTabBarController setViewControllers:[NSArray arrayWithObjects:messageListNavigationController, friendListNavigationController, nil]];
    [currentViewController.menuContainerViewController setCenterViewController:messageTabBarController];
    UINavigationController *navigationController = (UINavigationController *)messageTabBarController.selectedViewController;
    NSArray *controllers = [NSArray arrayWithObject:messageListViewController];
    navigationController.viewControllers = controllers;
    
    [currentViewController.menuContainerViewController setMenuState:MFSideMenuStateClosed];
}

+ (void)navigateToFindFriendsFrom:(UIViewController *)currentViewController{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
    
    //redirect to Find Friends View
    FindFriendViewController *findFriendViewController = [storyboard instantiateViewControllerWithIdentifier:@"findFriendViewController"];
    UINavigationController *findFriendNavigationController = [[UINavigationController alloc]initWithRootViewController:findFriendViewController];
    
    [currentViewController.menuContainerViewController setCenterViewController:findFriendNavigationController];
    [currentViewController.menuContainerViewController setMenuState:MFSideMenuStateClosed];
}

+ (void)navigateToReviewDetail:(PFObject*)aReview from:(UIViewController *)currentViewController{
    if (aReview == nil) {
        UIAlertView *noObjectAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Review not found", nil) message:NSLocalizedString(@"This review has been deleted set to private. Please ask its owner for view permission.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles: nil];
        [noObjectAlert show];
        [MBProgressHUD hideAllHUDsForView:currentViewController.view animated:YES];
    } else {
        NSDate *createdDate = aReview.createdAt;
        if (-[createdDate timeIntervalSinceNow] < [PresenticeUtility waitingTimeToView:aReview]) {
            //        NSLog(@"not yet: %f < %d", -[createdDate timeIntervalSinceNow], [PresenticeUtility waitingTimeToView:aReview]);
            NSDate *availableDate = [[NSDate alloc] initWithTimeInterval:[PresenticeUtility waitingTimeToView:aReview] sinceDate:aReview.createdAt];
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"JST"]];
            dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
            NSString *message = [NSString stringWithFormat:NSLocalizedString(@"You have to wait until:\n%@", nil), [dateFormatter stringFromDate:availableDate]];
            UIAlertView *waitingAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Can not view now", nil) message:message delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles: nil];
            [waitingAlert show];
        } else {
            //        NSLog(@"it's ok: %f > %d", -[createdDate timeIntervalSinceNow], [PresenticeUtility waitingTimeToView:aReview]);
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
            ReviewDetailViewController *destViewController = [storyboard instantiateViewControllerWithIdentifier:@"reviewDetailViewController"];
            destViewController.reviewObject = aReview;
            [currentViewController.navigationController pushViewController:destViewController animated:YES];
        }
    }
}

+ (void)navigateToVideoView:(PFObject *)aVideo from:(UIViewController *)currentViewController {
    if (aVideo == nil) {
        UIAlertView *noObjectAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Video not found", nil) message:NSLocalizedString(@"This video has been deleted set to private. Please ask its owner for view permission.", nil) delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [noObjectAlert show];
        [MBProgressHUD hideAllHUDsForView:currentViewController.view animated:YES];
    } else {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
        if ([[aVideo objectForKey:kVideoTypeKey] isEqualToString:@"answer"]) {
            VideoViewController *destViewController = [storyboard instantiateViewControllerWithIdentifier:@"videoViewController"];
            destViewController.movieURL = [PresenticeUtility s3URLForObject:aVideo];
            destViewController.answerVideoObj = aVideo;
            [currentViewController.navigationController pushViewController:destViewController animated:YES];
        } else if ([[aVideo objectForKey:kVideoTypeKey] isEqualToString:@"question"]) {
            QuestionDetailViewController *destViewController = [storyboard instantiateViewControllerWithIdentifier:@"questionDetailViewController"];
            destViewController.movieURL = [PresenticeUtility s3URLForObject:aVideo];
            destViewController.questionVideoObj = aVideo;
            [currentViewController.navigationController pushViewController:destViewController animated:YES];
        }
    }
}

+ (void)navigateToTakeReviewOfVideo:(PFObject *)aVideo from:(UIViewController *)currentViewController {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
    TakeReviewViewController *destViewController = [storyboard instantiateViewControllerWithIdentifier:@"takeReviewViewController"];
    
    destViewController.videoObj = aVideo;
    [currentViewController.navigationController pushViewController:destViewController animated:YES];
}

// Instantiate View Controller
+ (void)instantiateHomeScreenFrom:(UIViewController *)currentViewController animated:(BOOL)animated completion:(void (^)(void))completion {
    //get main storyboard
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
    
    //create side menu
    MainViewController *mainViewController = [storyboard instantiateViewControllerWithIdentifier:@"mainViewController"];
    UINavigationController *mainNavigationController = [[UINavigationController alloc]initWithRootViewController:mainViewController];
    
    QuestionListViewController *questionListViewController = [storyboard instantiateViewControllerWithIdentifier:@"questionListViewController"];
    UINavigationController *questionListNavigationController = [[UINavigationController alloc]initWithRootViewController:questionListViewController];
    
    MyListViewController *myListViewController = [storyboard instantiateViewControllerWithIdentifier:@"myListViewController"];
    UINavigationController *myListNavigationController = [[UINavigationController alloc]initWithRootViewController:myListViewController];
    
    NotificationListViewController *notificationListViewController = [storyboard instantiateViewControllerWithIdentifier:@"notificationListViewController"];
    UINavigationController *notificationListNavigationController = [[UINavigationController alloc]initWithRootViewController:notificationListViewController];
    
    UITabBarController *tabBarController = [[UITabBarController alloc] init];
    [tabBarController setViewControllers:[NSArray arrayWithObjects:mainNavigationController, questionListNavigationController, myListNavigationController, notificationListNavigationController, nil]];
    
    LeftSideMenuViewController *leftSideMenuController = [storyboard instantiateViewControllerWithIdentifier:@"leftSideMenuViewController"];
    RightSideMenuViewController *rightSideMenuController = [storyboard instantiateViewControllerWithIdentifier:@"rightSideMenuViewController"];
    
    MFSideMenuContainerViewController *container = [MFSideMenuContainerViewController
                                                    containerWithCenterViewController:tabBarController
                                                    leftMenuViewController:leftSideMenuController
                                                    rightMenuViewController:rightSideMenuController];
    
    [currentViewController.navigationController presentViewController:container animated:animated completion:completion];
}

+ (void)instantiateFindFriendsFrom:(UIViewController *)currentViewController animated:(BOOL)animated completion:(void (^)(void))completion {
    //get main storyboard
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
    
    //create side menu
    FindFriendViewController *findFriendViewController = [storyboard instantiateViewControllerWithIdentifier:@"findFriendViewController"];
    UINavigationController *findFriendNavigationController = [[UINavigationController alloc]initWithRootViewController:findFriendViewController];
    
    LeftSideMenuViewController *leftSideMenuController = [storyboard instantiateViewControllerWithIdentifier:@"leftSideMenuViewController"];
    RightSideMenuViewController *rightSideMenuController = [storyboard instantiateViewControllerWithIdentifier:@"rightSideMenuViewController"];
    MFSideMenuContainerViewController *container = [MFSideMenuContainerViewController
                                                    containerWithCenterViewController:findFriendNavigationController
                                                    leftMenuViewController:leftSideMenuController
                                                    rightMenuViewController:rightSideMenuController];
    
    [currentViewController.navigationController presentViewController:container animated:animated completion:completion];
}

+ (void)instantiateViewController:(NSString*)controllerName inWindow:(UIWindow*)window {
    //get main storyboard
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
    
    //create side menu
    MainViewController *mainViewController = [storyboard instantiateViewControllerWithIdentifier:@"mainViewController"];
    UINavigationController *mainNavigationController = [[UINavigationController alloc]initWithRootViewController:mainViewController];
    
    QuestionListViewController *questionListViewController = [storyboard instantiateViewControllerWithIdentifier:@"questionListViewController"];
    UINavigationController *questionListNavigationController = [[UINavigationController alloc]initWithRootViewController:questionListViewController];
    
    MyListViewController *myListViewController = [storyboard instantiateViewControllerWithIdentifier:@"myListViewController"];
    UINavigationController *myListNavigationController = [[UINavigationController alloc]initWithRootViewController:myListViewController];
    
    NotificationListViewController *notificationListViewController = [storyboard instantiateViewControllerWithIdentifier:@"notificationListViewController"];
    UINavigationController *notificationListNavigationController = [[UINavigationController alloc]initWithRootViewController:notificationListViewController];
    
    UITabBarController *tabBarController = [[UITabBarController alloc] init];
    [tabBarController setViewControllers:[NSArray arrayWithObjects:mainNavigationController, questionListNavigationController, myListNavigationController, notificationListNavigationController, nil]];
    if ([controllerName isEqualToString:kquestionListViewController])
        [tabBarController setSelectedIndex:1];
    else if ([controllerName isEqualToString:kmyListViewController])
        [tabBarController setSelectedIndex:2];
    else if ([controllerName isEqualToString:knotificationListViewController])
        [tabBarController setSelectedIndex:3];
    else
        [tabBarController setSelectedIndex:0];
    
    LeftSideMenuViewController *leftSideMenuController = [storyboard instantiateViewControllerWithIdentifier:@"leftSideMenuViewController"];
    RightSideMenuViewController *rightSideMenuController = [storyboard instantiateViewControllerWithIdentifier:@"rightSideMenuViewController"];
    
    MFSideMenuContainerViewController *container = [MFSideMenuContainerViewController
                                                    containerWithCenterViewController:tabBarController
                                                    leftMenuViewController:leftSideMenuController
                                                    rightMenuViewController:rightSideMenuController];
    
    window.rootViewController = container;
}

+ (void)instantiateMessageDetailWith:(PFUser*)aUser from:(UIViewController*)currentViewController animated:(BOOL)animated {
    MessageDetailViewController *destViewController = [[MessageDetailViewController alloc] init];
    
    PFQuery *messageQuery = [PFQuery queryWithClassName:kMessageClassKey];
    [messageQuery whereKey:kMessageUsersKey containsAllObjectsInArray:@[[PFUser currentUser], aUser]];
    [messageQuery includeKey:kMessageUsersKey];
    [messageQuery includeKey:kMessageFromUserKey];
    [messageQuery includeKey:kMessageToUserKey];
    
    [messageQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            if (objects.count == 0) {
                PFObject *messageObj = [PFObject objectWithClassName:kMessageClassKey];
                
                NSMutableArray *users = [[NSMutableArray alloc] initWithArray:@[[PFUser currentUser],aUser]];    // Add two users to the "users" field
                NSSortDescriptor *aSortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"objectId" ascending:YES];
                [users sortUsingDescriptors:[NSArray arrayWithObject:aSortDescriptor]];
                
                [messageObj setObject:users forKey:kMessageUsersKey];
                [messageObj setObject:[PFUser currentUser] forKey:kMessageFromUserKey];
                [messageObj setObject:aUser forKey:kMessageToUserKey];
                
                NSMutableArray *messages = [[NSMutableArray alloc] init];
                [messageObj setObject:messages forKey:kMessageContentKey];
                
                PFACL *messageACL = [PFACL ACL];
                [messageACL setReadAccess:YES forUser:[PFUser currentUser]];
                [messageACL setReadAccess:YES forUser:aUser];
                [messageACL setWriteAccess:YES forUser:[PFUser currentUser]];
                [messageACL setWriteAccess:YES forUser:aUser];
                messageObj.ACL = messageACL;
                
                destViewController.messageObj = messageObj;
            } else {
                destViewController.messageObj = [objects lastObject];
            }
            
            destViewController.toUser = aUser;
            destViewController.hidesBottomBarWhenPushed = YES;
            [currentViewController.navigationController pushViewController:destViewController animated:animated];
        } else {
            // Log details of the failure
            NSLog(@"Could not find message Error: %@ %@", error, [error userInfo]);
        }
    }];
}

+ (void)showErrorAlert:(NSError*)error{
    NSLog(@"error = %@", error);
    NSString *message = [NSString stringWithFormat:NSLocalizedString(@"Error: %@.\nPlease contact us at info@presentice.com", nil), [error localizedDescription]];
    UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                         message:message
                                                        delegate:nil
                                               cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                               otherButtonTitles: nil];
    [errorAlert show];
}

+ (NSString*)generateMyCode {
    NSString *alphabet  = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXZY0123456789";
    NSMutableString *code = [NSMutableString stringWithCapacity:20];
    for (NSUInteger i = 0; i < 6; i++) {
        u_int32_t r = arc4random() % [alphabet length];
        unichar c = [alphabet characterAtIndex:r];
        [code appendFormat:@"%C", c];
    }
    return code;
}

+ (void)updateQuestionVideo {
    // Temporary
    PFQuery *questionListQuery = [PFQuery queryWithClassName:kVideoClassKey];
    [questionListQuery includeKey:kVideoUserKey];   // Important: Include "user" key in this query make receiving user info easier
    [questionListQuery whereKey:kVideoTypeKey equalTo:@"question"];
    [questionListQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error1) {
        if (!error1) {
            for (PFObject *object in objects) {
                PFRelation *relation = [object relationforKey:kVideoAnswersKey];
                PFQuery *answerQuery = [PFQuery queryWithClassName:kVideoClassKey];
                [answerQuery whereKey:kVideoTypeKey equalTo:@"answer"];
                [answerQuery whereKey:kVideoAsAReplyTo equalTo:object];
                [answerQuery findObjectsInBackgroundWithBlock:^(NSArray *answers, NSError *error2) {
                    if (!error2) {
                        for (PFObject *answer in answers) {
                            [relation addObject:answer];
                            NSLog(@"%@ is an answer of %@", answer.objectId, object.objectId);
                        }
                    } else {
                        [PresenticeUtility showErrorAlert:error2];
                    }
                    [object saveInBackground];
                }];
            }
        } else {
            [PresenticeUtility showErrorAlert:error1];
        }
    }];
}

// Check user activation
+ (void)checkCurrentUserActivationIn:(UIViewController *)currentViewController {
    NSLog(@"check user %@", [[PFUser currentUser] objectForKey:kUserNameKey]);

    if ([[[[PFUser currentUser] objectForKey:kUserPromotionKey] fetchIfNeeded] objectForKey:kPromotionActivatedKey] == nil || [[[[[PFUser currentUser] objectForKey:kUserPromotionKey] fetchIfNeeded] objectForKey:kPromotionActivatedKey] boolValue] == false) {
        
        [PresenticeUtility callAlert:alertDidDenyAction withDelegate:nil];
        
//        [PFUser logOut];
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
        WaitingListViewController *destViewController = [storyboard instantiateViewControllerWithIdentifier:@"waitingListViewController"];
        [currentViewController.navigationController pushViewController:destViewController animated:YES];
    }
}

// Get waiting time
+ (NSInteger)waitingTimeToView:(PFObject*)anActivity {
    PFObject* content = [anActivity objectForKey:kActivityContentKey];
    return (NSInteger)[[content objectForKey:kActivityReviewWaitingTime] integerValue];
}

// Get average review of an video
+ (float)getAverageReviewOfVideo:(PFObject*)aVideo {
    PFQuery *pointQuery = [PFQuery queryWithClassName:kActivityClassKey];
    [pointQuery whereKey:kActivityTypeKey equalTo:@"review"];
    [pointQuery whereKey:kActivityTargetVideoKey equalTo:aVideo];
    pointQuery.limit = 1000;
    float sum = 0.0;
    NSArray *objects = [pointQuery findObjects];
    if (objects.count == 0)
        return 0;
    for (PFObject *object in objects) {
        NSDictionary *content = [object objectForKey:kActivityContentKey];
        NSDictionary *points = [content objectForKey:kActivityReviewCriteriaKey];
        NSArray *criteria = [[NSArray alloc] initWithArray:[points allKeys]];
        float average = 0.0;
        for (NSString *criterium in criteria)
            average += [[points objectForKey:criterium] floatValue];
        average /= criteria.count;
        sum += average;
    }
    sum /= objects.count;
    return sum;
}

// Call alertView for action
+ (void)callAlert:(NSString*)action withDelegate:(id)delegate {
    
    if ([action isEqualToString:alertSayThanks]) {
        UIAlertView *thanksAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Say thank you", nil)
                                                              message:NSLocalizedString(@"Do you want to say thank you to this person and ask more question?", nil)
                                                             delegate:delegate
                                                    cancelButtonTitle:NSLocalizedString(@"NO", nil)
                                                    otherButtonTitles:NSLocalizedString(@"YES", nil), nil];
        thanksAlert.tag = tagSayThanks;
        [thanksAlert show];
        
    } else if ([action isEqualToString:alertRateComment]) {
        UIAlertView *replyAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Rate this comment", nil)
                                                             message:NSLocalizedString(@"Do you find this comment useful for you?", nil)
                                                            delegate:delegate
                                                   cancelButtonTitle:NSLocalizedString(@"Decide later", nil)
                                                   otherButtonTitles:NSLocalizedString(@"YES", nil), NSLocalizedString(@"NO", nil), nil];
        replyAlert.tag = tagRateComment;
        [replyAlert show];
        
    } else if ([action isEqualToString:alertSignupSucceeded]) {
        UIAlertView *succeedAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Sign Up Succeeded", nil) message:NSLocalizedString(@"Congratulations! Let's find some friends who are already on Presentice", nil) delegate:delegate cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles: nil];
        succeedAlert.tag = tagSignupSucceeded;
        [succeedAlert show];
        
    } else if ([action isEqualToString:alertWillSendMessage]) {
        UIAlertView *sendMessageAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Send Private Message", nil) message:NSLocalizedString(@"Send a private message to this user?", nil) delegate:delegate cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:@"OK", nil];
        sendMessageAlert.tag = tagWillSendMessage;
        [sendMessageAlert show];
        
    } else if ([action isEqualToString:alertWillReportUser]) {
        UIAlertView *reportUserAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Report this User", nil) message:NSLocalizedString(@"Did you find this user suspicious",nil) delegate:delegate cancelButtonTitle:NSLocalizedString(@"NO", nil) otherButtonTitles:NSLocalizedString(@"YES", nil), nil];
        [reportUserAlert setAlertViewStyle:UIAlertViewStylePlainTextInput];
        [[reportUserAlert textFieldAtIndex:0] setPlaceholder:NSLocalizedString(@"Reason this person is suspicious", nil)];
        reportUserAlert.tag = tagWillReportUser;
        [reportUserAlert show];
        
    } else if ([action isEqualToString:alertWillChangePassword]) {
        UIAlertView *resetPasswordAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Change Password", nil)  message:NSLocalizedString(@"Do you want to change password?", nil) delegate:delegate cancelButtonTitle:NSLocalizedString(@"NO", nil) otherButtonTitles:NSLocalizedString(@"YES", nil), nil];
        resetPasswordAlert.tag = tagWillChangePassword;
        [resetPasswordAlert show];
        
    } else if ([action isEqualToString:alertWillInquire]) {
        UIAlertView *resetPasswordAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Inquiry", nil) message:NSLocalizedString(@"Do you have an inquiry?\nSend us an email.", nil) delegate:delegate cancelButtonTitle:NSLocalizedString(@"NO", nil) otherButtonTitles:NSLocalizedString(@"YES", nil), nil];
        resetPasswordAlert.tag = tagWillInquire;
        [resetPasswordAlert show];
        
    } else if ([action isEqualToString:alertWillPostQuestion]) {
        UIAlertView *postAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Post a new challenge", nil)
                                                            message:NSLocalizedString(@"Please choose a short title (less than 10 words) then select how to post video from the following options.", nil)
                                                           delegate:delegate
                                                  cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                                  otherButtonTitles:NSLocalizedString(@"Upload from Library", nil), NSLocalizedString(@"Record from Camera", nil), nil];
        postAlert.tag = tagWillPostQuestion;      // Set alert tag is important in case of existence of many alerts
        [postAlert setAlertViewStyle:UIAlertViewStylePlainTextInput];
        [[postAlert textFieldAtIndex:0] setPlaceholder:NSLocalizedString(@"Video Name", nil)];
        [postAlert show];
        
    } else if ([action isEqualToString:alertWillSuggestQuestion]) {
        UIAlertView *suggestAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Suggest new challenge", nil)
                                                               message:NSLocalizedString(@"Suggest a challenge and we will consider making it.", nil)
                                                              delegate:delegate
                                                     cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                                     otherButtonTitles:NSLocalizedString(@"Send", nil), nil];
        suggestAlert.tag = tagWillSuggestQuestion;
        [suggestAlert setAlertViewStyle:UIAlertViewStylePlainTextInput];
        [[suggestAlert textFieldAtIndex:0] setPlaceholder:NSLocalizedString(@"Details", nil)];
        [suggestAlert show];
        
    } else if ([action isEqualToString:alertDidSaveVideo]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Video Saved", nil)
                                                        message:NSLocalizedString(@"Saved To Photo Album! Upload Answer to Server?", nil)
                                                       delegate:delegate
                                              cancelButtonTitle:NSLocalizedString(@"NO", nil)
                                              otherButtonTitles:NSLocalizedString(@"YES", nil), nil];
        alert.tag = tagDidSaveVideo;      // Set alert tag is important in case of existence of many alerts
        [alert show];
        
    } else if ([action isEqualToString:alertWillAddNote]) {
        UIAlertView *addNoteAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Success", nil)
                                                               message:NSLocalizedString(@"Your video has been uploaded to Presentice successfully. Do you want to add a note for those who will view this video?", nil)
                                                              delegate:delegate
                                                     cancelButtonTitle:NSLocalizedString(@"NO", nil)
                                                     otherButtonTitles:NSLocalizedString(@"YES", nil) , nil];
        addNoteAlert.tag = tagWillAddNote;
        [addNoteAlert show];
        
    } else if ([action isEqualToString:alertSelectVisibility]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Visibility Selection", nil)
                                                        message:NSLocalizedString(@"Decide who can view this video.\n※You can change it later.", nil)
                                                       delegate:delegate
                                              cancelButtonTitle:NSLocalizedString(@"Open inside Presentice", nil)
                                              otherButtonTitles:NSLocalizedString(@"Only friends who are following me", nil), NSLocalizedString(@"Only Me", nil), nil];
        alert.tag = tagSelectVisibility;
        [alert show];
        
    } else if ([action isEqualToString:alertWillDisplayNote]) {
        UIAlertView *noteDisplayAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Fully display note", nil)
                                                                   message:NSLocalizedString(@"Do you want to view this note fully", nil)
                                                                  delegate:delegate
                                                         cancelButtonTitle:NSLocalizedString(@"NO", nil)
                                                         otherButtonTitles:NSLocalizedString(@"YES", nil) , nil];
        noteDisplayAlert.tag = tagWillDisplayNote;
        [noteDisplayAlert show];
        
    } else if ([action isEqualToString:alertWillTakeAnswer]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Name your answer", nil)
                                                        message:NSLocalizedString(@"Please choose a short title (less than 10 words) then select how to post video from the following options.", nil)
                                                       delegate:delegate
                                              cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                              otherButtonTitles:NSLocalizedString(@"Upload from Library", nil), NSLocalizedString(@"Record from Camera", nil), nil];
        alert.tag = tagWillTakeAnswer;      // Set alert tag is important in case of existence of many alerts
        [alert setAlertViewStyle:UIAlertViewStylePlainTextInput];
        [[alert textFieldAtIndex:0] setPlaceholder:NSLocalizedString(@"Video Name", nil)];
        [alert show];
        
    } else if ([action isEqualToString:alertWillDisplayQuestionVideo]) {
        UIAlertView *noteDisplayAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"View question video", nil)
                                                                   message:NSLocalizedString(@"Do you want to view the question video which this video answered for?", nil)
                                                                  delegate:delegate
                                                         cancelButtonTitle:NSLocalizedString(@"NO", nil)
                                                         otherButtonTitles:NSLocalizedString(@"YES", nil), nil];
        noteDisplayAlert.tag = tagWillDisplayQuestionVideo;
        [noteDisplayAlert show];
        
    } else if ([action isEqualToString:alertChangeVideoName]) {
        UIAlertView *titleEditAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Edit video name", nil)
                                                                 message:NSLocalizedString(@"Choose a new name for this video", nil)
                                                                delegate:delegate
                                                       cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                                       otherButtonTitles:NSLocalizedString(@"Change it", nil), nil];
        titleEditAlert.tag = tagChangeVideoName;
        [titleEditAlert setAlertViewStyle:UIAlertViewStylePlainTextInput];
        [[titleEditAlert textFieldAtIndex:0] setPlaceholder:NSLocalizedString(@"New video name", nil)];
        [titleEditAlert show];
        
    } else if ([action isEqualToString:alertWillDeleteVideo]) {
        UIAlertView *deleteAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Delete video", nil)
                                                              message:NSLocalizedString(@"Are you sure you want to delete this video. This action can not be undone.", nil)
                                                             delegate:delegate
                                                    cancelButtonTitle:NSLocalizedString(@"NO", nil)
                                                    otherButtonTitles:NSLocalizedString(@"YES", nil), nil];
        deleteAlert.tag = tagWillDeleteVideo;
        [deleteAlert show];
        
    } else if ([action isEqualToString:alertWillEditVideo]) {
        UIAlertView *editAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Edit Video Information", nil)
                                                            message:NSLocalizedString(@"What do you want to do?", nil)
                                                           delegate:delegate
                                                  cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                                  otherButtonTitles:NSLocalizedString(@"Video Name", nil), NSLocalizedString(@"Note for viewer", nil), NSLocalizedString(@"Visibility status", nil), NSLocalizedString(@"Delete", nil) ,nil];
        editAlert.tag = tagWillEditVideo;
        [editAlert show];
        
    } else if ([action isEqualToString:alertWillSaveNote]) {
        UIAlertView *saveAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Save Changes", nil)
                                                            message:NSLocalizedString(@"Do you want to save this note?", nil)
                                                           delegate:delegate
                                                  cancelButtonTitle:NSLocalizedString(@"NO", nil)
                                                  otherButtonTitles:NSLocalizedString(@"YES", nil), nil];
        saveAlert.tag = tagWillSaveNote;
        [saveAlert show];
        
    } else if ([action isEqualToString:alertWillBackToVideoView]) {
        UIAlertView *successAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Success", nil)
                                                               message:NSLocalizedString(@"Note saved successfully? Back to Video View?", nil)
                                                              delegate:delegate
                                                     cancelButtonTitle:NSLocalizedString(@"NO", nil)
                                                     otherButtonTitles:NSLocalizedString(@"YES", nil), nil];
        successAlert.tag = tagWillBackToVideoView;
        [successAlert show];
        
    } else if ([action isEqualToString:alertDidDenyAction]) {
        UIAlertView *activatedAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Access denied", nil)
                                                                 message:NSLocalizedString(@"Your account has not been activated yet. If you have waited for more than a week, please contact us at\ninfo@presentice.com", nil)
                                                                delegate:delegate
                                                       cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                       otherButtonTitles:nil];
        activatedAlert.tag = tagDidDenyAction;
        [activatedAlert show];
        
    } else if ([action isEqualToString:alertLetsAnswer]) {
        UIAlertView *letsAnswerAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Answer this question", nil)
                                                                  message:NSLocalizedString(@"Why not give it a try on this one?", nil)
                                                                 delegate:delegate
                                                        cancelButtonTitle:NSLocalizedString(@"Later", nil)
                                                        otherButtonTitles:NSLocalizedString(@"Yeah, go ahead", nil), nil];
        letsAnswerAlert.tag = tagLetsAnswer;
        [letsAnswerAlert show];
        
    } else if ([action isEqualToString:alertLetsReview]) {
        UIAlertView *letsReviewAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Review this answer", nil)
                                                                  message:NSLocalizedString(@"Let's give it a review. It only takes 10 seconds.", nil)
                                                                 delegate:delegate
                                                        cancelButtonTitle:NSLocalizedString(@"Later", nil)
                                                        otherButtonTitles:NSLocalizedString(@"Yeah, go ahead", nil), nil];
        letsReviewAlert.tag = tagLetsReview;
        [letsReviewAlert show];
    }
}

// Login via Facebook
+ (void)loginViaFacebookIn:(UIViewController *)currentViewController {
    // Set permissions required from the facebook user account
    NSArray *permissionsArray = @[ @"user_about_me", @"user_relationships", @"user_birthday", @"user_location"];
    
    //start loading hub
    [MBProgressHUD showHUDAddedTo:currentViewController.view animated:YES];
    
    // Login PFUser using facebook
    [PFFacebookUtils logInWithPermissions:permissionsArray block:^(PFUser *user, NSError *error) {
        if (!user) {
            if (!error) {
                NSLog(@"Uh oh. The user cancelled the Facebook login.");
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Login error",nil)
                                                                message:NSLocalizedString(@"You have just cancelled the Facebook register.",nil)
                                                               delegate:nil
                                                      cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                                      otherButtonTitles:nil];
                [alert show];
            } else {
                [PresenticeUtility showErrorAlert:error];
            }
        } else {
            // check if user already registered with facebook
            [FBRequestConnection startForMeWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                if(!error){
                    //get email from facebook
                    NSDictionary<FBGraphUser> *me = (NSDictionary<FBGraphUser> *)result;
                    NSLog(@"%@", me);
                    NSString *email = [me objectForKey:@"email"];
                    NSString *facebookId = [me objectForKey:@"id"];
                    //query User with email
                    PFQuery *queryUser = [PFUser query];
                    
                    if(email != nil && ![email isEqual:@""]){
                        [queryUser whereKey:kUserNameKey equalTo:email];
                    } else {
                        [queryUser whereKey:kUserFacebookIdKey equalTo:facebookId];
                    }
                    [queryUser findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                        //if email/facebookId already registered, redirect to main view
                        if (!error && [objects count] != 0) {
                            //redirect using storyboard
                            //if user already login, redirect to MainViewController
                            if([PFUser currentUser] && [PFFacebookUtils isLinkedWithUser:[PFUser currentUser]])
                                [PresenticeUtility instantiateHomeScreenFrom:currentViewController animated:NO completion:nil];
                            
                        } else {
                            //redirecto to register screen using storyboard
                            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
                            RegisterViewController *destViewController = (RegisterViewController *)[storyboard instantiateViewControllerWithIdentifier:@"RegisterViewController"];
                            [currentViewController.navigationController pushViewController:destViewController animated:YES];
                        }
                        
                        // subscribe user default channel for notification.
                        PFInstallation *currentInstallation = [PFInstallation currentInstallation];
                        [currentInstallation addUniqueObject:[NSString stringWithFormat:@"user_%@",[user objectId]] forKey:@"channels"];
                        [currentInstallation saveInBackground];
                        
                        NSLog(@"currentInstallation: %@", currentInstallation);
                        
                        // dismiss hub
                        [MBProgressHUD hideHUDForView:currentViewController.view animated:YES];
                    }];
                    
                }
            }];
        }
    }];
}


@end





