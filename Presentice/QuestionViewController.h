//
//  QuestionViewController.h
//  Presentice
//
//  Created by レー フックダイ on 12/24/13.
//  Copyright (c) 2013 Appcoda. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>

#import "PostAnswerViewController.h"

@interface QuestionViewController : UIViewController

@property (strong, nonatomic) IBOutlet UILabel *fileLabel;
@property (strong, nonatomic) IBOutlet UILabel *userLabel;

- (IBAction)takeAnswer:(id)sender;


@property (strong, nonatomic) NSString *fileName;
@property (strong, nonatomic) NSString *userName;
@property (copy, nonatomic)NSURL *movieURL;
@property (strong, nonatomic)MPMoviePlayerController *movieController;

@property (strong, nonatomic) PFObject *questionVideo;

@end
