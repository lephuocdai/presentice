//
//  FindFriendCell.h
//  Presentice
//
//  Created by PhuongNQ on 1/18/14.
//  Copyright (c) 2014 Presentice. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
@class FindFriendCell;
@protocol FindFriendCellDelegate;
@interface FindFriendCell : UITableViewCell {
    id _delegate;
}
@property (nonatomic, strong) id<FindFriendCellDelegate> delegate;

@property (nonatomic, strong) PFUser *user;
@property (nonatomic, strong) IBOutlet UIImageView *profilePicture;
@property (nonatomic, strong) IBOutlet UILabel *facebookName;
@property (nonatomic, strong) IBOutlet UIButton *followBtn;
/*! Setters for the cell's content */
- (void)setUser:(PFUser *)user;

- (void)didTapFollowButtonAction:(id)sender;

/**
 static method
 return height of cell
 **/
+ (CGFloat)heightForCell;
@end

/*!
 The protocol defines methods a delegate of a PAPBaseTextCell should implement.
 */
@protocol FindFriendCellDelegate <NSObject>
@optional

/*!
 Sent to the delegate when a user button is tapped
 @param aUser the PFUser of the user that was tapped
 */
- (void)cell:(FindFriendCell *)cellView didTapFollowButton:(PFUser *)aUser;
@end
