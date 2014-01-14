//
//  QuestionDetailViewController.h
//  Presentice
//
//  Created by レー フックダイ on 1/14/14.
//  Copyright (c) 2014 Presentice. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <AWSRuntime/AWSRuntime.h>
#import <AWSS3/AWSS3.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <MediaPlayer/MediaPlayer.h>
#import <MobileCoreServices/UTCoreTypes.h>
#import "Constants.h"

#import <Parse/Parse.h>
#import "MBProgressHUD.h"

@interface QuestionDetailViewController : PFQueryTableViewController <UINavigationControllerDelegate, UINavigationBarDelegate, UIAlertViewDelegate, AmazonServiceRequestDelegate, UIImagePickerControllerDelegate>


// For display questionVideo
@property (strong, nonatomic) IBOutlet UILabel *videoNameLabel;
@property (strong, nonatomic) IBOutlet UILabel *postedUserLabel;
@property (copy, nonatomic)NSURL *movieURL;
@property (strong, nonatomic) PFObject *questionVideoObj;
@property (strong, nonatomic) IBOutlet UIView *videoView;
@property (strong, nonatomic)MPMoviePlayerController *movieController;

// For taking answerVideo
- (IBAction)takeAnswer:(id)sender;
@property (weak, nonatomic) IBOutlet UITextField *putObjectTextField;
@property (nonatomic, strong) S3TransferManager *tm;
- (BOOL)startCameraControllerFromViewController:(UIViewController *)controller usingDelegate:(id)delegate;
- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo;
@property (strong, nonatomic) NSString *answerVideoName;
@property (strong, nonatomic) NSString *answerVideoVisibility;


@end
