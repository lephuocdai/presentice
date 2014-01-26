//
//  ReviewViewController.m
//  Presentice
//
//  Created by PhuongNQ on 12/29/13.
//  Copyright (c) 2013 Presentice. All rights reserved.
//

#import "TakeReviewViewController.h"

PFObject *reviewObj;

@interface TakeReviewViewController ()

@end

@implementation TakeReviewViewController {
//    NSMutableArray *sections;
//    NSMutableDictionary *ratings;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super initWithCoder:aDecoder])) {

        self.root = [[QRootElement alloc] initWithJSONFile:@"reviewForm"];

        self.resizeWhenKeyboardPresented = YES;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self getCurrentReview];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    NSLog(@"fuck you out of Login View Controller");
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)QEntryShouldChangeCharactersInRangeForElement:(QEntryElement *)element andCell:(QEntryTableViewCell *)cell {
    NSLog(@"Should change characters");
    return YES;
}

- (void)QEntryEditingChangedForElement:(QEntryElement *)element andCell:(QEntryTableViewCell *)cell {
    NSLog(@"Editing changed");
}

- (void)QEntryMustReturnForElement:(QEntryElement *)element andCell:(QEntryTableViewCell *)cell {
    NSLog(@"Must return");
}


- (void)onSendReview:(QButtonElement *)buttonElement {
    [self loading:YES];
    
    NSArray *sections = self.root.sections;
    QMultilineElement *comment = [((QSection*)[sections objectAtIndex:1]).elements firstObject];
    NSArray *ratings = [NSArray arrayWithArray:((QSection*)[sections firstObject]).elements];
    NSLog(@"%@ = %@ \n",comment.key, comment.textValue);
    
    for (QPickerElement *rating in ratings) {
        if (!rating.value) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Rating missed" message:[NSString stringWithFormat:@"You have not rated for %@",rating.title] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
            [alert show];
            [self loading:NO];
            return;
        }
    }
    
    if(!reviewObj){
        reviewObj = [PFObject objectWithClassName:kActivityClassKey];
        NSLog(@"assert reviewObj %@", reviewObj);
        
        [reviewObj setObject:@"review" forKey:kActivityTypeKey];
        [reviewObj setObject:[PFUser currentUser] forKey:kActivityFromUserKey];
        [reviewObj setObject:comment.textValue forKey:kActivityDescriptionKey];
        [reviewObj setObject:self.videoObj forKey:kActivityTargetVideoKey];
        [reviewObj setObject:[self.videoObj objectForKey:kVideoUserKey] forKey:kActivityToUserKey];
        
        NSMutableDictionary *content = [[NSMutableDictionary alloc] init ];
        for (QPickerElement *rating in ratings) {
            [content setObject:rating.value forKey:rating.key];
            NSLog(@"Title: %@ - %@ = %@ \n", rating.title, rating.key, rating.value);
        }
        [reviewObj setObject:content forKey:kActivityContentKey];
        
        NSLog(@"reviewObj before save = %@", reviewObj);
        
        [reviewObj saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            NSLog(@"reviewObj after save = %hhd", succeeded);
            if(!error){
                NSLog(@"save succeeded");
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Save Review Succeeded" message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Dismiss", nil];
                [alert show];
                
                // Send a notification to the device with channel contain video's userId
                if ([[[[self.videoObj objectForKey:kVideoUserKey] objectForKey:kUserPushPermission] objectForKey:@"reviewed"] isEqualToString:@"yes"]) {
                    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
                    [params setObject:[self.videoObj objectForKey:kVideoNameKey] forKey:@"targetVideo"];
                    [params setObject:[[self.videoObj objectForKey:kVideoUserKey] objectId] forKey:@"toUser"];
                    [params setObject:@"reviewed" forKey:@"pushType"];
                    [PFCloud callFunction:@"sendPushNotification" withParameters:params];
                }
            } else{
                NSLog(@"saveInBackgroundWithBlock error = %@", error);
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
        
        [reviews addObject:reviewObj];
        
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
    } else {
        PFQuery *query = [PFQuery queryWithClassName:kActivityClassKey];
        [query getObjectInBackgroundWithId:reviewObj.objectId block:^(PFObject *object, NSError *error) {
            if (!error) {
                [object setObject:comment.textValue forKey:kActivityDescriptionKey];
                
                NSMutableDictionary *content = [[NSMutableDictionary alloc] init ];
                for (QPickerElement *rating in ratings) {
                    [content setObject:rating.value forKey:rating.key];
                    NSLog(@"Title: %@ - %@ = %@ \n", rating.title, rating.key, rating.value);
                }
                [object setObject:content forKey:kActivityContentKey];
                
                [object saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    if(!error){
                        NSLog(@"save succeeded");
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Update Review Succeeded" message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Dismiss", nil];
                        [alert show];
                        
                        // Send a notification to the device with channel contain video's userId
                        if ([[[[self.videoObj objectForKey:kVideoUserKey] objectForKey:kUserPushPermission] objectForKey:@"reviewed"] isEqualToString:@"yes"]) {
                            NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
                            [params setObject:[self.videoObj objectForKey:kVideoNameKey] forKey:@"targetVideo"];
                            [params setObject:[[self.videoObj objectForKey:kVideoUserKey] objectId] forKey:@"toUser"];
                            [params setObject:@"reviewed" forKey:@"pushType"];
                            [PFCloud callFunction:@"sendPushNotification" withParameters:params];
                        }
                    } else{
                        NSLog(@"saveInBackgroundWithBlock error = %@", error);
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Update Review Failed" message:@"Please try again later." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Dismiss", nil];
                        [alert show];
                    }
                }];
            } else {
                NSLog(@"getObjectInBackgroundWithId error = %@", error);
            }
        }];
    }
    [self loading:NO];
}

/**
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
 **/

/**
 * end of editing
 * dissmis input keyboard


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
        reviewObj = [PFObject objectWithClassName:kActivityClassKey];
        NSLog(@"assert reviewObj %@", reviewObj);
    }
    
    [reviewObj setObject:@"review" forKey:kActivityTypeKey];
    [reviewObj setObject:[PFUser currentUser] forKey:kActivityFromUserKey];
//    [reviewObj setObject:self.commentTextView.text forKey:kActivityDescriptionKey];
    [reviewObj setObject:self.videoObj forKey:kActivityTargetVideoKey];
    [reviewObj setObject:[self.videoObj objectForKey:kVideoUserKey] forKey:kActivityToUserKey];
    
    NSMutableDictionary *content = [[NSMutableDictionary alloc] init ];
//    [content setObject:self.organizationLabel.text forKey:@"organization"];
//    [content setObject:self.understandLabel.text forKey:@"understandability"];
//    [content setObject:self.appearanceLabel.text forKey:@"appearance"];
    [reviewObj setObject:content forKey:kActivityContentKey];
    
    NSLog(@"reviewObj before save = %@", reviewObj);
    
    [reviewObj saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if(!error){
            NSLog(@"save succeeded");
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Save Review Succeeded" message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Dismiss", nil];
            [alert show];
            
            // Send a notification to the device with channel contain video's userId
            if ([[[[self.videoObj objectForKey:kVideoUserKey] objectForKey:kUserPushPermission] objectForKey:@"reviewed"] isEqualToString:@"yes"]) {
                NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
                [params setObject:[self.videoObj objectForKey:kVideoNameKey] forKey:@"targetVideo"];
                [params setObject:[[self.videoObj objectForKey:kVideoUserKey] objectId] forKey:@"toUser"];
                [params setObject:@"reviewed" forKey:@"pushType"];
                [PFCloud callFunction:@"sendPushNotification" withParameters:params];
            }
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

    [reviews addObject:reviewObj];

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
**/
- (void) getCurrentReview {
    NSArray *reviews = [self.videoObj objectForKey:kVideoReviewsKey];
    
    NSLog(@"getCurrentReview reviews = %@", reviews);
    
    self.didReview = false;
    for (PFObject *review in reviews) {
        // In case the currentUser already reviewed this video before
        if ([[[review objectForKey:kActivityFromUserKey] objectId] isEqualToString:[PFUser currentUser].objectId]) {
            reviewObj = review;
            
            self.didReview = true;
            self.root.title = @"Edit Review";
            ((QButtonElement*)[self.root elementWithKey:@"sendReviewButton"]).title = @"Update this review";
            
            QMultilineElement *comment = [((QSection*)[self.root.sections objectAtIndex:1]).elements firstObject];
            comment.textValue = [review objectForKey:kActivityDescriptionKey];
            comment.title = @"Last comment";
            
            NSArray *ratings = [NSArray arrayWithArray:((QSection*)[self.root.sections firstObject]).elements];
            for (QPickerElement *rating in ratings) {
                rating.value = [[review objectForKey:kActivityContentKey] objectForKey:rating.key];
            }
        }
    }
    
    NSLog(@"reviewObject = %@", reviewObj);
}

@end
