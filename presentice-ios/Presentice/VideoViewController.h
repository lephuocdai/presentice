//
//  VideoViewController.h
//  Presentice
//
//  Created by レー フックダイ on 1/7/14.
//  Copyright (c) 2014 Presentice. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Constants.h"
#import <Parse/Parse.h>
#import "MBProgressHUD.h"

#import <AWSRuntime/AWSRuntime.h>
#import <AWSS3/AWSS3.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <MediaPlayer/MediaPlayer.h>

#import "TakeReviewViewController.h"
#import "ReviewDetailViewController.h"

@interface VideoViewController : PFQueryTableViewController <UINavigationControllerDelegate, UINavigationBarDelegate, UIAlertViewDelegate, AmazonServiceRequestDelegate, UIImagePickerControllerDelegate>

// For display answerVideo
@property (strong, nonatomic) IBOutlet UILabel *videoNameLabel;
@property (strong, nonatomic) IBOutlet UILabel *postedUserLabel;
@property (strong, nonatomic) IBOutlet UILabel *viewNumLabel;
@property (copy, nonatomic)NSURL *movieURL;
@property (strong, nonatomic) PFObject *answerVideoObj;
@property (strong, nonatomic) IBOutlet UIView *videoView;
@property (strong, nonatomic)MPMoviePlayerController *movieController;




//@property (strong, nonatomic) NSString *fileName;
//@property (copy, nonatomic)NSURL *movieURL;
//@property (strong, nonatomic)MPMoviePlayerController *movieController;
//@property (strong, nonatomic) PFObject *videoObj;

@end
