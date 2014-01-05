//
//  ReviewViewController.m
//  Presentice
//
//  Created by PhuongNQ on 12/29/13.
//  Copyright (c) 2013 Presentice. All rights reserved.
//

#import "ReviewViewController.h"

PFObject *reviewObj;

@interface ReviewViewController ()

@end

@implementation ReviewViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	[self initDesign];
    [self initSlider];
    [self queryCurrentReview];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) initDesign {
    self.commentTextView.layer.borderWidth = 0.5f;
    self.commentTextView.layer.borderColor = [[UIColor grayColor] CGColor];
}
- (void) initSlider {
    self.organizationPoint.minimumValue = REVIEW_MIN_VALUE;
    self.organizationPoint.maximumValue = REVIEW_MAX_VALUE;
    self.organizationPoint.continuous = YES;
    [self.organizationPoint addTarget:self action:@selector(sliderChanged:)
       forControlEvents:UIControlEventValueChanged];
    
    self.understandPoint.minimumValue = REVIEW_MIN_VALUE;
    self.understandPoint.maximumValue = REVIEW_MAX_VALUE;
    self.understandPoint.continuous = YES;
    [self.understandPoint addTarget:self action:@selector(sliderChanged:)
                     forControlEvents:UIControlEventValueChanged];
    
    self.appearancePoint.minimumValue = REVIEW_MIN_VALUE;
    self.appearancePoint.maximumValue = REVIEW_MAX_VALUE;
    self.appearancePoint.continuous = YES;
    [self.appearancePoint addTarget:self action:@selector(sliderChanged:)
                   forControlEvents:UIControlEventValueChanged];
}
- (void) sliderChanged:(id)sender {
    self.organizationLabel.text = [NSString stringWithFormat:@"%d",(int)self.organizationPoint.value];
    self.understandLabel.text = [NSString stringWithFormat:@"%d", (int)self.understandPoint.value];
    self.appearanceLabel.text = [NSString stringWithFormat:@"%d", (int)self.appearancePoint.value];
}
/**
 * end of editing
 * dissmis input keyboard
 **/
- (void)touchesEnded: (NSSet *)touches withEvent: (UIEvent *)event {
	for (UIView* view in self.view.subviews) {
		if ([view isKindOfClass:[UITextView class]])
			[view resignFirstResponder];
	}
}
- (IBAction)didPressSendButton:(id)sender {
    //start loading hub
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    NSLog(@"%@", reviewObj);
    
    if(!reviewObj){
        reviewObj = [PFObject objectWithClassName:kReviewClassKey];
        NSLog(@"assert reviewObj %@", reviewObj);
    }
    
//    [reviewObj setObject:[PFUser currentUser] forKey:kReviewFromUserKey];
//    [reviewObj setObject:self.videoObj forKey:kReviewTargetVideoKey];
//    [reviewObj setObject:self.commentTextView.text forKey:kReviewCommentKey];
    reviewObj[kReviewFromUserKey] = [PFUser currentUser];
    reviewObj[kReviewTargetVideoKey] = self.videoObj;
    reviewObj[kReviewCommentKey] = self.commentTextView.text;
    
    NSMutableDictionary *content = [[NSMutableDictionary alloc] init ];
    [content setObject:self.organizationLabel.text forKey:@"organization"];
    [content setObject:self.understandLabel.text forKey:@"understandability"];
    [content setObject:self.appearanceLabel.text forKey:@"appearance"];
//    [reviewObj setObject:content forKey:kReviewContentKey];
    reviewObj[kReviewContentKey] = content;
    NSLog(@"reviewObj before save = %@", reviewObj);
    
    [reviewObj saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if(!error){
            NSLog(@"save succeeded");
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Save Review Succeeded" message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Dismiss", nil];
            [alert show];
            
            // Send a notification to all devices subscribed to the "Giants" channel.
            PFPush *push = [[PFPush alloc] init];
            NSString *channelName = self.videoObj[@"user"];
            NSLog(@"%@", channelName);
            [push setChannel:channelName];
            [push setMessage:@"The Giants just scored!"];
            [push sendPushInBackground];
            
        } else{
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Save Review Failed" message:@"Please try again later." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Dismiss", nil];
            [alert show];
            
        }
    }];
    
    NSLog(@"reviewObj after save = %@", reviewObj);
    
    // Add this review to the reviews list of the answerVideo
    NSMutableArray *reviews = [[NSMutableArray alloc]init];
    
    if ([self.videoObj objectForKey:kVideoReviewsKey]) {
        for (PFObject *review in [self.videoObj objectForKey:kVideoReviewsKey]) {
            [reviews addObject:review];
        }
    }
    NSLog(@"1 reviews = %@", reviews);
    [reviews addObject:reviewObj];
    NSLog(@"2 reviews = %@", reviews);
    [self.videoObj setObject:reviews forKey:kVideoReviewsKey];
    PFQuery *query = [PFQuery queryWithClassName:kVideoClassKey];
    [query whereKey:kObjectIdKey equalTo:[self.videoObj objectId]];
    [query getFirstObjectInBackgroundWithBlock:^(PFObject *answerVideo, NSError *error) {
        if (!error) {
            [answerVideo setObject:reviews forKey:kVideoReviewsKey];
            [answerVideo saveInBackground];
            NSLog(@"answerVideo = %@", answerVideo);
        } else {
            // Did not find any answerVideo in server for self.videoObj
            NSLog(@"Error: %@", error);
        }
    }];
    //dismiss hub
    [MBProgressHUD hideHUDForView:self.view animated:YES];
}

- (void) queryCurrentReview {
    
    NSArray *reviews = [self.videoObj objectForKey:kVideoReviewsKey];
    
    NSLog(@"queryCurrentReview reviews = %@", reviews);

    PFQuery *review = [PFQuery queryWithClassName:kReviewClassKey];
    [review whereKey:kReviewFromUserKey equalTo:[PFUser currentUser]];
    [review whereKey:kReviewTargetVideoKey equalTo:self.videoObj];
    [review getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        if(!error && object != nil){
            reviewObj = object;
            NSDictionary *content = [reviewObj objectForKey:kReviewContentKey];
            self.organizationLabel.text = [content objectForKey:@"appearance"];
            self.understandLabel.text = [content objectForKey:@"understandability"];
            self.appearanceLabel.text = [content objectForKey:@"appearance"];
            self.commentTextView.text = [reviewObj objectForKey:kReviewCommentKey];
        }
    }];
    NSLog(@"queryCurrentReview reviewObject = %@", reviewObj);
}
@end
