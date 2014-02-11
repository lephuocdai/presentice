//
//  ReviewDetailViewController.h
//  Presentice
//
//  Created by レー フックダイ on 1/15/14.
//  Copyright (c) 2014 Presentice. All rights reserved.
//

#import "PresenticeUtility.h"

#import "UserProfileViewController.h"


@interface ReviewDetailViewController : UITableViewController

@property (strong, nonatomic) PFObject *reviewObject;

@property (strong, nonatomic) IBOutlet UIImageView *userProfilePicture;
@property (strong, nonatomic) IBOutlet UILabel *reviewerNameLabel;
@property (strong, nonatomic) IBOutlet UILabel *answerVideoNameLabel;
@property (strong, nonatomic) IBOutlet UILabel *answerVideoPosterUserNameLabel;

@property (strong, nonatomic) IBOutlet UIView *commentView;
- (IBAction)reply:(id)sender;

@end
