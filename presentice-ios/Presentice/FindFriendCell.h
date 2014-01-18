//
//  FindFriendCell.h
//  Presentice
//
//  Created by PhuongNQ on 1/18/14.
//  Copyright (c) 2014 Presentice. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

@interface FindFriendCell : UITableViewCell
@property (nonatomic, strong) PFUser *user;
@property (weak, nonatomic) IBOutlet UIImageView *profilePicture;
@property (weak, nonatomic) IBOutlet UILabel *facebookName;
@property (weak, nonatomic) IBOutlet UIButton *followBtn;

/**
 static method
 return height of cell
 **/
+ (CGFloat)heightForCell;
@end
