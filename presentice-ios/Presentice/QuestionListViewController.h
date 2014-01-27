//
//  QuestionListViewController.h
//  Presentice
//
//  Created by レー フックダイ on 12/31/13.
//  Copyright (c) 2013 Presentice. All rights reserved.
//

#import <Parse/Parse.h>
#import "MFSideMenu.h"
#import "MBProgressHUD.h"
#import "Constants.h"
#import "PresenticeUtitily.h"

#import <AWSRuntime/AWSRuntime.h>
#import <AWSS3/AWSS3.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <MediaPlayer/MediaPlayer.h>
#import <MobileCoreServices/UTCoreTypes.h>

#import "UILabel+Boldify.h"

#import "QuestionDetailViewController.h"


@interface QuestionListViewController : PFQueryTableViewController <UINavigationControllerDelegate, AmazonServiceRequestDelegate, UITableViewDelegate, UITableViewDataSource, UIAlertViewDelegate, UIImagePickerControllerDelegate>

// For display question list
@property (strong, nonatomic) IBOutlet UITableView *tableView;
- (IBAction)showLeftMenu:(id)sender;


// For adding more question
- (IBAction)addQuestion:(id)sender
;
@property (nonatomic, strong) S3TransferManager *tm;

- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo;

@property (strong, nonatomic) NSString *questionVideoName;


@end
