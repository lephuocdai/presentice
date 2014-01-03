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

@interface QuestionViewController : UIViewController <UINavigationBarDelegate>

@property (strong, nonatomic) IBOutlet UILabel *fileLabel;
@property (strong, nonatomic) IBOutlet UILabel *userLabel;

- (IBAction)takeAnswer:(id)sender;


@property (strong, nonatomic) NSString *fileName;
@property (strong, nonatomic) NSString *userName;
@property (copy, nonatomic)NSURL *movieURL;
@property (strong, nonatomic)MPMoviePlayerController *movieController;

@property (weak, nonatomic) NSString *questionVideoId;

@property (strong, nonatomic) PFObject *videoObj;

@end
