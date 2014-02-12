//
//  WaitingListViewController.h
//  Presentice
//
//  Created by レー フックダイ on 2/13/14.
//  Copyright (c) 2014 Presentice. All rights reserved.
//

#import "PresenticeUtility.h"
#import <MessageUI/MessageUI.h>

@interface WaitingListViewController : UIViewController <MFMailComposeViewControllerDelegate>


@property (strong, nonatomic) IBOutlet UILabel *peopleWaitingLabel;


- (IBAction)showAbout:(id)sender;
- (IBAction)checkStatus:(id)sender;
- (IBAction)inquire:(id)sender;


@end
