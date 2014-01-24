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

#import "Constants.h"

@implementation Constants

+ (NSString *)transferManagerBucket {
    return [[NSString stringWithFormat:@"%@-%@", S3TRANSFERMANAGER_BUCKET, ACCESS_KEY_ID] lowercaseString];
}

//+ (NSString *)transferManagerBucket {
//    return @"presentice";
//}

+ (NSString *)getConstantbyClass:(NSString *)className forType:(NSString *)typeName withName:(NSString *)name {
    PFQuery *query = [PFQuery queryWithClassName:@"Constant"];
    [query whereKey:@"class" equalTo:className];
    [query whereKey:@"type" equalTo:typeName];
    PFObject *object = [query getFirstObject];
    
    NSArray *contents = [[NSArray alloc] initWithArray:[object objectForKey:@"content"]];
    NSPredicate *filter = [NSPredicate predicateWithFormat:@"name = %@", name];
    return [[[contents filteredArrayUsingPredicate:filter] firstObject] objectForKey:@"content"];
}

//+ (NSString*)facebookProfilePictureofUser:(PFUser*)user{
//    NSString* userFBID = [user objectForKey:kUserFacebookIdKey];
//    return [NSString stringWithFormat:@"http://graph.facebook.com/%@/picture?type=square", userFBID];
//}

@end
