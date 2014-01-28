//
//  PresenticeUtitily.h
//  Presentice
//
//  Created by レー フックダイ on 1/9/14.
//  Copyright (c) 2014 Presentice. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>
#import <AWSRuntime/AWSRuntime.h>
#import <AWSS3/AWSS3.h>
#import <MobileCoreServices/MobileCoreServices.h>

#import "Constants.h"
#import "PresenticeCache.h"

@interface PresenticeUtitily : NSObject

+ (void)drawSideAndBottomDropShadowForRect:(CGRect)rect inContext:(CGContextRef)context;
+ (void)followUserEventually:(PFUser *)user block:(void (^)(BOOL succeeded, NSError *error))completionBlock;
+ (void)followUsersEventually:(NSArray *)users block:(void (^)(BOOL succeeded, NSError *error))completionBlock;
+ (void)unfollowUserEventually:(PFUser *)user;
+ (void)unfollowUsersEventually:(NSArray *)users;


// Query all users that a user is following
+ (PFQuery *)followingFriendsOfUser:(PFUser*)aUser;

// Query all videos that a user can view
+ (PFQuery *)videosCanBeViewedByUser:(PFUser*)aUser;

// Check following
+ (BOOL)isUser:(PFUser*)userA followUser:(PFUser*)userB;
+ (BOOL)canUser:(PFUser*)aUser viewVideo:(PFObject*)aVideo;
//+ (BOOL)canUser:(PFUser*)aUser viewActivity:(PFObject*)anActivity;

// Show facebook
+ (NSString*)facebookProfilePictureofUser:(PFUser*)user;
+ (UIViewController *)facebookPageOfUser:(PFUser*)aUser;

// Initiate S3TransferManager bucket
+ (S3TransferManager *)getS3TransferManagerForDelegate:(id)delegate withEndPoint:(AmazonRegion)endPoint andRegion:(S3Region *)region;
+ (void)alertBucketCreatingError;

// S3URL of a video object
+ (NSURL*)s3URLForObject:(PFObject*)object;

+ (NSURL*)s3URLWithFileName:(NSString*)filename;

// Start recording from camera
+ (BOOL)startCameraControllerFromViewController:(UIViewController *)controller usingDelegate:(id)delegate withTimeLimit:(NSTimeInterval)timeLimit;

+ (void)startImagePickerFromViewController:(UIViewController *)controller usingDelegate:(id)delegate withTimeLimit:(NSTimeInterval)timeLimit;

// Video information
+ (NSString *)stringNumberOfKey:(NSString*)key inObject:(PFObject*)object;
+ (void)setImageView:(UIImageView*)imageView forUser:(PFUser*)user;


@end
