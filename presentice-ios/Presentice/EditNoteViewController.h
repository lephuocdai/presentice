//
//  EditNoteViewController.h
//  Presentice
//
//  Created by レー フックダイ on 1/29/14.
//  Copyright (c) 2014 Presentice. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import "Constants.h"
#import "MBProgressHUD.h"



@interface EditNoteViewController : UIViewController

@property (strong, nonatomic) IBOutlet UITextView *noteView;
@property NSString *note;
@property (strong, nonatomic) PFObject *videoObj;

- (IBAction)save:(id)sender;

@end
