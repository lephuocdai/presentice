//
//  MyAnswerViewController.h
//  Presentice
//
//  Created by レー フックダイ on 1/6/14.
//  Copyright (c) 2014 Presentice. All rights reserved.
//

#import "PresenticeUtility.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <MediaPlayer/MediaPlayer.h>

#import "UILabel+Boldify.h"

#import "ReviewDetailViewController.h"
#import "EditNoteViewController.h"

@interface MyAnswerViewController : PFQueryTableViewController <UINavigationControllerDelegate, UINavigationBarDelegate, UIAlertViewDelegate, AmazonServiceRequestDelegate, UIImagePickerControllerDelegate>

// For display answerVideo
@property (strong, nonatomic) IBOutlet UILabel *videoNameLabel;
@property (strong, nonatomic) IBOutlet UILabel *viewNumLabel;
@property (strong, nonatomic) IBOutlet UILabel *visibilityLabel;
@property (strong, nonatomic) IBOutlet UIView *videoView;
@property (strong, nonatomic) IBOutlet UILabel *noteView;


@property (copy, nonatomic)NSURL *movieURL;
@property (strong, nonatomic) PFObject *answerVideoObj;
@property (strong, nonatomic) PFUser *questionPostedUser;
@property (strong, nonatomic) PFObject *questionVideoObj;
@property (strong, nonatomic)MPMoviePlayerController *movieController;


// For edit video information
- (IBAction)editVideoInfo:(id)sender;

@end
