//
//  RegisterInfo.h
//  Presentice
//
//  Created by レー フックダイ on 1/23/14.
//  Copyright (c) 2014 Presentice. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RegisterInfo : NSObject {

@private
    NSString *_email;
    NSString *_password;
    NSString *_passowrdConfirm;
    NSString *_code;
    NSString *_school;
    NSString *_country;
}

@property(strong) NSString *email;
@property(strong) NSString *password;
@property(strong) NSString *passwordConfirm;
@property(strong) NSString *code;
@property(strong) NSString *school;
@property(strong) NSString *country;

@end
