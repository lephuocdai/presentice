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


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.scrollView setScrollEnabled:YES];
    [self.scrollView setContentSize:(CGSizeMake(320, 860))];

    fileLabel.text = fileName;
    userLabel.text = userName;
    
//    [self.scrollView addSubview:[[]
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated {
    self.movieController = [[MPMoviePlayerController alloc] init];
    
    [self.movieController setContentURL:self.movieURL];
    [self.movieController.view setFrame:CGRectMake(0, 130, 320, 400)];
//    [self.view addSubview:self.movieController.view];
    [self.scrollView addSubview:self.movieController.view];
    
    // Using the Movie Player Notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayBackDidFinish:) name:MPMoviePlayerPlaybackDidFinishNotification object:self.movieController];
    
    
    self.movieController.controlStyle =  MPMovieControlStyleEmbedded;
    self.movieController.shouldAutoplay = YES;
    self.movieController.repeatMode = NO;
    [self.movieController prepareToPlay];
    [self.movieController play];
    
    // Add activity
    PFObject *activity = [PFObject objectWithClassName:kActivityClassKey];
    [activity setObject:[PFUser currentUser] forKey:kActivityFromUserKey];
    [activity setObject:[self.videoObj objectForKey:kVideoUserKey] forKey:kActivityToUserKey];
    [activity setObject:@"view" forKey:kActivityTypeKey];
    [activity setObject:self.videoObj forKey:kACtivityTargetVideoKey];
    [activity saveInBackground];
    
    
    // Increment views
    int viewsNum = [[self.videoObj objectForKey:kVideoViewsKey] intValue];
    [self.videoObj setObject:[NSNumber numberWithInt:viewsNum+1] forKey:kVideoViewsKey];
    PFQuery *query = [PFQuery queryWithClassName:kVideoClassKey];
    [query getObjectInBackgroundWithId:[self.videoObj objectId] block:^(PFObject *object, NSError *error) {
        [object setObject:[NSNumber numberWithInt:viewsNum+1] forKey:kVideoViewsKey];
        [object saveInBackground];
    }];
    [self.videoObj saveInBackground];
    NSLog(@"after videoObj = %@", self.videoObj);
}

- (void)moviePlayBackDidFinish:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
}
- (void) viewWillDisappear:(BOOL)animated {
    [self.movieController stop];
    [self.movieController.view removeFromSuperview];
    self.movieController = nil;
}


- (IBAction)takeAnswer:(id)sender { }

/**
 * segue for takeAnswer button
 * click to direct to video upload/record view
 * pass questionVideoId
 */

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showPostAnswer"]) {
        PostAnswerViewController *destViewController = segue.destinationViewController;
        destViewController.questionVideoId = self.questionVideoId;
        destViewController.questionVideoObj = self.videoObj;
    }
}

@end
