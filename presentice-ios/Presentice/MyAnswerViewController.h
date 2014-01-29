//
//  MyAnswerViewController.h
//  Presentice
//
//  Created by レー フックダイ on 1/6/14.
//  Copyright (c) 2014 Presentice. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Constants.h"
#import <Parse/Parse.h>
#import "MBProgressHUD.h"
#import "PresenticeUtitily.h"

#import <AWSRuntime/AWSRuntime.h>
#import <AWSS3/AWSS3.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <MediaPlayer/MediaPlayer.h>

#import "ReviewDetailViewController.h"

@interface MyAnswerViewController : PFQueryTableViewController <UINavigationControllerDelegate, UINavigationBarDelegate, UIAlertViewDelegate, AmazonServiceRequestDelegate, UIImagePickerControllerDelegate>

// For display answerVideo
@property (strong, nonatomic) IBOutlet UILabel *questionVideoLabel;
@property (strong, nonatomic) IBOutlet UILabel *questionVideoPostedUserLabel;
@property (strong, nonatomic) IBOutlet UILabel *viewNumLabel;
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
