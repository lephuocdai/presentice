//
//  VideoViewController.h
//  Presentice
//
//  Created by レー フックダイ on 1/7/14.
//  Copyright (c) 2014 Presentice. All rights reserved.
//

#import "PresenticeUtility.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <MediaPlayer/MediaPlayer.h>

#import "TakeReviewViewController.h"
#import "ReviewDetailViewController.h"
#import "UserProfileViewController.h"

@interface VideoViewController : PFQueryTableViewController <UINavigationControllerDelegate, UINavigationBarDelegate, UIAlertViewDelegate, AmazonServiceRequestDelegate, UIImagePickerControllerDelegate>

// For display answerVideo
@property (strong, nonatomic) IBOutlet UIImageView *userProfilePicture;
@property (strong, nonatomic) IBOutlet UILabel *postedUserLabel;
@property (strong, nonatomic) IBOutlet UILabel *videoNameLabel;
@property (strong, nonatomic) IBOutlet UILabel *questionVideoLabel;
@property (strong, nonatomic) IBOutlet UILabel *viewNumLabel;
@property (strong, nonatomic) IBOutlet UIView *videoView;
@property (strong, nonatomic) IBOutlet UILabel *noteView;

@property (copy, nonatomic)NSURL *movieURL;
@property (strong, nonatomic) PFObject *answerVideoObj;
@property (strong, nonatomic)MPMoviePlayerController *movieController;

@property BOOL isFromQuestionDetail;

@end
