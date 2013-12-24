//
//  MapViewController.h
//  SidebarDemo
//
//  Created by Simon on 30/6/13.
//  Copyright (c) 2013 Appcoda. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SWRevealViewController.h"

#import <AWSRuntime/AWSRuntime.h>
#import <AWSS3/AWSS3.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <MediaPlayer/MediaPlayer.h>
#import <MobileCoreServices/UTCoreTypes.h>
#import "Constants.h"

#import <Parse/Parse.h>

@interface ShareViewController : UIViewController <UINavigationControllerDelegate, UIAlertViewDelegate, AmazonServiceRequestDelegate, UIImagePickerControllerDelegate>

@property (weak, nonatomic) IBOutlet UIBarButtonItem *sidebarButton;

@property (nonatomic, strong) S3TransferManager *tm;

- (IBAction)upload:(id)sender;
- (IBAction)record:(id)sender;
@property (weak, nonatomic) IBOutlet UITextField *putObjectTextField;
// This file may not be used
@property (weak, nonatomic) IBOutlet UITextField *multipartObjectTextField;

- (BOOL)startCameraControllerFromViewController:(UIViewController *)controller usingDelegate:(id)delegate;
- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo;

@end
