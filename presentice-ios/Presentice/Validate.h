//
//  Validate.h
//  Presentice
//
//  Created by PhuongNQ on 12/29/13.
//  Copyright (c) 2013 Presentice. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Validate : NSObject
+ (BOOL) NSStringIsValidEmail:(NSString *)checkString;
+ (BOOL) NSSTringISValidPassword:(NSString *)checkString;
@end
