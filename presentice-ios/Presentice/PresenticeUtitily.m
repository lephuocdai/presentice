//
//  PresenticeUtitily.m
//  Presentice
//
//  Created by レー フックダイ on 1/9/14.
//  Copyright (c) 2014 Presentice. All rights reserved.
//

#import "PresenticeUtitily.h"

@implementation PresenticeUtitily

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
        [PresenticeUtitily followUserEventually:user block:completionBlock];
        //[[PresenticeCache sharedCache] setFollowStatus:YES user:user];
    }
}

+ (void)unfollowUserEventually:(PFUser *)user {
    PFQuery *query = [PFQuery queryWithClassName:kActivityClassKey];
    [query whereKey:kActivityFromUserKey equalTo:[PFUser currentUser]];
    [query whereKey:kActivityToUserKey equalTo:user];
    [query whereKey:kActivityTypeKey equalTo:kActivityTypeFollow];
    [query findObjectsInBackgroundWithBlock:^(NSArray *followActivities, NSError *error) {
        // While normally there should only be one follow activity returned, we can't guarantee that.
        if (!error) {
            for (PFObject *followActivity in followActivities) {
                [followActivity deleteEventually];
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
    followingFriendQuery.cachePolicy = kPFCachePolicyCacheThenNetwork;
    followingFriendQuery.limit = 1000;
    return followingFriendQuery;
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
    if ([object objectForKey:key]) {
        return [NSString stringWithFormat:@"%@: %@", key, [object objectForKey:key]];
    } else {
        return [NSString stringWithFormat:@"%@: 0", key];
    }
}

+ (void)setImageView:(UIImageView *)imageView forUser:(PFUser *)user {
    //asyn to get image
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSData *profileImageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:[PresenticeUtitily facebookProfilePictureofUser:user]]];
        dispatch_async(dispatch_get_main_queue(), ^{
            imageView.image = [UIImage imageWithData:profileImageData];
            imageView.highlightedImage = imageView.image;
            imageView.layer.cornerRadius = imageView.frame.size.width / 2;
            imageView.layer.masksToBounds = YES;
        });
    });
}


@end
