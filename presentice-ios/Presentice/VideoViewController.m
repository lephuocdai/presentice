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
    NSMutableArray *actionList;
}

//@synthesize postedUserLabel;
//@synthesize fileNameLabel;
//@synthesize viewsNumLabel;
//@synthesize reviewsNumLabel;
@synthesize fileName;

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    actionList = [[NSMutableArray alloc] init];
    
    
    // Add queryReviews
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewWillAppear:(BOOL)animated {
}

- (void)viewDidAppear:(BOOL)animated {
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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(section == 0) {
        return 1;   // Only one video play
    } else {
        return 3;   // Video info has three row: videoName + postedUser + views/reviews
    }
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section == 0) {
        return 300;
    } else {
        return 50;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *videoTableCellIdentifier = @"videoTableCell";
    UITableViewCell *cell = (UITableViewCell*)[tableView dequeueReusableCellWithIdentifier:videoTableCellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:videoTableCellIdentifier ];
    }
    // Configure the cell...
    
    if (indexPath.section == 0) {
        self.movieController = [[MPMoviePlayerController alloc] init];
        [self.movieController setContentURL:self.movieURL];
        [self.movieController.view setFrame:CGRectMake(0, 0, 320, 300)];
        [cell.contentView addSubview:self.movieController.view];
        
        // Using the Movie Player Notifications
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayBackDidFinish:) name:MPMoviePlayerPlaybackDidFinishNotification object:self.movieController];
        
        self.movieController.controlStyle =  MPMovieControlStyleEmbedded;
        self.movieController.shouldAutoplay = YES;
        self.movieController.repeatMode = NO;
        [self.movieController prepareToPlay];
        
        [self.movieController play];
        
        // Send a notification to the device with channel contain video's userId
        PFPush *push = [[PFPush alloc] init];
        NSString *channelName = [[self.videoObj objectForKey:kVideoUserKey] objectId];
        [push setChannel:channelName];
        [push setMessage:[NSString stringWithFormat:@"Your video %@ has been viewed from %@!",[self.videoObj objectForKey:kVideoNameKey], [[PFUser currentUser] objectForKey:kUserDisplayNameKey]]];
        [push sendPushInBackground];
        
    } else {
        if (indexPath.row == 0) {
            cell.textLabel.text = [[self.videoObj objectForKey:kVideoUserKey] objectForKey:kUserDisplayNameKey];
        } else if (indexPath.row == 1) {
            cell.textLabel.text = [self.videoObj objectForKey:kVideoNameKey];
        } else {
            cell.textLabel.text = [NSString stringWithFormat:@"View: %@     Reviews: %d",[self.videoObj objectForKey:kVideoViewsKey],[[self.videoObj objectForKey:kVideoReviewsKey] count]];
        }
    }
    return cell;
}

/**
 * segue for table cell
 * click to direct to video review
 * pass video object
 */

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"toReviewView"]) {
        ReviewViewController *destViewController = segue.destinationViewController;
        destViewController.videoObj = self.videoObj;
    }
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

 */

@end
