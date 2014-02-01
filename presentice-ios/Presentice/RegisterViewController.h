//
//  RegisterViewController.h
//  Presentice
//
//  Created by PhuongNQ on 12/23/13.
//  Copyright (c) 2013 Appcoda. All rights reserved.
//

#import "quickdialog/QuickDialog.h"
#import "PresenticeUtility.h"

#import "RegisterInfo.h"

#import "LoginViewController.h"
#import "Validate.h"


@interface RegisterViewController : QuickDialogController <QuickDialogEntryElementDelegate> {
    
}

@property NSString *email;


@end
