//
//  MyAnswerViewController.m
//  Presentice
//
//  Created by レー フックダイ on 12/24/13.
//  Copyright (c) 2013 Appcoda. All rights reserved.
//

#import "MyAnswerViewController.h"

NSString * videoPointStr;

@interface MyAnswerViewController ()

@end

@implementation MyAnswerViewController {
    NSMutableArray *commentList;
}

@synthesize fileName;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //init video info table
    self.videoInfoTable.dataSource = self;
    self.videoInfoTable.delegate = self;
}
- (void) viewWillAppear:(BOOL)animated {
    commentList = [[NSMutableArray alloc] init];
    [self queryPoint];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated {
    self.movieController = [[MPMoviePlayerController alloc] init];
    
    [self.movieController setContentURL:self.movieURL];
    [self.movieController.view setFrame:self.videoView.bounds];
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
    //finish video when clicking back button
    if([self.navigationController.viewControllers indexOfObject:self] == NSNotFound){
        [self.movieController stop];
        [self.movieController.view removeFromSuperview];
        self.movieController = nil;
    }
}

#pragma Parse query
/**
 * query points of video in Review table
 * output information to screen
 **/
- (void) queryPoint {
    PFQuery *points = [PFQuery queryWithClassName:kReviewClassKey];
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

            }
            
            //print video point to string
            videoPointStr = [NSString stringWithFormat:@"Organization: %d", organizationPoint];
            videoPointStr = [videoPointStr stringByAppendingFormat:@"\nUnderstandability: %d", understandPoint];
            videoPointStr = [videoPointStr stringByAppendingFormat:@"\nAppearance: %d", appearancePoint];
            
            //reload table data
            [self.videoInfoTable reloadData];
        } else {
            NSLog(@"error");
        }
    }];
}

#pragma UITableViewDelegate
/**
* table with 3 sections:
 1. video info
 2. comment list
*
**/
- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if(section == 0){
        return @"Video Information";
    } else if(section == 1){
        return  @"Comments";
    }
    return  nil;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(section == 0){
        return 2;   // video info has two row: videoname + video points
    } else if(section == 1){
        return [commentList count]; //number of comments
    }
    return 0;
}
- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 120;
}
- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *videoInfoCellIdentifier = @"videoInfoTableCell";
    VideoInfoCell *cell = (VideoInfoCell*)[tableView dequeueReusableCellWithIdentifier:videoInfoCellIdentifier];
    if (cell == nil) {
        cell = [[VideoInfoCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:videoInfoCellIdentifier];
    }
    if(indexPath.section == 0){
        if(indexPath.row == 0){
            cell.content.text = [NSString stringWithFormat:@"Video Name: %@",self.fileName];
        } else {
            cell.content.text = videoPointStr;
        }
    } else {
            cell.content.text = [commentList objectAtIndex:indexPath.row][@"comment_content"];
    }
    return cell;
}
@end
