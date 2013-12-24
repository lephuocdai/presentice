//
//  FileViewController.h
//  S3TransferManager
//
//  Created by レー フックダイ on 12/8/13.
//
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
//#import <AVFoundation/AVFoundation.h>

@interface FileViewController : UIViewController


@property (strong, nonatomic) IBOutlet UILabel *fileLabel;
@property (strong, nonatomic) NSString *fileName;
@property (copy, nonatomic)NSURL *movieURL;
@property (strong, nonatomic)MPMoviePlayerController *movieController;

@end
