//
//  PresenticeCache.h
//  Presentice
//
//  Created by PhuongNQ on 1/18/14.
//  Copyright (c) 2014 Presentice. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Constants.h"

@interface PresenticeCache : NSObject
+ (id)sharedCache;
- (void)setFacebookFriends:(NSArray *)friends;
- (NSArray *)facebookFriends;

- (BOOL)followStatusForUser:(PFUser *)user;
- (void)setFollowStatus:(BOOL)following user:(PFUser *)user;

- (NSDictionary *)attributesForUser:(PFUser *)user;
@end
