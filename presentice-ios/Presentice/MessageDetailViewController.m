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
        self.paginationEnabled = YES;
        
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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (PFQuery *)queryForTable {
    PFQuery *messageListQuery = [PFQuery queryWithClassName:self.parseClassName];
    [messageListQuery includeKey:@"fromUser"];
    [messageListQuery whereKey:@"users" containsAllObjectsInArray:@[[PFUser currentUser], self.toUser]];
    
    // If no objects are loaded in memory, we look to the cache first to fill the table
    // and then subsequently do a query against the network.
    if ([self.objects count] == 0) {
        messageListQuery.cachePolicy = kPFCachePolicyCacheThenNetwork;
    }
    [messageListQuery orderByAscending:kUpdatedAtKey];
    return messageListQuery;
}

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
    
//    NSString *chatText = [[self.objects objectAtIndex:indexPath.row] objectForKey:@"content"];
//    self.userLabel.text = [[[[self.objects objectAtIndex:indexPath.row] objectForKey:@"users"] firstObject] objectId];
//    self.timeLabel.text = [[self.objects objectAtIndex:indexPath.row] objectForKey:kCreatedAtKey];
//    
//    cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
//    UIFont *font = [UIFont systemFontOfSize:14];
//    CGSize size = [chatText sizeWithFont:font constrainedToSize:CGSizeMake(225.0f, 1000.0f) lineBreakMode:NSLineBreakByCharWrapping];
//    cell.textString.frame = CGRectMake(75, 14, size.width +20, size.height + 20);
//    cell.textString.font = [UIFont fontWithName:@"Helvetica" size:14.0];
//    cell.textString.text = chatText;
    
    return cell;
    
    
//     static NSString *fileListIdentifier = @"chatCellIdentifier";
//     UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:fileListIdentifier];
//    
//     cell.textLabel.text = [[self.objects objectAtIndex:indexPath.row] objectForKey:@"content"];
//     return cell;
    
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    NSString *trimmedComment = [textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (trimmedComment.length != 0) {
        PFObject *message = [PFObject objectWithClassName:kMessageClassKey];
        [message setObject:trimmedComment forKey:@"content"]; // Set comment text
        NSMutableArray *users = [[NSMutableArray alloc] initWithArray:@[[PFUser currentUser], self.toUser]];    // Add two users to the "users" field
        [message setObject:users forKey:@"users"];
        [message setObject:[PFUser currentUser] forKey:@"fromUser"];
        // Show HUD view
        [MBProgressHUD showHUDAddedTo:self.view.superview animated:YES];
        
        // If more than 5 seconds pass since we post a comment, stop waiting for the server to respond
        NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:5.0f target:self selector:@selector(handleCommentTimeout:) userInfo:@{@"comment": message} repeats:NO];
        
        [message saveEventually:^(BOOL succeeded, NSError *error) {
            [timer invalidate];
            
            if (error && error.code == kPFErrorObjectNotFound) {
//                [[PAPCache sharedCache] decrementCommentCountForPhoto:self.photo];
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Could not post comment", nil) message:NSLocalizedString(@"This photo is no longer available", nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
                [alert show];
                [self.navigationController popViewControllerAnimated:YES];
            }
            
            // Send a notification to the device with channel contain toUser's Id
            PFPush *push = [[PFPush alloc] init];
            NSString *channelName = [self.toUser objectId];
            [push setChannel:channelName];
            [push setMessage:[NSString stringWithFormat:@"%@ sent you a message: %@",[[PFUser currentUser] objectForKey:kUserDisplayNameKey], trimmedComment]];
            [push sendPushInBackground];
            
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
