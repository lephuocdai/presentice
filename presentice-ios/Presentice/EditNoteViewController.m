//
//  EditNoteViewController.m
//  Presentice
//
//  Created by レー フックダイ on 1/29/14.
//  Copyright (c) 2014 Presentice. All rights reserved.
//

#import "EditNoteViewController.h"

@interface EditNoteViewController ()

@end

#define kOFFSET_FOR_KEYBOARD 280.0

@implementation EditNoteViewController {
    Boolean keyboardIsShowing;
    CGRect keyboardBounds;

}

@synthesize noteView;
@synthesize note;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    noteView.text = note;
    
    // Prevent other user from edit the note
    if (![[[self.videoObj objectForKey:kVideoUserKey] objectId] isEqualToString:[[PFUser currentUser] objectId]]) {
        noteView.editable = NO;
        self.navigationItem.rightBarButtonItem = nil;
    }
    
	// Do any additional setup after loading the view.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -
#pragma mark Keyboard Handling

- (void)keyboardWillShow:(NSNotification *)notification {
	NSDictionary *userInfo = [notification userInfo];
	NSValue *keyboardBoundsValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
	[keyboardBoundsValue getValue:&keyboardBounds];
	keyboardIsShowing = YES;
	[self resizeViewControllerToFitScreen];
}

- (void)keyboardWillHide:(NSNotification *)note {
	keyboardIsShowing = NO;
	keyboardBounds = CGRectMake(0, 0, 0, 0);
	[self resizeViewControllerToFitScreen];
}

- (void)resizeViewControllerToFitScreen {
	// Needs adjustment for portrait orientation!
	CGRect applicationFrame = [[UIScreen mainScreen] applicationFrame];
	CGRect frame = self.view.frame;
	frame.size.height = applicationFrame.size.height;
    
	if (keyboardIsShowing)
		frame.size.height -= keyboardBounds.size.height;
    
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationBeginsFromCurrentState:YES];
	[UIView setAnimationDuration:0.3f];
	self.view.frame = frame;
	[UIView commitAnimations];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (IBAction)save:(id)sender {
    UIAlertView *saveAlert = [[UIAlertView alloc] initWithTitle:@"Save Changes" message:@"Do you want to save this note?" delegate:self cancelButtonTitle:@"NO" otherButtonTitles:@"YES", nil];
    saveAlert.tag = 0;
    [saveAlert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 0) {
        if (buttonIndex == 1) {
            PFObject *editedVideo = [PFObject objectWithoutDataWithClassName:kVideoClassKey objectId:self.videoObj.objectId];
            [editedVideo setObject:self.noteView.text forKey:kVideoNoteKey];
            [editedVideo saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (!error) {
                    UIAlertView *successAlert = [[UIAlertView alloc] initWithTitle:@"Success" message:@"Note saved successfully" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
                    successAlert.tag = 1;
                    [successAlert show];
                } else {
                    [PresenticeUtility showErrorAlert:error];
                }
            }];
            
        }
    }
}

@end
