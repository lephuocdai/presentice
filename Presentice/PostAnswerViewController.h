//
//  PostAnswerViewController.h
//  Presentice
//
//  Created by レー フックダイ on 12/27/13.
//  Copyright (c) 2013 Appcoda. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <AWSRuntime/AWSRuntime.h>
#import <AWSS3/AWSS3.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <MediaPlayer/MediaPlayer.h>
#import <MobileCoreServices/UTCoreTypes.h>
#import "Constants.h"

#import <Parse/Parse.h>

@interface PostAnswerViewController : UIViewController <UINavigationControllerDelegate, UIAlertViewDelegate, AmazonServiceRequestDelegate, UIImagePickerControllerDelegate>

@property (nonatomic, strong) S3TransferManager *tm;

- (IBAction)upload:(id)sender;
- (IBAction)record:(id)sender;
@property (weak, nonatomic) IBOutlet UITextField *putObjectTextField;

@property (weak, nonatomic) NSString *questionVideoId;

//- (id)initWithQuestionVideo:(NSString *)questionVideoId;

// This file may not be used
@property (weak, nonatomic) IBOutlet UITextField *multipartObjectTextField;


- (BOOL)startCameraControllerFromViewController:(UIViewController *)controller usingDelegate:(id)delegate;
- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo;

@end
