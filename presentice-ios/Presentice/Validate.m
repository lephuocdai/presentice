//
//  Validate.m
//  Presentice
//
//  Created by PhuongNQ on 12/29/13.
//  Copyright (c) 2013 Presentice. All rights reserved.
//

#import "Validate.h"

@implementation Validate

+ (BOOL) NSStringIsValidEmail:(NSString *)checkString
{
    BOOL stricterFilter = YES;
    NSString *stricterFilterString = @"[A-Z0-9a-z\\._%+-]+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2,4}";
    NSString *laxString = @".+@([A-Za-z0-9]+\\.)+[A-Za-z]{2}[A-Za-z]*";
    NSString *emailRegex = stricterFilter ? stricterFilterString : laxString;
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:checkString];
}
+ (BOOL) NSSTringISValidPassword:(NSString *)checkString {
    return [checkString length] >= 6;
}
@end
