//
//  MessageFooterView.h
//  Presentice
//
//  Created by レー フックダイ on 1/9/14.
//  Copyright (c) 2014 Presentice. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PresenticeUtility.h"

@interface MessageFooterView : UIView

@property (nonatomic, strong) UITextField *commentField;
@property (nonatomic) BOOL hideDropShadow;

+ (CGRect)rectForView;

@end
