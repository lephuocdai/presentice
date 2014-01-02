//
//  ReviewViewController.h
//  Presentice
//
//  Created by PhuongNQ on 12/29/13.
//  Copyright (c) 2013 Presentice. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <Parse/Parse.h>
#import "MBProgressHUD.h"

#import "Constants.h"


@interface ReviewViewController : UIViewController 
@property (weak, nonatomic) IBOutlet UISlider *organizationPoint;
@property (weak, nonatomic) IBOutlet UISlider *understandPoint;
@property (weak, nonatomic) IBOutlet UISlider *appearancePoint;
@property (weak, nonatomic) IBOutlet UITextView *commentTextView;
@property (weak, nonatomic) IBOutlet UILabel *organizationLabel;
@property (weak, nonatomic) IBOutlet UILabel *understandLabel;

@property (weak, nonatomic) IBOutlet UILabel *appearanceLabel;

@property (weak, nonatomic) PFObject *videoObj;
- (IBAction)didPressSendButton:(id)sender;
@end
