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
    NSString *videoPointStr;
    NSMutableArray *commentList;
    NSMutableArray *reviews;
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

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    reviews = [[NSMutableArray alloc] init];
    commentList = [[NSMutableArray alloc] init];
    
    [self queryReviews];
}

- (void) viewWillAppear:(BOOL)animated {
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated {

}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 3;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if(section == 0) {
        return @"Video View";
    } else if(section == 1) {
        return @"Video Information";
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
        cell.textLabel.numberOfLines = 3;
        cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
        if(indexPath.row == 0){
            cell.textLabel.text = [NSString stringWithFormat:@"Video Name: %@",self.fileName];
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

- (void)moviePlayBackDidFinish:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
}

- (void) viewWillDisappear:(BOOL)animated {
    //finish video when clicking back button
    if([self.navigationController.viewControllers indexOfObject:self] == NSNotFound){
        [self.movieController stop];
        [self.movieController.view removeFromSuperview];
        self.movieController = nil;
    }
}

#pragma Parse query

- (void) queryReviews {

    PFQuery *points = [PFQuery queryWithClassName:kReviewClassKey];
    [points includeKey:kReviewFromUserKey];
    [points whereKey:kReviewTargetVideoKey equalTo:self.videoObj];
    [points findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            int organizationPoint = 0;
            int understandPoint = 0;
            int appearancePoint = 0;
            
            //retrive each row of data to get video points
            for(int i = 0; i < [objects count]; i++){
                //review content
                NSDictionary *content = [objects[i] objectForKey:kReviewContentKey];
                organizationPoint = organizationPoint + [[content objectForKey:@"organization"] integerValue];
                understandPoint = understandPoint + [[content objectForKey:@"understandability"] integerValue];
                appearancePoint = appearancePoint + [[content objectForKey:@"appearance"] integerValue];
                
                //review comment
                // Add new file to fileList
                NSMutableDictionary *comment = [NSMutableDictionary dictionary];
                comment[@"comment_content"] = [objects[i] objectForKey:kReviewCommentKey];
                [commentList addObject:comment];
                
                // Add each review object to reviews array
                [reviews addObject:objects[i]];
            }
            //print video point to string
            videoPointStr = [NSString stringWithFormat:@"Organization: %d", organizationPoint];
            videoPointStr = [videoPointStr stringByAppendingFormat:@"\nUnderstandability: %d", understandPoint];
            videoPointStr = [videoPointStr stringByAppendingFormat:@"\nAppearance: %d", appearancePoint];
            
            //reload table data
            [self.tableView reloadData];
            
            NSLog(@"videoPointStr = %@", videoPointStr);
            
        } else {
            NSLog(@"error");
        }
    }];
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
