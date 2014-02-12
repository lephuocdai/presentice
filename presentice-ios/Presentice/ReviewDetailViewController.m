//
//  ReviewDetailViewController.m
//  Presentice
//
//  Created by レー フックダイ on 1/15/14.
//  Copyright (c) 2014 Presentice. All rights reserved.
//

#import "ReviewDetailViewController.h"

@interface ReviewDetailViewController ()

@end

@implementation ReviewDetailViewController {
    NSMutableArray *criteria;
}

@synthesize reviewerNameLabel;
@synthesize answerVideoNameLabel;
@synthesize answerVideoPosterUserNameLabel;
@synthesize commentView;

//@synthesize thankYouLabel;

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Start loading HUD
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    if (![[[self.reviewObject objectForKey:kActivityToUserKey] objectId] isEqualToString:[[PFUser currentUser] objectId]])
        self.navigationItem.rightBarButtonItem = nil;
    
    [PresenticeUtility setImageView:self.userProfilePicture forUser:[self.reviewObject objectForKey:kActivityFromUserKey]];
    reviewerNameLabel.text = [NSString stringWithFormat:@"Reviewer: %@", [[self.reviewObject objectForKey:kActivityFromUserKey] objectForKey:kUserDisplayNameKey]];
    [reviewerNameLabel boldSubstring:@"Reviewer:"];
    answerVideoNameLabel.text = [NSString stringWithFormat:@"To video: %@", [[self.reviewObject objectForKey:kActivityTargetVideoKey] objectForKey:kVideoNameKey]];
    [answerVideoNameLabel boldSubstring:@"To video:"];
    answerVideoPosterUserNameLabel.text = [NSString stringWithFormat:@"Of user: %@", [[self.reviewObject objectForKey:kActivityToUserKey] objectForKey:kUserDisplayNameKey]];
    [answerVideoPosterUserNameLabel boldSubstring:@"Of user:"];
    UILabel *commentLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, 280, 200)];
    commentLabel.text = [self.reviewObject objectForKey:kActivityDescriptionKey];
    commentLabel.numberOfLines = 0;
    [commentLabel setTextAlignment:NSTextAlignmentLeft];
    [commentLabel setLineBreakMode:NSLineBreakByWordWrapping];
    [commentLabel sizeToFit];
    [commentView addSubview:commentLabel];
    
    NSLog(@"%@", commentView);
    criteria = [[NSMutableArray alloc] initWithArray:[[[self.reviewObject objectForKey:kActivityContentKey] objectForKey:kActivityReviewCriteriaKey] allKeys]];
    
    // Set tap gesture on user profile picture
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(actionHandleTapOnImageView)];
    [singleTap setNumberOfTapsRequired:1];
    self.userProfilePicture.userInteractionEnabled = YES;
    [self.userProfilePicture addGestureRecognizer:singleTap];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:YES];
    
    // Hid all HUD after all objects appered
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    
    [PresenticeUtility checkCurrentUserActivationIn:self];
}

- (void)actionHandleTapOnImageView {
    UserProfileViewController *userProfileViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"userProfileViewController"];
    userProfileViewController.userObj = [self.reviewObject objectForKey:kActivityFromUserKey];
    [self.navigationController pushViewController:userProfileViewController animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
//    return [criteria count];
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"reviewContentIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    NSString *criteriumKey = [criteria objectAtIndex:indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"%@: %@",
                           criteriumKey,
                           [[[self.reviewObject objectForKey:kActivityContentKey] objectForKey:kActivityReviewCriteriaKey] objectForKey:criteriumKey]];
    return cell;
}

- (IBAction)reply:(id)sender {
    if ([[self.reviewObject objectForKey:kActivityContentKey] objectForKey:kActivityReviewRateComment] == nil)
        [PresenticeUtility callAlert:alertRateComment withDelegate:self];
    else
        [PresenticeUtility callAlert:alertSayThanks withDelegate:self];
}
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == tagRateComment) {
        if (buttonIndex != 0) {
            NSMutableDictionary *content = [[NSMutableDictionary alloc] initWithDictionary:[self.reviewObject objectForKey:kActivityContentKey]];
            if (buttonIndex == 1) {
                [content setValue:kActivityReviewRateCommentSatisfied forKey:kActivityReviewRateComment];
                [PresenticeUtility callAlert:alertSayThanks withDelegate:self];
            } else {
                [content setValue:kActivityReviewRateCommentUnsatisfied forKey:kActivityReviewRateComment];
            }
            [self.reviewObject setObject:content forKey:kActivityContentKey];
            [self.reviewObject saveInBackground];
        }
    } else if (alertView.tag == tagSayThanks) {
        if (buttonIndex == 1) {
            [PresenticeUtility instantiateMessageDetailWith:[self.reviewObject objectForKey:kActivityFromUserKey] from:self animated:YES];
        }
    }
}

@end
