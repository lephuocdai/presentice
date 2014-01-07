//
//  VideoViewController.h
//  Presentice
//
//  Created by レー フックダイ on 1/7/14.
//  Copyright (c) 2014 Presentice. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import "ReviewViewController.h"


@interface VideoViewController : UITableViewController

//@property (strong, nonatomic) IBOutlet UILabel *postedUserLabel;
//@property (strong, nonatomic) IBOutlet UILabel *fileNameLabel;
//@property (strong, nonatomic) IBOutlet UILabel *viewsNumLabel;
//@property (strong, nonatomic) IBOutlet UILabel *reviewsNumLabel;
//@property (strong, nonatomic) IBOutlet UIView *videoView;

@property (strong, nonatomic) NSString *fileName;
@property (copy, nonatomic)NSURL *movieURL;
@property (strong, nonatomic)MPMoviePlayerController *movieController;

@property (strong, nonatomic) PFObject *videoObj;
@end
