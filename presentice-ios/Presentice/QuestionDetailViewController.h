//
//  QuestionDetailViewController.h
//  Presentice
//
//  Created by レー フックダイ on 1/14/14.
//  Copyright (c) 2014 Presentice. All rights reserved.
//

#import "PresenticeUtility.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <MediaPlayer/MediaPlayer.h>

#import "VideoViewController.h"
#import "UserProfileViewController.h"
#import "EditNoteViewController.h"


@interface QuestionDetailViewController : PFQueryTableViewController <UINavigationControllerDelegate, UINavigationBarDelegate, UIAlertViewDelegate, AmazonServiceRequestDelegate, UIImagePickerControllerDelegate>


// For display questionVideo
@property (strong, nonatomic) IBOutlet UIImageView *userProfilePicture;
@property (strong, nonatomic) IBOutlet UILabel *postedUserLabel;
@property (strong, nonatomic) IBOutlet UILabel *videoNameLabel;
@property (strong, nonatomic) IBOutlet UILabel *noteView;
@property (strong, nonatomic) IBOutlet UIView *videoView;

@property (copy, nonatomic)NSURL *movieURL;
@property (strong, nonatomic) PFObject *questionVideoObj;
#pragma play movie
@property (strong, nonatomic)MPMoviePlayerController *movieController;


// For taking answerVideo
- (IBAction)takeAnswer:(id)sender;

@property (nonatomic, strong) S3TransferManager *tm;

- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo;

@property (strong, nonatomic, getter = theNewAnswerVideoName) NSString *newAnswerVideoName;
@property (strong, nonatomic, getter = theNewAnswerVideoVisibility) NSString *newAnswerVideoVisibility;
@property (strong, nonatomic, getter = theNewAnswerVideoObj) PFObject *newAnswerVideoObj;

@end
