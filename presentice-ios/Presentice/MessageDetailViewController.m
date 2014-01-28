//
//  MessageDetailViewController.m
//  Presentice
//
//  Created by レー フックダイ on 12/26/13.
//  Copyright (c) 2013 Appcoda. All rights reserved.
//

#import "MessageDetailViewController.h"


@interface MessageDetailViewController ()

@end


@implementation MessageDetailViewController {
    NSString* kCurrentUser;
    NSString* kToUser;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    kCurrentUser = [[PFUser currentUser] objectForKey:kUserDisplayNameKey];
    kToUser = [self.toUser objectForKey:kUserDisplayNameKey];
    
    self.delegate = self;
    self.dataSource = self;
    [super viewDidLoad];
    
    [self.tabBarController.tabBar setHidden:YES];
    
    [[JSBubbleView appearance] setFont:[UIFont systemFontOfSize:16.0f]];
    
    self.title = kToUser;
    self.messageInputView.textView.placeHolder = @"New Message";
    self.sender = kCurrentUser;
    
    [self setBackgroundColor:[UIColor whiteColor]];
    
    self.messages = [[NSMutableArray alloc] init];
    
    NSArray *messages = [self.messageObj objectForKey:kMessageContentKey];
    for (NSDictionary *message in messages) {
        JSMessage *jsMessage = [[JSMessage alloc] initWithText:[message objectForKey:@"text"] sender:[message objectForKey:@"userName"] date:[message objectForKey:@"date"]];
        [self.messages addObject:jsMessage];
    }
    
    UIImage *currentUserImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[PresenticeUtitily facebookProfilePictureofUser:[PFUser currentUser]]]]];
    UIImage *toUserImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[PresenticeUtitily facebookProfilePictureofUser:self.toUser]]]];
    self.avatars = [[NSDictionary alloc] initWithObjectsAndKeys:
                    [JSAvatarImageFactory avatarImage:currentUserImage croppedToCircle:YES], kCurrentUser,
                    [JSAvatarImageFactory avatarImage:toUserImage croppedToCircle:YES], kToUser,
                    nil];
    NSLog(@"fuck come to messagedetail self.messages.count = %d", self.messages.count);
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.tabBarController.tabBar setHidden:NO];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.messages.count;
}

#pragma mark - Messages view delegate: REQUIRED

- (void)didSendMessage:(JSMessage *)message {
    if ((self.messages.count - 1) % 2) {
        [JSMessageSoundEffect playMessageSentSound];
    }
    else {
        [JSMessageSoundEffect playMessageReceivedSound];
        message.sender = kCurrentUser;
    }
    
    NSMutableArray *messages = [[NSMutableArray alloc] init];
    if (self.messages.count > 0) {
        if ([self.messageObj objectForKey:kMessageContentKey]) {
            for (NSDictionary *message in [self.messageObj objectForKey:kMessageContentKey]) {
                [messages addObject:message];
            }
        }
    }
    
    // Set messages content
    NSMutableDictionary *newMessage = [[NSMutableDictionary alloc] init];
    [newMessage setObject:message.text forKey:@"text"];
    [newMessage setObject:[[PFUser currentUser] objectId] forKey:@"userId"];
    [newMessage setObject:kCurrentUser forKey: @"userName"];
    [newMessage setObject:[NSDate date] forKey:@"date"];
    
    [messages addObject:newMessage];
    
    [self.messageObj setObject:messages forKey:kMessageContentKey];
    
    // Set ACL for messageObj
    PFACL *messageACL = [PFACL ACL];
    [messageACL setReadAccess:YES forUser:[PFUser currentUser]];
    [messageACL setReadAccess:YES forUser:self.toUser];
    [messageACL setWriteAccess:YES forUser:[PFUser currentUser]];
    [messageACL setWriteAccess:YES forUser:self.toUser];
    self.messageObj.ACL = messageACL;
    
    
    // Show HUD view
    [MBProgressHUD showHUDAddedTo:self.view.superview animated:YES];
    
    // If more than 5 seconds pass since we post a comment, stop waiting for the server to respond
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:5.0f target:self selector:@selector(handleCommentTimeout:) userInfo:@{@"comment": self.messageObj} repeats:NO];
    
    [self.messageObj saveEventually:^(BOOL succeeded, NSError *error) {
        [timer invalidate];
        
        if (error && error.code == kPFErrorObjectNotFound) {
            //                [[PAPCache sharedCache] decrementCommentCountForPhoto:self.photo];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Could not post comment", nil) message:NSLocalizedString(@"This photo is no longer available", nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
            [alert show];
            [self.navigationController popViewControllerAnimated:YES];
        }
        
        // Send a notification to the device with channel contain toUser's Id
        NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
        [params setObject:message.text forKey:@"content"];
        [params setObject:[self.toUser objectId] forKey:@"toUser"];
        [params setObject:@"message" forKey:@"pushType"];
        [PFCloud callFunction:@"sendPushNotification" withParameters:params];
        
        [MBProgressHUD hideHUDForView:self.view.superview animated:YES];
        [self.tableView reloadData];
    }];
    
    [self.messages addObject:message];
    
    [self finishSend];
    [self scrollToBottomAnimated:YES];
}

- (JSBubbleMessageType)messageTypeForRowAtIndexPath:(NSIndexPath *)indexPath {
    JSMessage *message = [self.messages objectAtIndex:indexPath.row];
    return ([message.sender isEqualToString:kToUser]) ? JSBubbleMessageTypeIncoming : JSBubbleMessageTypeOutgoing;
}

- (UIImageView *)bubbleImageViewWithType:(JSBubbleMessageType)type
                       forRowAtIndexPath:(NSIndexPath *)indexPath {
    JSMessage *message = [self.messages objectAtIndex:indexPath.row];
    if ([message.sender isEqualToString:kToUser]) {
        return [JSBubbleImageViewFactory bubbleImageViewForType:type
                                                          color:[UIColor js_bubbleLightGrayColor]];
    }
    
    return [JSBubbleImageViewFactory bubbleImageViewForType:type
                                                      color:[UIColor js_bubbleBlueColor]];
}

- (JSMessageInputViewStyle)inputViewStyle {
    return JSMessageInputViewStyleFlat;
}

#pragma mark - Messages view delegate: OPTIONAL

- (BOOL)shouldDisplayTimestampForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row % 3 == 0) {
        return YES;
    }
    return NO;
}

//
//  *** Implement to customize cell further
//
- (void)configureCell:(JSBubbleMessageCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    if ([cell messageType] == JSBubbleMessageTypeOutgoing) {
        cell.bubbleView.textView.textColor = [UIColor whiteColor];
        
        if ([cell.bubbleView.textView respondsToSelector:@selector(linkTextAttributes)]) {
            NSMutableDictionary *attrs = [cell.bubbleView.textView.linkTextAttributes mutableCopy];
            [attrs setValue:[UIColor blueColor] forKey:UITextAttributeTextColor];
            
            cell.bubbleView.textView.linkTextAttributes = attrs;
        }
    }
    
    if (cell.timestampLabel) {
        cell.timestampLabel.textColor = [UIColor lightGrayColor];
        cell.timestampLabel.shadowOffset = CGSizeZero;
    }
    
    if (cell.subtitleLabel) {
        cell.subtitleLabel.textColor = [UIColor lightGrayColor];
    }
}

//  *** Implement to use a custom send button
//
//  The button's frame is set automatically for you
//
//  - (UIButton *)sendButtonForInputView
//

//  *** Implement to prevent auto-scrolling when message is added
//
- (BOOL)shouldPreventScrollToBottomWhileUserScrolling
{
    return YES;
}

// *** Implemnt to enable/disable pan/tap todismiss keyboard
//
- (BOOL)allowsPanToDismissKeyboard
{
    return YES;
}

#pragma mark - Messages view data source: REQUIRED

- (JSMessage *)messageForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self.messages objectAtIndex:indexPath.row];
}

- (UIImageView *)avatarImageViewForRowAtIndexPath:(NSIndexPath *)indexPath sender:(NSString *)sender {
    UIImage *image = [self.avatars objectForKey:sender];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    if ([sender isEqualToString:kToUser]) {
        UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(actionHandleTapOnImageView)];
        [singleTap setNumberOfTapsRequired:1];
        imageView.userInteractionEnabled = YES;
        [imageView addGestureRecognizer:singleTap];
    }
    return imageView;
}

- (void)actionHandleTapOnImageView {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:[NSBundle mainBundle]];
    UserProfileViewController *userProfileViewController = [storyboard instantiateViewControllerWithIdentifier:@"userProfileViewController"];
    
    userProfileViewController.userObj = self.toUser;
    [self.navigationController pushViewController:userProfileViewController animated:YES];
}

@end
