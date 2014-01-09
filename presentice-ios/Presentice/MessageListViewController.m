//
//  MessageListViewController.m
//  Presentice
//
//  Created by レー フックダイ on 12/26/13.
//  Copyright (c) 2013 Appcoda. All rights reserved.
//

#import "MessageListViewController.h"

@interface MessageListViewController ()

@end

@implementation MessageListViewController {
//    NSMutableArray *messageList;
    AmazonS3Client *s3Client;
}

- (id)initWithCoder:(NSCoder *)aCoder {
    self = [super initWithCoder:aCoder];
    if (self) {
        // Custom the table
        
        // The className to query on
        self.parseClassName = kMessageClassKey;
        
        // The key of the PFObject to display in the label of the default cell style
        self.textKey = kCreatedAtKey;   // Need to be modified
        
        // Whether the built-in pull-to-refresh is enabled
        self.pullToRefreshEnabled = YES;
        
        // Whether the built-in pagination is enabled
        self.paginationEnabled = YES;
        
        // The number of objects to show per page
        self.objectsPerPage = 5;
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
    
    // Set the side bar button action. When it's tapped, it'll show up the sidebar.
    _sidebarButton.target = self.revealViewController;
    _sidebarButton.action = @selector(revealToggle:);
    
    // Set the gesture
    [self.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    // Set refreshTable notification
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshTable:)
                                                 name:@"refreshTable"
                                               object:nil];
}

/**
 * override function
 * load table for each time load view
 */
//- (void) viewWillAppear:(BOOL)animated {
//    messageList = [[NSMutableArray alloc] init];
//    [self queryMessageList];
//    [self.tableView reloadData];
//}

- (void)viewDidAppear:(BOOL)animated {
    // Hid all HUD after all objects appered
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (PFQuery *)queryForTable {
    PFQuery *messageListQuery = [PFQuery queryWithClassName:self.parseClassName];
//    PFQuery *questionListQuery = [PFUser query];
    // Now we don't have any algorithm about showing user list. Just show all users
    /**
     [questionListQuery includeKey:kVideoUserKey];   // Important: Include "user" key in this query make receiving user info easier
     [questionListQuery whereKey:kVideoTypeKey equalTo:@"question"];
     **/
    // If no objects are loaded in memory, we look to the cache first to fill the table
    // and then subsequently do a query against the network.
    if ([self.objects count] == 0) {
        messageListQuery.cachePolicy = kPFCachePolicyCacheThenNetwork;
    }
    [messageListQuery orderByAscending:kUpdatedAtKey];
    return messageListQuery;
}

#pragma table methods
/**
 * delegage method
 * number of rows of table
 */
//- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
//    return [messageList count];
//}

/**
 * delegate method
 * build table view
 */
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object {
    static NSString *fileListIdentifier = @"messageListIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:fileListIdentifier];
    
    cell.textLabel.text = [object objectForKey:@"content"];
    return cell;
}

- (void) objectsDidLoad:(NSError *)error {
    [super objectsDidLoad:error];
    NSLog(@"error: %@", [error localizedDescription]);
}

/**
 * segue for table cell
 * click to direct to video play view
 * pass video name, video url
 */
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
//    if ([segue.identifier isEqualToString:@"showQuestionDetail"]) {
//        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
//        QuestionViewController *destViewController = segue.destinationViewController;
//        destViewController.fileName = [questionList objectAtIndex:indexPath.row][@"fileName"];
//        destViewController.movieURL = [questionList objectAtIndex:indexPath.row][@"fileURL"];
//        destViewController.userName = [questionList objectAtIndex:indexPath.row][@"userName"];
//    }
}

@end
