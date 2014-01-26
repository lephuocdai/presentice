//
//  TakeReviewViewController.h
//  Presentice
//
//  Created by PhuongNQ on 12/29/13.
//  Copyright (c) 2013 Presentice. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <Parse/Parse.h>
#import "MBProgressHUD.h"
#import "quickdialog/QuickDialog.h"
#import "QPickerElement.h"

#import "Constants.h"


@interface TakeReviewViewController : QuickDialogController <QuickDialogEntryElementDelegate> {
    
}

@property (weak, nonatomic) PFObject *videoObj;
@property BOOL didReview;

@end
