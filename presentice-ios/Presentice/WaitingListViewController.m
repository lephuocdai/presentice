//
//  WaitingListViewController.m
//  Presentice
//
//  Created by レー フックダイ on 2/13/14.
//  Copyright (c) 2014 Presentice. All rights reserved.
//

#import "WaitingListViewController.h"

@interface WaitingListViewController ()

@end

@implementation WaitingListViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    //hide navigator if in waiting list
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [super viewWillAppear:animated];
}

- (void)viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    // Start loading HUD
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
//    [self.navigationController.navigationBar setHidden:YES];
    [self.tabBarController.tabBar setHidden:YES];
    
    PFQuery *countInactivatedUser = [PFQuery queryWithClassName:kPromotionClassKey];
    [countInactivatedUser whereKey:@"activated" equalTo:[NSNumber numberWithBool:NO]];
    [countInactivatedUser countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
        self.peopleWaitingLabel.text = [NSString stringWithFormat:@"%d", number];
        // Hid all HUD after all objects appered
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    }];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)showAbout:(id)sender {
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    UIViewController *webViewController = [[UIViewController alloc] init];
    
    UIWebView *uiWebView = [[UIWebView alloc] initWithFrame: CGRectMake(0,0,self.view.frame.size.width, self.view.frame.size.height)];
    NSURL *aboutURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.presentice.com/"]];
    [uiWebView loadRequest:[NSURLRequest requestWithURL:aboutURL]];
    [webViewController.view addSubview:uiWebView];
    [self.navigationController pushViewController:webViewController animated:YES];
}

- (IBAction)checkStatus:(id)sender {
    if ([[[[PFUser currentUser] objectForKey:kUserPromotionKey] fetchIfNeeded] objectForKey:kPromotionActivatedKey] == nil || [[[[[PFUser currentUser] objectForKey:kUserPromotionKey] fetchIfNeeded] objectForKey:kPromotionActivatedKey] boolValue] == false) {
        
        [PresenticeUtility callAlert:alertDidDenyAction withDelegate:nil];
    }
}

- (IBAction)inquire:(id)sender {
    [PresenticeUtility callAlert:alertWillInquire withDelegate:self];
}

- (void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex  {
    if (alertView.tag == tagWillInquire) {
        if (buttonIndex == 1) {
            // Email Subject
            NSString *emailTitle = [NSString stringWithFormat:NSLocalizedString(@"[%@]Inquiry", nil), [[PFUser currentUser] objectId]];
            // Email Content
            NSString *messageBody = NSLocalizedString(@"Hi there, I have an inquiry.",nil);
            // To address
            NSArray *toRecipents = [NSArray arrayWithObject:@"info@presentice.com"];
            
            MFMailComposeViewController *mc = [[MFMailComposeViewController alloc] init];
            mc.mailComposeDelegate = self;
            [mc setSubject:emailTitle];
            [mc setMessageBody:messageBody isHTML:NO];
            [mc setToRecipients:toRecipents];
            
            // Present mail view controller on screen
            [self presentViewController:mc animated:YES completion:NULL];
        }
    }
}

- (void) mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    switch (result) {
        case MFMailComposeResultCancelled:
            NSLog(@"Mail cancelled");
            break;
        case MFMailComposeResultSaved:
            NSLog(@"Mail saved");
            break;
        case MFMailComposeResultSent:
            NSLog(@"Mail sent");
            break;
        case MFMailComposeResultFailed:
            NSLog(@"Mail sent failure: %@", [error localizedDescription]);
            break;
        default:
            break;
    }
    
    // Close the Mail Interface
    [self dismissViewControllerAnimated:YES completion:NULL];
}


@end
