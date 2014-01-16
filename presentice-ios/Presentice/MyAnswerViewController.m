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

@synthesize questionVideoLabel;
@synthesize questionVideoPostedUserLabel;
@synthesize viewNumLabel;
@synthesize noteView;

- (id)initWithCoder:(NSCoder *)aCoder {
    self = [super initWithCoder:aCoder];
    if (self) {
        // Custom the table
        
        // The className to query on
        self.parseClassName = kReviewClassKey;
        
        // The key of the PFObject to display in the label of the default cell style
        self.textKey = kReviewCommentKey;
        
        // Whether the built-in pull-to-refresh is enabled
        self.pullToRefreshEnabled = YES;
        
        // Whether the built-in pagination is enabled
        self.paginationEnabled = YES;
        
        // The number of objects to show per page
        self.objectsPerPage = 5;
    }
    return self;
}

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
    
    // Start loading HUD
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    questionVideoLabel.text = [self.questionVideoObj objectForKey:kVideoNameKey];
    questionVideoPostedUserLabel.text = [self.questionPostedUser objectForKey:kUserDisplayNameKey];
    viewNumLabel.text = [NSString stringWithFormat:@"views: %@",[self.answerVideoObj objectForKey:kVideoViewsKey]];
    noteView.text = [self.answerVideoObj objectForKey:kVideoNoteKey];
    
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
    // Set up movieController
    self.movieController = [[MPMoviePlayerController alloc] init];
    [self.movieController setContentURL:self.movieURL];
    [self.movieController.view setFrame:CGRectMake(0, 0, 320, 380)];
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
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"refreshTable" object:nil];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (PFQuery *)queryForTable {
    PFQuery *reviewListQuery = [PFQuery queryWithClassName:self.parseClassName];
    [reviewListQuery includeKey:kReviewFromUserKey];   // Important: Include "fromUser" key in this query make receiving user info easier
    [reviewListQuery includeKey:kReviewToUserKey];
    [reviewListQuery includeKey:kReviewTargetVideoKey];
    [reviewListQuery whereKey:kReviewTargetVideoKey equalTo:self.answerVideoObj];
    
    // If no objects are loaded in memory, we look to the cache first to fill the table
    // and then subsequently do a query against the network.
    if ([self.objects count] == 0) {
        reviewListQuery.cachePolicy = kPFCachePolicyCacheThenNetwork;
    }
    [reviewListQuery orderByAscending:kUpdatedAtKey];
    return reviewListQuery;
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
/**
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 3;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if(section == 0) {
        return @"Answer Video View";
    } else if(section == 1) {
        return @"Answer Information";
    } else if (section == 2) {
        return  @"Comments";
    }
    return  nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(section == 0) {
        return 1;   // Only one video play
    } else if(section == 1) {
        return 2;   // video info has two row: videoname + video points
    } else {
        return [commentList count]; //number of comments
    }
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section == 0) {
        return 300;
    } else {
        return 120;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *videoTableCellIdentifier = @"videoTableCell";
    UITableViewCell *cell = (UITableViewCell*)[tableView dequeueReusableCellWithIdentifier:videoTableCellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:videoTableCellIdentifier ];
    }
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
    } else if(indexPath.section == 1){
        cell.textLabel.numberOfLines = 4;
        cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
        if(indexPath.row == 0){
            NSLog(@"section 1 videoObj = %@", self.videoObj);
            cell.textLabel.text = [NSString stringWithFormat:@"Question: %@\nAnswer Name: %@",
                                   [[self.videoObj objectForKey:kVideoAsAReplyTo] objectForKey:kVideoNameKey],
                                   self.fileName];
        } else {
            cell.textLabel.text = videoPointStr;
            NSLog(@"videoPointStr text = %@",cell.textLabel.text);
        }
    } else {
        cell.textLabel.text = [NSString stringWithFormat:@"%@ :\n%@",
                               [[[reviews objectAtIndex:indexPath.row] objectForKey:kReviewFromUserKey] objectForKey:kUserDisplayNameKey],
                               [[reviews objectAtIndex:indexPath.row] objectForKey:kReviewCommentKey]];
        cell.textLabel.numberOfLines = 2;
// These lines are related to UI design
        cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
        cell.textLabel.baselineAdjustment = UIBaselineAdjustmentAlignBaselines;
        cell.textLabel.textAlignment = NSTextAlignmentLeft;
        cell.textLabel.font=[UIFont boldSystemFontOfSize:22];
        cell.textLabel.textColor=[UIColor lightGrayColor];
//--------------------------------------
        NSLog(@"commentList text = %@",cell.textLabel.text);
    }
    return cell;
}
**/
 
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object {
    static NSString *simpleTableIdentifier = @"reviewListIdentifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
    }
    
    // Configure the cell
    UILabel *userName = (UILabel *)[cell viewWithTag:101];
    UILabel *pointDetail = (UILabel *)[cell viewWithTag:102];
    UILabel *pointSum = (UILabel *)[cell viewWithTag:103];
    UILabel *comment = (UILabel *)[cell viewWithTag:104];
    
    userName.text = [[object objectForKey:kReviewFromUserKey] objectForKey:kUserDisplayNameKey];
    
    NSMutableDictionary *points = [object objectForKey:kReviewContentKey];
    pointDetail.text = [NSString stringWithFormat:@"app: %@, org: %@, und: %@",
                        [points objectForKey:@"appearance"],
                        [points objectForKey:@"organization"],
                        [points objectForKey:@"understandability"]];
    
    pointSum.text = @"undefined";
    
    comment.text = [object objectForKey:kReviewCommentKey];
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
}

/**
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}

// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}

// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}

#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
**/

@end
