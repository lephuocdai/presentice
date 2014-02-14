//
//  MyListViewController.m
//  Presentice
//
//  Created by レー フックダイ on 12/31/13.
//  Copyright (c) 2013 Presentice. All rights reserved.
//

#import "MyListViewController.h"

@interface MyListViewController ()

@end

@implementation MyListViewController {
    AmazonS3Client *s3Client;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aCoder {
    self = [super initWithCoder:aCoder];
    if (self) {
        // Custom the table
        self.parseClassName = kVideoClassKey;
        self.textKey = kVideoURLKey;
        self.pullToRefreshEnabled = YES;
        self.paginationEnabled = YES;
        self.objectsPerPage = 5;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Start loading HUD
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    // Set refreshTable notification
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshTable:)
                                                 name:@"refreshTable"
                                               object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:YES];
    
    // Hid all HUD after all objects appered
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    
    [PresenticeUtility checkCurrentUserActivationIn:self];
}

- (PFQuery *)queryForTable {
    PFQuery *myListQuery = [PFQuery queryWithClassName:self.parseClassName];
    [myListQuery whereKey:kVideoUserKey equalTo:[PFUser currentUser]];
    [myListQuery includeKey:kVideoUserKey];
    [myListQuery includeKey:kVideoReviewsKey];
    [myListQuery includeKey:kVideoAsAReplyTo];
    [myListQuery includeKey:kVideoToUserKey];
    
    // If no objects are loaded in memory, we look to the cache first to fill the table
    // and then subsequently do a query against the network.
    if ([self.objects count] == 0) {
        myListQuery.cachePolicy = kPFCachePolicyCacheThenNetwork;
    }
    
    [myListQuery orderByAscending:kVideoViewsKey];
    return myListQuery;
}

// Override to customize the look of a cell representing an object. The default is to display
// a UITableViewCellStyleDefault style cell with the label being the first key in the object.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object {
    static NSString *simpleTableIdentifier = @"myListIdentifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
    }
    
    // Configure the cell
    UILabel *videoName = (UILabel *)[cell viewWithTag:100];
    UILabel *postedTime = (UILabel *)[cell viewWithTag:101];
    UILabel *reviews_answersNum = (UILabel *)[cell viewWithTag:102];
    UILabel *viewsNum = (UILabel *)[cell viewWithTag:103];
    UILabel *visibility = (UILabel *)[cell viewWithTag:104];
    
    if ([[object objectForKey:kVideoTypeKey] isEqualToString:@"answer"]) {
        reviews_answersNum.text = [NSString stringWithFormat:NSLocalizedString(@"Reviews: %d", nil) , [[object objectForKey:kVideoReviewsKey] count]];
    } else if ([[object objectForKey:kVideoTypeKey] isEqualToString:@"question"]) {
        [PresenticeUtility setLabel:reviews_answersNum withKey:kVideoAnswersKey forObject:object];
    }
    
    videoName.text = [PresenticeUtility nameOfVideo:object];
    
    postedTime.text = [NSString stringWithFormat:@"%@", [[[NSDate alloc] initWithTimeInterval:0 sinceDate:object.createdAt] dateTimeUntilNow]];
    [PresenticeUtility setLabel:viewsNum withKey:kVideoViewsKey forObject:object];
    visibility.text = [PresenticeUtility visibilityOfVideo:object];
    return cell;
}

- (void) objectsDidLoad:(NSError *)error {
    [super objectsDidLoad:error];
    NSLog(@"error: %@", [error localizedDescription]);
    // Hid all HUD after all objects appered
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
    if (indexPath.row < self.objects.count) {
        
        [PresenticeUtility navigateToVideoView:[self.objects objectAtIndex:indexPath.row] from:self];

        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    } else {
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    }
}

- (IBAction)showLeftMenu:(id)sender {
    [self.menuContainerViewController toggleLeftSideMenuCompletion:nil];
}

- (IBAction)showRightMenu:(id)sender {
    [self.menuContainerViewController toggleRightSideMenuCompletion:nil];
}
@end
