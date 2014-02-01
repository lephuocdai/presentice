//
//  TakeReviewViewController.h
//  Presentice
//
//  Created by PhuongNQ on 12/29/13.
//  Copyright (c) 2013 Presentice. All rights reserved.
//

#import "PresenticeUtility.h"

#import "quickdialog/QuickDialog.h"
#import "QPickerElement.h"


@interface TakeReviewViewController : QuickDialogController <QuickDialogEntryElementDelegate> {
    
}
@property (weak, nonatomic) PFObject *videoObj;
@property BOOL didReview;

@end
