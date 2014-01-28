//
//  ReviewDetailViewController.m
//  Presentice
//
//  Created by レー フックダイ on 1/15/14.
//  Copyright (c) 2014 Presentice. All rights reserved.
//

#import "ReviewDetailViewController.h"

@interface ReviewDetailViewController ()

@end

@implementation ReviewDetailViewController {
    NSMutableArray *criteria;
}

@synthesize reviewerNameLabel;
@synthesize answerVideoNameLabel;
@synthesize answerVideoPosterUserNameLabel;
@synthesize commentView;

//@synthesize thankYouLabel;

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Start loading HUD
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    [PresenticeUtitily setImageView:self.userProfilePicture forUser:[self.reviewObject objectForKey:kActivityFromUserKey]];
    
    reviewerNameLabel.text = [[self.reviewObject objectForKey:kActivityFromUserKey] objectForKey:kUserDisplayNameKey];
    answerVideoNameLabel.text = [[self.reviewObject objectForKey:kActivityTargetVideoKey] objectForKey:kVideoNameKey];
    answerVideoPosterUserNameLabel.text = [[self.reviewObject objectForKey:kActivityToUserKey] objectForKey:kUserDisplayNameKey];
    UILabel *commentLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, 280, 200)];
    commentLabel.text = [self.reviewObject objectForKey:kActivityDescriptionKey];
    commentLabel.numberOfLines = 0;
    [commentLabel setTextAlignment:NSTextAlignmentLeft];
    [commentLabel setLineBreakMode:NSLineBreakByWordWrapping];
    [commentLabel sizeToFit];
    [commentView addSubview:commentLabel];
    
    NSLog(@"%@", commentView);
    criteria = [[NSMutableArray alloc] initWithArray:[[self.reviewObject objectForKey:kActivityContentKey] allKeys]];
    
    // Set tap gesture on user profile picture
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(actionHandleTapOnImageView)];
    [singleTap setNumberOfTapsRequired:1];
    self.userProfilePicture.userInteractionEnabled = YES;
    [self.userProfilePicture addGestureRecognizer:singleTap];
    
}

- (void)actionHandleTapOnImageView {
    UserProfileViewController *userProfileViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"userProfileViewController"];
    userProfileViewController.userObj = [self.reviewObject objectForKey:kActivityFromUserKey];
    [self.navigationController pushViewController:userProfileViewController animated:YES];
}


- (void)viewDidAppear:(BOOL)animated {
    // Hid all HUD after all objects appered
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [criteria count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"reviewContentIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    NSString *criteriumKey = [criteria objectAtIndex:indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"%@: %@",
                           criteriumKey,
                           [[self.reviewObject objectForKey:kActivityContentKey] objectForKey:criteriumKey]];
    return cell;
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
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath{
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

- (IBAction)sayThankyou:(id)sender {
}
@end
