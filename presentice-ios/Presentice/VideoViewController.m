//
//  VideoViewController.m
//  Presentice
//
//  Created by レー フックダイ on 1/7/14.
//  Copyright (c) 2014 Presentice. All rights reserved.
//

#import "VideoViewController.h"

@interface VideoViewController ()

@end

@implementation VideoViewController {
}

@synthesize videoNameLabel;
@synthesize postedUserLabel;
@synthesize viewNumLabel;
@synthesize noteView;
@synthesize questionVideoLabel;
@synthesize visibilityLabel;
@synthesize averagePoint;

- (id)initWithCoder:(NSCoder *)aCoder {
    self = [super initWithCoder:aCoder];
    if (self) {
        // Custom the table
        self.parseClassName = kActivityClassKey;
        self.textKey = kActivityDescriptionKey;
        self.pullToRefreshEnabled = YES;
        self.paginationEnabled = YES;
        self.objectsPerPage = 5;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [PresenticeUtility checkCurrentUserActivationIn:self];
    
    // Prevent currentUser from edit the note
    if ([[[self.answerVideoObj objectForKey:kVideoUserKey] objectId] isEqualToString:[[PFUser currentUser] objectId]])
        self.navigationItem.rightBarButtonItem.title = NSLocalizedString(@"Edit", nil);
    else
        self.navigationItem.rightBarButtonItem.title = NSLocalizedString(@"Review", nil);

    // Start loading HUD
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    //asyn to get profile picture
    [PresenticeUtility setImageView:self.userProfilePicture forUser:[self.answerVideoObj objectForKey:kVideoUserKey]];
    videoNameLabel.text = [self.answerVideoObj objectForKey:kVideoNameKey];
    postedUserLabel.text = [[self.answerVideoObj objectForKey:kVideoUserKey] objectForKey:kUserDisplayNameKey];
    viewNumLabel.text = [PresenticeUtility stringNumberOfKey:kVideoViewsKey inObject:self.answerVideoObj];
    visibilityLabel.text = [PresenticeUtility visibilityOfVideo:self.answerVideoObj];
    averagePoint.text = [NSString stringWithFormat:@"Average review: %.1f", [PresenticeUtility getAverageReviewOfVideo:self.answerVideoObj]];
    questionVideoLabel.text = [NSString stringWithFormat:@"This is an answer of:\n%@", [[self.answerVideoObj objectForKey:kVideoAsAReplyTo] objectForKey:kVideoNameKey]];
    [questionVideoLabel sizeToFit];
    // There is a bug with iOS 6
//    [questionVideoLabel boldSubstring:@"This is an answer of:"];
    
    // Set tap gesture on questionVideoLabel when not pushed from Question Detail
    if (![[self.navigationController.viewControllers objectAtIndex:self.navigationController.viewControllers.count-2] isKindOfClass:NSClassFromString(@"QuestionDetailViewController")]) {
        UITapGestureRecognizer *singleTapForQuestion = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(actionHandleTapOnQuestionView)];
        [singleTapForQuestion setNumberOfTapsRequired:1];
        questionVideoLabel.userInteractionEnabled = YES;
        [questionVideoLabel addGestureRecognizer:singleTapForQuestion];
    }
    
    noteView.text = [NSString stringWithFormat:@"Note for viewer: \n%@",[self.answerVideoObj objectForKey:kVideoNoteKey]];
    // There is a bug with iOS 6
//    [noteView boldSubstring:@"Note for viewer:"];
    // Set tap gesture on noteview
    UITapGestureRecognizer *singleTapForNote = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(actionHandleTapOnNoteView)];
    [singleTapForNote setNumberOfTapsRequired:1];
    noteView.userInteractionEnabled = YES;
    [noteView addGestureRecognizer:singleTapForNote];
    
    
    // Set tap gesture on user profile picture
    UITapGestureRecognizer *singleTapForImage = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(actionHandleTapOnImageView)];
    [singleTapForImage setNumberOfTapsRequired:1];
    self.userProfilePicture.userInteractionEnabled = YES;
    [self.userProfilePicture addGestureRecognizer:singleTapForImage];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    // Set refreshTable notification
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshTable:)
                                                 name:@"refreshTable"
                                               object:nil];
}

- (void)actionHandleTapOnQuestionView {
    [PresenticeUtility callAlert:alertWillDisplayQuestionVideo withDelegate:self];

}

- (void)actionHandleTapOnNoteView {
    [PresenticeUtility callAlert:alertWillDisplayNote withDelegate:self];

}

- (void)actionHandleTapOnImageView {
    UserProfileViewController *userProfileViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"userProfileViewController"];
    userProfileViewController.userObj = [self.answerVideoObj objectForKey:kVideoUserKey];
    [self.navigationController pushViewController:userProfileViewController animated:YES];
}

- (void)viewWillAppear:(BOOL)animated {
    // If currentUser is not the video's owner
    if (![[[PFUser currentUser] objectId] isEqualToString:[[self.answerVideoObj objectForKey:kVideoUserKey] objectId]]) {
        // Send a "viewed" notification
        if ([[[[self.answerVideoObj objectForKey:kVideoUserKey] objectForKey:kUserPushPermission] objectForKey:@"viewed"] isEqualToString:@"yes"]) {
            NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
            [params setObject:[self.answerVideoObj objectForKey:kVideoNameKey] forKey:@"targetVideo"];
            [params setObject:[[self.answerVideoObj objectForKey:kVideoUserKey] objectId] forKey:@"toUser"];
            [params setObject:@"viewed" forKey:@"pushType"];
            NSLog(@"Send viewed push notification to %@", [[self.answerVideoObj objectForKey:kVideoUserKey] objectId]);
            [PFCloud callFunction:@"sendPushNotification" withParameters:params];
        }
        
        
        // Register view activity in to Acitivity Table
        PFQuery *activityQuery = [PFQuery queryWithClassName:kActivityClassKey];
        [activityQuery whereKey:kActivityTypeKey equalTo:@"view"];
        [activityQuery whereKey:kActivityFromUserKey equalTo:[PFUser currentUser]];
        [activityQuery whereKey:kActivityToUserKey equalTo:[self.answerVideoObj objectForKey:kVideoUserKey]];
        [activityQuery whereKey:kActivityTargetVideoKey equalTo:self.answerVideoObj];
        [activityQuery getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
            if (!error) {
                // Found activity record, so just overwrote it
                NSMutableDictionary *views = [[NSMutableDictionary alloc]initWithDictionary:[object objectForKey:kActivityContentKey]];
                [views setObject:@{@"date": [NSDate date]} forKey:[NSString stringWithFormat:@"%d", [[views allKeys] count]]];
                [object setObject:views forKey:kActivityContentKey];
                [object saveInBackground];
            } else {
                // No activity record, so create a new activity
                PFObject *activity = [PFObject objectWithClassName:kActivityClassKey];
                [activity setObject:@"view" forKey:kActivityTypeKey];
                [activity setObject:[PFUser currentUser] forKey:kActivityFromUserKey];
                [activity setObject:[self.answerVideoObj objectForKey:kVideoUserKey] forKey:kActivityToUserKey];
                [activity setObject:self.answerVideoObj forKey:kActivityTargetVideoKey];
                [activity setObject:@{@"0":@{@"date": [NSDate date]}} forKey:kActivityContentKey];
                [activity saveInBackground];
            }
        }];
        
        // Increment views
        int viewsNum = [[self.answerVideoObj objectForKey:kVideoViewsKey] intValue];
        [self.answerVideoObj setObject:[NSNumber numberWithInt:viewsNum+1] forKey:kVideoViewsKey];
        PFQuery *query = [PFQuery queryWithClassName:kVideoClassKey];
        [query getObjectInBackgroundWithId:[self.answerVideoObj objectId] block:^(PFObject *object, NSError *error) {
            [object setObject:[NSNumber numberWithInt:viewsNum+1] forKey:kVideoViewsKey];
            [object saveInBackground];
        }];
        [self.answerVideoObj saveInBackground];
        NSLog(@"after videoObj = %@", self.answerVideoObj);
    }
}

- (void)viewDidAppear:(BOOL)animated {
#pragma play movie
    // Set up movieController
    self.movieController = [[MPMoviePlayerController alloc] init];
    [self.movieController setContentURL:self.movieURL];
    [self.movieController.view setFrame:CGRectMake(0, 0, 320, 405)];
    [self.videoView addSubview:self.movieController.view];
    
    // Using the Movie Player Notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayBackDidFinish:) name:MPMoviePlayerPlaybackDidFinishNotification object:self.movieController];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterFullScreen:) name:MPMoviePlayerWillEnterFullscreenNotification object:nil];
    
    self.movieController.controlStyle =  MPMovieControlStyleEmbedded;
    self.movieController.shouldAutoplay = YES;
    self.movieController.repeatMode = NO;
    [self.movieController prepareToPlay];
    [self.movieController play];
    
    // Hid all HUD after all objects appered
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
}

- (void) viewWillDisappear:(BOOL)animated {
    //stop playing video
    if([self.navigationController.viewControllers indexOfObject:self] == NSNotFound){
        //Release any retained subviews of the main view.
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"refreshTable" object:nil];
        
        //release movie controller
        [self.movieController stop];
        [self.movieController.view removeFromSuperview];
        self.movieController = nil;
    }
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)refreshTable:(NSNotification *) notification {
    // Reload the recipes
    [self loadObjects];
    noteView.text = [NSString stringWithFormat:@"Note for viewer: \n%@",[self.answerVideoObj objectForKey:kVideoNoteKey]];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"refreshTable" object:nil];
}


#pragma query table objects

- (PFQuery *)queryForTable {
    PFQuery *reviewListQuery = [PFQuery queryWithClassName:self.parseClassName];
    [reviewListQuery whereKey:kActivityTypeKey equalTo:@"review"];
    [reviewListQuery whereKey:kActivityTargetVideoKey equalTo:self.answerVideoObj];
    [reviewListQuery whereKey:kActivityDescriptionKey notEqualTo:@""];
    [reviewListQuery includeKey:kActivityFromUserKey];   // Important: Include "fromUser" key in this query make receiving user info easier
    [reviewListQuery includeKey:kActivityToUserKey];
    [reviewListQuery includeKey:kActivityTargetVideoKey];
    
    // If no objects are loaded in memory, we look to the cache first to fill the table
    // and then subsequently do a query against the network.
    if ([self.objects count] == 0) {
        reviewListQuery.cachePolicy = kPFCachePolicyCacheThenNetwork;
    }
    [reviewListQuery orderByDescending:kUpdatedAtKey];
    return reviewListQuery;
}


- (void)moviePlayBackDidFinish:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
}
- (void)willEnterFullScreen:(NSNotification *)notification {
    NSLog(@"Enter full screen mode");
}


#pragma mark - Table view data source

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return @"Comments about this video";
    } else {
        if (![[[PFUser currentUser] objectId] isEqualToString:[[self.answerVideoObj objectForKey:kVideoUserKey] objectId]]) {
        return @"There is no review for this video. Be the first person to review it.";
        } else {
            return @"There is no review for this video. Request some of your friends to review it.";
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object {
    static NSString *simpleTableIdentifier = @"reviewListIdentifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
    }
    
    // Configure the cell
    UIImageView *userProfilePicture = (UIImageView *)[cell viewWithTag:100];
    UILabel *userName = (UILabel *)[cell viewWithTag:101];
    UILabel *postedTime = (UILabel *)[cell viewWithTag:102];
    UILabel *comment = (UILabel *)[cell viewWithTag:104];
    
    userProfilePicture.image = [UIImage imageWithData:
                                [NSData dataWithContentsOfURL:
                                 [NSURL URLWithString:
                                  [PresenticeUtility facebookProfilePictureofUser:
                                   [object objectForKey:kActivityFromUserKey]]]]];
    userProfilePicture.layer.cornerRadius = userProfilePicture.frame.size.width / 2;
    userProfilePicture.layer.masksToBounds = YES;
    
    userName.text = [[object objectForKey:kActivityFromUserKey] objectForKey:kUserDisplayNameKey];
    postedTime.text = [NSString stringWithFormat:@"%@", [[[NSDate alloc] initWithTimeInterval:0 sinceDate:object.updatedAt] dateTimeUntilNow]];
    comment.text = [object objectForKey:kActivityDescriptionKey];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
    if (indexPath.row < self.objects.count) {
        PFObject *object = [self.objects objectAtIndex:indexPath.row];
        [PresenticeUtility navigateToReviewDetail:object from:self];
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    } else {
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    }
}

- (void) objectsDidLoad:(NSError *)error {
    [super objectsDidLoad:error];
    NSLog(@"error: %@", [error localizedDescription]);
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == tagWillDisplayQuestionVideo) {
        if (buttonIndex == 1) {
            QuestionDetailViewController *destViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"questionDetailViewController"];
            PFQuery *videoQuery = [PFQuery queryWithClassName:kVideoClassKey];
            [videoQuery whereKey:kObjectIdKey equalTo:self.answerVideoObj.objectId];
            [videoQuery includeKey:kVideoAsAReplyTo];
            [videoQuery includeKey:@"asAReplyTo.user"];
            [videoQuery getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                if (!error) {
                    PFObject *questionVideo = [object objectForKey:kVideoAsAReplyTo];
                    NSLog(@"sent object = %@", questionVideo);
                    destViewController.movieURL = [PresenticeUtility s3URLForObject:questionVideo];
                    destViewController.questionVideoObj = questionVideo;
                    [self.navigationController pushViewController:destViewController animated:YES];
                } else {
                    [PresenticeUtility showErrorAlert:error];
                }
            }];
        }
    } else if (alertView.tag == tagWillDisplayNote) {
        if (buttonIndex == 1) {
            EditNoteViewController *editNoteViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"editNoteViewController"];
            editNoteViewController.note = [self.answerVideoObj objectForKey:kVideoNoteKey];
            editNoteViewController.videoObj = self.answerVideoObj;
            [self.navigationController pushViewController:editNoteViewController animated:YES];
        }
    } else if (alertView.tag == tagWillEditVideo) {
        if (buttonIndex == 1) {
            [PresenticeUtility callAlert:alertChangeVideoName withDelegate:self];

        } else if (buttonIndex == 2) {
            EditNoteViewController *editNoteViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"editNoteViewController"];
            editNoteViewController.note = [self.answerVideoObj objectForKey:kVideoNoteKey];
            editNoteViewController.videoObj = self.answerVideoObj;
            
            [self.navigationController pushViewController:editNoteViewController animated:YES];
        } else if (buttonIndex == 3) {
            [PresenticeUtility callAlert:alertSelectVisibility withDelegate:self];

        } else if (buttonIndex == 4) {
            [PresenticeUtility callAlert:alertWillDeleteVideo withDelegate:self];

        }
    } else if (alertView.tag == tagChangeVideoName) {
        if (buttonIndex == 1) {
            NSString *newName = [alertView textFieldAtIndex:0].text;
            PFObject *editedVideo = [PFObject objectWithoutDataWithClassName:kVideoClassKey objectId:self.answerVideoObj.objectId];
            [editedVideo setObject:newName forKey:kVideoNameKey];
            [editedVideo saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (!error) {
                    [self.answerVideoObj setObject:newName forKey:kVideoNameKey];
                    self.videoNameLabel.text = newName;
                    UIAlertView *successAlert = [[UIAlertView alloc] initWithTitle:@"Success" message:@"Video name change has been saved successfully" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
                    [successAlert show];
                } else {
                    [PresenticeUtility showErrorAlert:error];
                }
            }];
        }
    } else if (alertView.tag == tagSelectVisibility) {
        NSLog(@"alert = %@",[alertView buttonTitleAtIndex:buttonIndex]);
        NSString *answerVideoVisibility = [[NSString alloc] init];
        if (buttonIndex == 0)
            answerVideoVisibility = @"open";
        else if (buttonIndex == 1)
            answerVideoVisibility = @"friendOnly";
        else
            answerVideoVisibility = @"onlyMe";
        NSLog(@"visibility = %@", answerVideoVisibility);
        if (![[self.answerVideoObj objectForKey:kVideoVisibilityKey] isEqualToString:answerVideoVisibility]) {
            PFObject *editedVideo = [PFObject objectWithoutDataWithClassName:kVideoClassKey objectId:self.answerVideoObj.objectId];
            [editedVideo setObject:answerVideoVisibility forKey:kVideoVisibilityKey];
            [editedVideo saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (!error) {
                    [self.answerVideoObj setObject:answerVideoVisibility forKey:kVideoVisibilityKey];
                    self.visibilityLabel.text = [PresenticeUtility visibilityOfVideo:self.answerVideoObj];
                    UIAlertView *successAlert = [[UIAlertView alloc] initWithTitle:@"Success" message:@"Visibility change has been saved successfully" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
                    [successAlert show];
                } else {
                    [PresenticeUtility showErrorAlert:error];
                }
            }];
        }
    } else if (alertView.tag == tagWillDeleteVideo) {
        if (buttonIndex == 1) {
            [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            [self.answerVideoObj deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (!error) {
                    UIAlertView *successAlert = [[UIAlertView alloc] initWithTitle:@"Success" message:@"Video has ben deleted successfully" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
                    [successAlert show];
                    [PresenticeUtility navigateToMyLibraryFrom:self];
                } else {
                    [PresenticeUtility showErrorAlert:error];
                }
            }];
        }
    }
}

- (IBAction)rightMenuButtonPressed:(id)sender {
    if (![[[PFUser currentUser] objectId] isEqualToString:[[self.answerVideoObj objectForKey:kVideoUserKey] objectId]]) { // If currentUser is not the video's owner, navigate to TakeReview
        
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
        TakeReviewViewController *destViewController = [storyboard instantiateViewControllerWithIdentifier:@"takeReviewViewController"];
        
        destViewController.videoObj = self.answerVideoObj;
        [self.navigationController pushViewController:destViewController animated:YES];
    } else { // If currentUser is the video's owner, let her edit the video
        [PresenticeUtility callAlert:alertWillEditVideo withDelegate:self];

    }
}
@end
