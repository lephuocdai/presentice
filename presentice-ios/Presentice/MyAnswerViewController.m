//
//  MyAnswerViewController.m
//  Presentice
//
//  Created by レー フックダイ on 1/6/14.
//  Copyright (c) 2014 Presentice. All rights reserved.
//

#import "MyAnswerViewController.h"

@interface MyAnswerViewController ()

@end

@implementation MyAnswerViewController {
}

- (id)initWithCoder:(NSCoder *)aCoder {
    self = [super initWithCoder:aCoder];
    if (self) {
        // Custom the table
        
        // The className to query on
        self.parseClassName = kActivityClassKey;
        
        // The key of the PFObject to display in the label of the default cell style
        self.textKey = kActivityDescriptionKey;
        
        // Whether the built-in pull-to-refresh is enabled
        self.pullToRefreshEnabled = YES;
        
        // Whether the built-in pagination is enabled
        self.paginationEnabled = YES;
        
        // The number of objects to show per page
        self.objectsPerPage = 5;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Start loading HUD
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    self.videoNameLabel.text = [PresenticeUtility nameOfVideo:self.answerVideoObj];
    self.viewNumLabel.text = [PresenticeUtility stringNumberOfKey:kVideoViewsKey inObject:self.answerVideoObj];
    self.visibilityLabel.text = [PresenticeUtility visibilityOfVideo:self.answerVideoObj];
    
    self.noteView.text = [NSString stringWithFormat:@"Note for viewer: \n%@",[self.answerVideoObj objectForKey:kVideoNoteKey]];
    [self.noteView boldSubstring:@"Note for viewer:"];
    
    // Set tap gesture on noteview
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(actionHandleTapOnNoteView)];
    [singleTap setNumberOfTapsRequired:1];
    self.noteView.userInteractionEnabled = YES;
    [self.noteView addGestureRecognizer:singleTap];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    // Set refreshTable notification
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshTable:)
                                                 name:@"refreshTable"
                                               object:nil];
}

- (void) viewWillAppear:(BOOL)animated {
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    self.movieController.controlStyle =  MPMovieControlStyleEmbedded;
    self.movieController.shouldAutoplay = YES;
    self.movieController.repeatMode = NO;
    [self.movieController prepareToPlay];
    [self.movieController play];
    
    // Hid all HUD after all objects appered
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
}

- (void)refreshTable:(NSNotification *) notification {
    // Reload the recipes
    [self loadObjects];
    self.noteView.text = [NSString stringWithFormat:@"Note for viewer: \n%@",[self.answerVideoObj objectForKey:kVideoNoteKey]];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"refreshTable" object:nil];
}

- (PFQuery *)queryForTable {
    PFQuery *reviewListQuery = [PFQuery queryWithClassName:self.parseClassName];
    [reviewListQuery includeKey:kActivityFromUserKey];   // Important: Include "fromUser" key in this query make receiving user info easier
    [reviewListQuery includeKey:kActivityToUserKey];
    [reviewListQuery includeKey:kActivityTargetVideoKey];
    [reviewListQuery whereKey:kActivityTypeKey equalTo:@"review"];
    [reviewListQuery whereKey:kActivityTargetVideoKey equalTo:self.answerVideoObj];
    
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

#pragma mark - Table view data source
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return @"Reviews of this video";
    } else {
        return @"";
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
    UILabel *pointDetail = (UILabel *)[cell viewWithTag:102];
    UILabel *pointSum = (UILabel *)[cell viewWithTag:103];
    UILabel *comment = (UILabel *)[cell viewWithTag:104];
    
    userProfilePicture.image = [UIImage imageWithData:
                                [NSData dataWithContentsOfURL:
                                 [NSURL URLWithString:
                                  [PresenticeUtility facebookProfilePictureofUser:
                                   [object objectForKey:kActivityFromUserKey]]]]];
    
    userProfilePicture.layer.cornerRadius = userProfilePicture.frame.size.width / 2;
    userProfilePicture.layer.masksToBounds = YES;
    
    userName.text = [[object objectForKey:kActivityFromUserKey] objectForKey:kUserDisplayNameKey];
    
    NSMutableDictionary *points = [object objectForKey:kActivityContentKey];
    pointDetail.text = [NSString stringWithFormat:@"app: %@, org: %@, und: %@",
                        [points objectForKey:@"appearance"],
                        [points objectForKey:@"organization"],
                        [points objectForKey:@"understandability"]];
    
    pointSum.text = @"undefined";
    
    comment.text = [object objectForKey:kActivityDescriptionKey];
    return cell;
}

- (void) objectsDidLoad:(NSError *)error {
    [super objectsDidLoad:error];
    NSLog(@"error: %@", [error localizedDescription]);
}

/**
 * segue for table cell
 * click to direct to video review
 * pass video object
 */

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showReviewDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        ReviewDetailViewController *destViewController = segue.destinationViewController;
        PFObject *object = [self.objects objectAtIndex:indexPath.row];
        NSLog(@"sent object = %@", object);
        destViewController.reviewObject = object;
    }
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}

- (IBAction)editVideoInfo:(id)sender {
    UIAlertView *editAlert = [[UIAlertView alloc] initWithTitle:@"Edit Video Information" message:@"Which information do you want to edit" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Note for viewer", @"Visibility status",nil];
    editAlert.tag = 0;
    [editAlert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 0) {
        if (buttonIndex == 1) {
            EditNoteViewController *editNoteViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"editNoteViewController"];
            editNoteViewController.note = [self.answerVideoObj objectForKey:kVideoNoteKey];
            editNoteViewController.videoObj = self.answerVideoObj;
            
            [self.navigationController pushViewController:editNoteViewController animated:YES];
        } else if (buttonIndex == 2) {
            UIAlertView *visibilityEditAlert = [[UIAlertView alloc] initWithTitle:@"Visibility Selection" message:@"Decide who can view this video" delegate:self cancelButtonTitle:@"Open inside Presentice" otherButtonTitles:@"Only friends who are following me", @"Only Me", nil];
            visibilityEditAlert.tag = 2;
            [visibilityEditAlert show];
        }
    } else if (alertView.tag == 1) {
        if (buttonIndex == 1) {
            EditNoteViewController *editNoteViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"editNoteViewController"];
            editNoteViewController.note = [self.answerVideoObj objectForKey:kVideoNoteKey];
            editNoteViewController.videoObj = self.answerVideoObj;
            
            [self.navigationController pushViewController:editNoteViewController animated:YES];
        }
    } else if (alertView.tag == 2) {
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
                    UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Something went wrong. Please contact us at: info@presentice.com" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
                    [errorAlert show];
                }
            }];
        }
    }
}

- (void)actionHandleTapOnNoteView {
    UIAlertView *noteDisplayAlert = [[UIAlertView alloc] initWithTitle:@"Fully display note" message:@"Do you want to view this note fully" delegate:self cancelButtonTitle:@"No, it's ok" otherButtonTitles:@"Yes, show me", nil];
    noteDisplayAlert.tag = 1;
    [noteDisplayAlert show];
}

@end
