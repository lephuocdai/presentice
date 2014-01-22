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
    
    UIWebView *uiWebView = [[UIWebView alloc] initWithFrame: CGRectMake(0,0,320,480)];
    NSURL *facebooURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://www.facebook.com/%@/", [aUser objectForKey:kUserFacebookIdKey]]];
    [uiWebView loadRequest:[NSURLRequest requestWithURL:facebooURL]];
    
    [webViewController.view addSubview:uiWebView];
    
    return webViewController;
}

@end
