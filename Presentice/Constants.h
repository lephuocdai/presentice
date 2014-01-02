/*
 * Copyright 2010-2013 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License").
 * You may not use this file except in compliance with the License.
 * A copy of the License is located at
 *
 *  http://aws.amazon.com/apache2.0
 *
 * or in the "license" file accompanying this file. This file is distributed
 * on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
 * express or implied. See the License for the specific language governing
 * permissions and limitations under the License.
 */

#import <Foundation/Foundation.h>

// Constants used to represent your AWS Credentials.
//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// This sample App is for demonstration purposes only.
// It is not secure to embed your credentials into source code.
// Please read the following article for getting credentials
// to devices securely.
// http://aws.amazon.com/articles/Mobile/4611615499399490
//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#define ACCESS_KEY_ID          @"AKIAIBF67U5IMHUB2KDQ"
#define SECRET_KEY             @"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"


// Constants for the Bucket
#define S3TRANSFERMANAGER_BUCKET         @"s3-transfer-manager-bucket"


#define CREDENTIALS_ERROR_TITLE    @"Missing Credentials"
#define CREDENTIALS_ERROR_MESSAGE  @"AWS Credentials not configured correctly.  Please review the README file."

#define kRequestTagForSmallFile         @"tag-tm-small-file-0"
#define kRequestTagForBigFile           @"tag-tm-big-file-0"
#define kKeyForBigFile                  @"tm-large-file-0"
#define kKeyForSmallFile                @"Question6-Engineer Recent Web Service.mp4"

#define kSmallFileSize 1024*1024*4.8 //4.8 megs
#define kBigFileSize 1024*1024*10  //10 megs

#pragma constants of Parse Table

#define kObjectIdKey @"objectId"
#define kCreatedAtKey @"createdAt"
#define kUpdatedAtKey @"updatedAt"
#define kACLKey @"ACL"

#pragma Table User
#define kUserClassKey @"User"
#define kUserNameKey @"username"
#define kUserPasswordKey @"password"
#define kUserAuthDataKey @"authData"
#define kUserEmailKey @"email"
#define kUserEmailVerifiedKey @"emailVerified"
#define kUserTypeKey @"type"
#define kUserActivatedKey @"activated"
#define kUserDisplayNameKey @"displayName"
#define kUserFacebookIdKey @"facebookId"
#define kUserProfileKey @"profile"

#pragma Table Video
#define kVideoClassKey @"Video"
#define kVideoURLKey @"videoURL"
#define kVideoThumbnailURLKey @"thumbnailURL"
#define kVideoTypeKey @"type"
#define kVideoNameKey @"videoName"
#define kVideoUserKey @"user"   // Pointer to the user that posted this video
#define kVideoAsAReplyTo @"asAReplyTo"  // Pointer to the questionVideo that this answerVideo is replying to
#define kVideoReviewsKey @"reviews"

#pragma Table Activity
#define kActivityFromUserKey @"fromUser"
#define kActivityToUserKey @"toUser"    //
#define kActivityTypeKey @"type"    // Ex: "view", "review", "comment"
#define kActivityContentKey @"content"  // The detail content if available
#define kActivityVideoKey @"video"  // Pointer to the video that this activity was taken on

#define kReviewClassKey @"Review"
#define kReviewFromUserKey @"fromUser"
#define kReviewToUserKey @"toUser"
#define kReviewTargetVideoKey @"targetVideo"
#define kReviewContentKey @"content"
#define kReviewCommentKey @"comment"

#define REVIEW_MAX_VALUE 5
#define REVIEW_MIN_VALUE 1


@interface Constants : NSObject

/*
 * Creating bucket
 */
+ (NSString *)transferManagerBucket;

@end
