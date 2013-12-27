//
//  QuestionViewController.m
//  Presentice
//
//  Created by レー フックダイ on 12/24/13.
//  Copyright (c) 2013 Appcoda. All rights reserved.
//

#import "QuestionViewController.h"

@interface QuestionViewController ()

@end

@implementation QuestionViewController

@synthesize fileLabel;
@synthesize fileName;
@synthesize userLabel;
@synthesize userName;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    fileLabel.text = fileName;
    userLabel.text = userName;

    NSLog(@"In Question View: \n %@", self.questionVideo);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated {
    self.movieController = [[MPMoviePlayerController alloc] init];
    
    [self.movieController setContentURL:self.movieURL];
    [self.movieController.view setFrame:CGRectMake(0, 100, 320, 340)];
    [self.view addSubview:self.movieController.view];
    
    // Using the Movie Player Notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayBackDidFinish:) name:MPMoviePlayerPlaybackDidFinishNotification object:self.movieController];
    
    
    self.movieController.controlStyle =  MPMovieControlStyleEmbedded;
    self.movieController.shouldAutoplay = YES;
    self.movieController.repeatMode = NO;
    [self.movieController prepareToPlay];
    
    [self.movieController play];
}

- (void)moviePlayBackDidFinish:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
}
- (void) viewWillDisappear:(BOOL)animated {
    [self.movieController stop];
    [self.movieController.view removeFromSuperview];
    self.movieController = nil;
}


- (IBAction)takeAnswer:(id)sender {
    
//    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
//    PostAnswerViewController *destViewController = (PostAnswerViewController *) [storyboard instantiateViewControllerWithIdentifier:@"Storyboard_PostAnswer"];
    
    PostAnswerViewController *destViewController = [[PostAnswerViewController alloc] initWithNibName:nil bundle:nil];
    
    destViewController.questionVideo = self.questionVideo;
    [self presentViewController:destViewController animated:YES completion:nil];
    
    NSLog(@"In Question List takeAnswer View: \n  %@",destViewController.questionVideo);
    //[self.navigationController pushViewController:destViewController animated:YES];
}

/**
 * segue for table cell
 * click to direct to video play view
 * pass video name, video url
 */

@end
