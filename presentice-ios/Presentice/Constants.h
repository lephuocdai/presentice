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
#import <Parse/Parse.h>
#import "Credentials.h"

// Constants for the Bucket
#define S3TRANSFERMANAGER_BUCKET         @"s3-transfer-manager-bucket"
#define CREDENTIALS_ERROR_TITLE    @"Missing Credentials"
#define CREDENTIALS_ERROR_MESSAGE  @"AWS Credentials not configured correctly.  Please review the README file."

//Constants for PresenticeCache
#define kUserDefaultsCacheFacebookFriendsKey            @"com.presentice.userDefaults.cache.facebookFriends"
#define kUserAttributesIsFollowedByCurrentUserKey    @"isFollowedByCurrentUser"

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
#define kUserPushPermission @"pushPermission"
#define kUserCanPostQuestion @"canPostQuestion"
#define kUserCanComment @"canComment"
#define kUserMyCode @"myCode"
#define kUserReceiveCode @"receiveCode"
#define kUserPromotionKey @"promotion"

#pragma Table Video
#define kVideoClassKey @"Video"
#define kVideoURLKey @"videoURL"
#define kVideoThumbnailURLKey @"thumbnailURL"
#define kVideoTypeKey @"type"
#define kVideoNameKey @"videoName"
#define kVideoUserKey @"user"   // Pointer to the user that posted this video
#define kVideoAsAReplyTo @"asAReplyTo"  // Pointer to the questionVideo that this answerVideo is replying to
#define kVideoToUserKey @"toUser"
#define kVideoReviewsKey @"reviews"
#define kVideoViewsKey @"views"
#define kVideoAnswersKey @"answers"
#define kVideoVisibilityKey @"visibility"
#define kVideoNoteKey @"note"

#pragma Table Activity
#define kActivityClassKey @"Activity"
#define kActivityFromUserKey @"fromUser"
#define kActivityToUserKey @"toUser"    //
#define kActivityTypeKey @"type"    // Ex: "view", "review", "comment"
#define kActivityDescriptionKey @"description" // The description of the activity if available
#define kActivityContentKey @"content"  // The detail content if available
#define kActivityTargetVideoKey @"targetVideo"  // Pointer to the video that this activity was taken on
#define kActivityTypeFollow @"follow"   //type = follow
#define kActivityReviewCriteriaKey @"criteria"
#define kActivityReviewWaitingTime @"waitingTime"
#define kActivityReviewRateComment @"rateComment"
#define kActivityReviewRateCommentSatisfied @"satisfied"
#define kActivityReviewRateCommentUnsatisfied @"unsatisfied"


#pragma Table Message
#define kMessageClassKey @"Message"
#define kMessageUsersKey @"users"
#define kMessageFromUserKey @"fromUser"
#define kMessageToUserKey @"toUser"
#define kMessageContentKey @"content"

#pragma Table Promotion
#define kPromotionClassKey @"Promotion"
#define kPromotionUserKey @"user"
#define kPromotionPointsKey @"points"
#define kPromotionLevelKey @"level"
#define kPromotionMyCodeKey @"myCode"
#define kPromotionReceiveCodeKey @"receiveCode"
#define kPromotionContributionKey @"contribution"

#pragma View Controller
#define kmainViewController @"mainViewController"
#define kquestionListViewController @"questionListViewController"
#define kmyListViewController @"myListViewController"
#define knotificationListViewController @"notificationListViewController"



#pragma Alert View
#define alertSayThanks @"sayThanks"
#define tagSayThanks 1

#define alertRateComment @"rateComment"
#define tagRateComment 2

#define alertSignupSucceeded @"signupSucceeded"
#define tagSignupSucceeded 3

#define alertWillSendMessage @"willSendMessage"
#define tagWillSendMessage 4

#define alertWillReportUser @"willReportUser"
#define tagWillReportUser 5

#define alertWillChangePassword @"willChangePassword"
#define tagWillChangePassword 6

#define alertWillInquire @"willInquire"
#define tagWillInquire 7

#define alertWillPostQuestion @"willPostQuestion"
#define tagWillPostQuestion 8

#define alertWillSuggestQuestion @"willSuggestQuestion"
#define tagWillSuggestQuestion 9

#define alertDidSaveVideo @"didSaveVideo"
#define tagDidSaveVideo 10

#define alertWillAddNote @"willAddNote"
#define tagWillAddNote 11

#define alertSelectVisibility @"selectVisibility"
#define tagSelectVisibility 12

#define alertWillDisplayNote @"willDisplayNote"
#define tagWillDisplayNote 13

#define alertWillTakeAnswer @"willTakeAnswer"
#define tagWillTakeAnswer 14

#define alertWillDisplayQuestionVideo @"willDisplayQuestionVideo"
#define tagWillDisplayQuestionVideo 15

#define alertChangeVideoName @"changetVideoName"
#define tagChangeVideoName 16

#define alertWillDeleteVideo @"willDeleteVideo"
#define tagWillDeleteVideo 17

#define alertWillEditVideo @"willEditVideo"
#define tagWillEditVideo 18

#define alertWillSaveNote @"willSaveNote"
#define tagWillSaveNote 19

#define alertWillBackToVideoView @"willBackToVideoView"
#define tagWillBackToVideoView 20





#define REVIEW_MAX_VALUE 5
#define REVIEW_MIN_VALUE 1

#define VIDEO_TIME_LIMIT 120.0f     // 2 minutes

#define VIEW_REVIEW_WAITNG_TIME 3600           // Wait at least 1 hour = 3600 seconds

@interface Constants : NSObject

/*
 * Creating bucket
 */
+ (NSString *)transferManagerBucket;

+ (NSString *)getConstantbyClass:(NSString *)className forType:(NSString *)typeName withName:(NSString *)name;

//+ (NSString*)facebookProfilePictureofUser:(PFUser*)user;

@end
