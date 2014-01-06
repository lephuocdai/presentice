//
//  MyAnswerViewController.h
//  Presentice
//
//  Created by レー フックダイ on 1/6/14.
//  Copyright (c) 2014 Presentice. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import <Parse/Parse.h>

#import "Constants.h"
//#import "VideoInfoCell.h"

@interface MyAnswerViewController : UITableViewController

@property (strong, nonatomic) NSString *fileName;
@property (copy, nonatomic)NSURL *movieURL;
@property (strong, nonatomic)MPMoviePlayerController *movieController;

@property (strong, nonatomic) PFObject *videoObj;

@end
