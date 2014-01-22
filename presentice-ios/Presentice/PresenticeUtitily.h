//
//  PresenticeUtitily.h
//  Presentice
//
//  Created by レー フックダイ on 1/9/14.
//  Copyright (c) 2014 Presentice. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>
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



// Show facebook
+ (NSString*)facebookProfilePictureofUser:(PFUser*)user;
+ (UIViewController *)facebookPageOfUser:(PFUser*)aUser;

@end
