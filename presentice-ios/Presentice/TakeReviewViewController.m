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
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super initWithCoder:aDecoder])) {

        self.root = [[QRootElement alloc] initWithJSONFile:@"reviewForm"];
        
        QAppearance *fieldsAppearance = [self.root.appearance copy];
        fieldsAppearance.backgroundColorEnabled = [UIColor colorWithRed:0 green:125.0/255 blue:225.0/255 alpha:1];
        [self.root elementWithKey:@"sendReviewButton"].appearance = fieldsAppearance;

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
        if (comment.textValue)
            [reviewObj setObject:comment.textValue forKey:kActivityDescriptionKey];
        [reviewObj setObject:self.videoObj forKey:kActivityTargetVideoKey];
        [reviewObj setObject:[self.videoObj objectForKey:kVideoUserKey] forKey:kActivityToUserKey];
        
        NSMutableDictionary *criteria = [[NSMutableDictionary alloc] init ];
        for (QPickerElement *rating in ratings) {
            NSNumber *value;
            NSLog(@"value class = %@", [rating.value class]);
            if ([rating.value isKindOfClass:[NSString class]]) {
                NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
                [f setNumberStyle:NSNumberFormatterDecimalStyle];
                value = [f numberFromString:rating.value];
            } else {
                value = rating.value;
            }
            [criteria setObject:value forKey:rating.key];
            NSLog(@"Title: %@ - %@ = %@ \n", rating.title, rating.key, rating.value);
        }
        NSDictionary *content = [[NSDictionary alloc] initWithObjectsAndKeys:criteria, kActivityReviewCriteriaKey, [NSNumber numberWithInteger:VIEW_REVIEW_WAITNG_TIME], kActivityReviewWaitingTime, nil];
        
        [reviewObj setObject:content forKey:kActivityContentKey];
        
        NSLog(@"reviewObj before save = %@", reviewObj);
        
        [reviewObj saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if(!error){
                
                //call cloud code and set Promotion
                NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
                [params setObject:[[self.videoObj objectForKey:kVideoToUserKey] objectId] forKey:@"toUser"];
                [params setObject:comment.textValue forKey:@"comment"];
                NSLog(@"params: %@", params);
                [PFCloud callFunction:@"onReviewed" withParameters:params];

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
                NSLog(@"reviewObj after save = %@", reviewObj);
                
                // Add this review to the reviews list of the answerVideo
                NSMutableArray *reviews = [[NSMutableArray alloc] initWithArray:[self.videoObj objectForKey:kVideoReviewsKey]];
                [reviews addObject:reviewObj];
                [self.videoObj setObject:reviews forKey:kVideoReviewsKey];
                
                PFQuery *query = [PFQuery queryWithClassName:kVideoClassKey];
                [query getObjectInBackgroundWithId:self.videoObj.objectId block:^(PFObject *answerVideo, NSError *error) {
                    if (!error) {
                        [answerVideo setObject:reviews forKey:kVideoReviewsKey];
                        [answerVideo saveInBackground];
                    } else {
                        // Did not find any answerVideo in server for self.videoObj
                        NSLog(@"update self.videoObj error : %@", error);
                    }
                }];
            } else{
                NSLog(@"saveInBackgroundWithBlock error = %@", error);
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Save Review Failed" message:@"Please try again later." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Dismiss", nil];
                [alert show];
            }
        }];
    } else {
        PFQuery *query = [PFQuery queryWithClassName:kActivityClassKey];
        [query getObjectInBackgroundWithId:reviewObj.objectId block:^(PFObject *object, NSError *error) {
            if (!error) {
                if (comment.textValue)
                    [object setObject:comment.textValue forKey:kActivityDescriptionKey];
                
                NSMutableDictionary *criteria = [[NSMutableDictionary alloc] init ];
                for (QPickerElement *rating in ratings) {
                    NSNumber *value;
                    NSLog(@"value class = %@", [rating.value class]);
                    if ([rating.value isKindOfClass:[NSString class]]) {
                        NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
                        [f setNumberStyle:NSNumberFormatterDecimalStyle];
                        value = [f numberFromString:rating.value];
                    } else {
                        value = rating.value;
                    }
                    [criteria setObject:value forKey:rating.key];
                    NSLog(@"Title: %@ - %@ = %@ \n", rating.title, rating.key, rating.value);
                }
                NSDictionary *content = [[NSDictionary alloc] initWithObjectsAndKeys:criteria, kActivityReviewCriteriaKey, [NSNumber numberWithInteger:VIEW_REVIEW_WAITNG_TIME], kActivityReviewWaitingTime, nil];
                
                [object setObject:content forKey:kActivityContentKey];
                
                [object saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    if(!error){
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
                        [PresenticeUtility showErrorAlert:error];
                    }
                }];
            } else {
                NSLog(@"getObjectInBackgroundWithId error = %@", error);
            }
        }];
    }
    [self loading:NO];
}

- (void) getCurrentReview {
    NSArray *reviews = [self.videoObj objectForKey:kVideoReviewsKey];
    
    NSLog(@"getCurrentReview reviews = %@", reviews);
    self.didReview = false;
    for (PFObject *review in reviews) {
        if (review != (id)[NSNull null]) {
            // In case the currentUser already reviewed this video before
            if ([[[review objectForKey:kActivityFromUserKey] objectId] isEqualToString:[[PFUser currentUser] objectId]]) {
                reviewObj = review;
                self.didReview = true;
                self.root.title = @"Edit Review";
                ((QButtonElement*)[self.root elementWithKey:@"sendReviewButton"]).title = @"Update this review";
                
                QMultilineElement *comment = [((QSection*)[self.root.sections objectAtIndex:1]).elements firstObject];
                if ([review objectForKey:kActivityDescriptionKey]) {
                    comment.textValue = [review objectForKey:kActivityDescriptionKey];
                    comment.title = @"Last comment";
                }
                NSArray *ratings = [NSArray arrayWithArray:((QSection*)[self.root.sections firstObject]).elements];
                for (QPickerElement *rating in ratings) {
                    rating.value = [[[review objectForKey:kActivityContentKey] objectForKey:kActivityReviewCriteriaKey] objectForKey:rating.key];
                }
            }
        }
    }
    NSLog(@"reviewObject = %@", reviewObj);
}

@end
