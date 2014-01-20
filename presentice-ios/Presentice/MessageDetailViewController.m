//
//  MessageDetailViewController.m
//  Presentice
//
//  Created by レー フックダイ on 12/26/13.
//  Copyright (c) 2013 Appcoda. All rights reserved.
//

#import "MessageDetailViewController.h"


@interface MessageDetailViewController ()

@property (nonatomic, strong) UITextField *commentTextField;

@end


@implementation MessageDetailViewController

@synthesize commentTextField;


#pragma mark - Initialization
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
        
        // The className to query on
        self.parseClassName = kMessageClassKey;
        
        // The key of the PFObject to display in the label of the default cell style
        self.textKey = kCreatedAtKey;   // Need to be modified
        
        // Whether the built-in pull-to-refresh is enabled
        self.pullToRefreshEnabled = YES;
        
        // Whether the built-in pagination is enabled
        self.paginationEnabled = NO;
        
        // The number of objects to show per page
        self.objectsPerPage = 5;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Set refreshTable notification
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshTable:)
                                                 name:@"refreshTable"
                                               object:nil];
    
    // Set table footer
    MessageFooterView *footerView = [[MessageFooterView alloc] initWithFrame:[MessageFooterView rectForView]];
    commentTextField = footerView.commentField;
    commentTextField.delegate = self;
    self.tableView.tableFooterView = footerView;
}

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

- (PFQuery *)queryForTable {
    PFQuery *messageListQuery = [PFQuery queryWithClassName:self.parseClassName];
    [messageListQuery includeKey:kMessageFromUserKey];
    [messageListQuery includeKey:kMessageToUserKey];
    [messageListQuery whereKey:kMessageUsersKey containsAllObjectsInArray:@[[PFUser currentUser], self.toUser]];
    
    // If no objects are loaded in memory, we look to the cache first to fill the table
    // and then subsequently do a query against the network.
    if ([self.objects count] == 0) {
        messageListQuery.cachePolicy = kPFCachePolicyCacheThenNetwork;
    }
    [messageListQuery orderByAscending:kUpdatedAtKey];
    return messageListQuery;
}
/**
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object {
    
    static NSString *cellIdentifier = @"chatCellIdentifier";
    UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    // Configure the cell
    UILabel *userLabel = (UILabel *)[cell viewWithTag:100];
    UILabel *timeLabel = (UILabel *)[cell viewWithTag:101];
    UITextView *textString = (UITextView *)[cell viewWithTag:102];
    
    userLabel.text = [[object objectForKey:@"fromUser"] objectForKey:kUserDisplayNameKey];
    
    NSDate *theDate = [object objectForKey:kCreatedAtKey];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateStyle:NSDateFormatterShortStyle];
    timeLabel.text = [formatter stringFromDate:theDate];
    
    textString.text = [object objectForKey:@"content"];
    
    return cell;
}
**/

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSLog(@"fuck section = %d", section);
    if (self.objects.count > 0) {
        NSLog(@"fuck 1 self.objects.count = %d", self.objects.count);
        NSInteger rows = [[[self.objects firstObject] objectForKey:kMessageContentKey] count];
        NSLog(@"fuck 2 rows = %d", rows);
        if (self.paginationEnabled && rows != 0)
            rows++;
        NSLog(@"fuck 3 rows = %d", rows);
        return rows;
    } else {
        NSLog(@"fuck 4 self.objects.count = %d", self.objects.count);
        return 0;
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"chatCellIdentifier";
    UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    if (self.objects.count > 0) {
        NSMutableArray *messages = [[self.objects firstObject] objectForKey:kMessageContentKey];
        NSMutableDictionary *message = [messages objectAtIndex:indexPath.row];
        
        // Configure the cell
        UILabel *userLabel = (UILabel *)[cell viewWithTag:100];
        UILabel *timeLabel = (UILabel *)[cell viewWithTag:101];
        UITextView *textString = (UITextView *)[cell viewWithTag:102];
        
        userLabel.text = [message objectForKey:@"userName"];
        
        NSDate *theDate = [message objectForKey:@"date"];
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateStyle:NSDateFormatterShortStyle];
        timeLabel.text = [formatter stringFromDate:theDate];
        
        textString.text = [message objectForKey:@"text"];
        
        return cell;
    } else {
        return cell;
    }
    
}


#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    NSString *trimmedComment = [textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (trimmedComment.length != 0) {
        
        PFObject *messageObj = [PFObject objectWithClassName:kMessageClassKey];
        NSMutableArray *messages = [[NSMutableArray alloc] init];
        
        if (self.objects.count > 0) {
            messageObj = [self.objects firstObject];
            if ([messageObj objectForKey:kMessageContentKey]) {
                for (NSDictionary *message in [messageObj objectForKey:kMessageContentKey]) {
                    [messages addObject:message];
                }
            }
        }
        
        NSMutableDictionary *newMessage = [[NSMutableDictionary alloc] init];
        [newMessage setObject:trimmedComment forKey:@"text"];
        [newMessage setObject:[[PFUser currentUser] objectId] forKey:@"userId"];
        [newMessage setObject:[[PFUser currentUser] objectForKey:kUserDisplayNameKey] forKey: @"userName"];
        [newMessage setObject:[NSDate date] forKey:@"date"];
        
        [messages addObject:newMessage];
        
        [messageObj setObject:messages forKey:kMessageContentKey];
        
        NSMutableArray *users = [[NSMutableArray alloc] initWithArray:@[[PFUser currentUser], self.toUser]];    // Add two users to the "users" field
        NSSortDescriptor *aSortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"objectId" ascending:YES];
        [users sortUsingDescriptors:[NSArray arrayWithObject:aSortDescriptor]];
        
        [messageObj setObject:users forKey:kMessageUsersKey];
        [messageObj setObject:[PFUser currentUser] forKey:kMessageFromUserKey];
        [messageObj setObject:self.toUser forKey:kMessageToUserKey];

        
        // Show HUD view
        [MBProgressHUD showHUDAddedTo:self.view.superview animated:YES];
        
        // If more than 5 seconds pass since we post a comment, stop waiting for the server to respond
        NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:5.0f target:self selector:@selector(handleCommentTimeout:) userInfo:@{@"comment": messageObj} repeats:NO];
        
        [messageObj saveEventually:^(BOOL succeeded, NSError *error) {
            [timer invalidate];
            
            if (error && error.code == kPFErrorObjectNotFound) {
//                [[PAPCache sharedCache] decrementCommentCountForPhoto:self.photo];
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Could not post comment", nil) message:NSLocalizedString(@"This photo is no longer available", nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
                [alert show];
                [self.navigationController popViewControllerAnimated:YES];
            }
            
            // Send a notification to the device with channel contain toUser's Id
            NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
            [params setObject:trimmedComment forKey:@"content"];
            [params setObject:[self.toUser objectId] forKey:@"toUser"];
            [params setObject:@"message" forKey:@"pushType"];
            [PFCloud callFunction:@"sendPushNotification" withParameters:params];
            
            [MBProgressHUD hideHUDForView:self.view.superview animated:YES];
            [self loadObjects];
        }];
    }
    [textField setText:@""];
    return [textField resignFirstResponder];
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

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [commentTextField resignFirstResponder];
}

@end
