//
//  FindFriendCell.m
//  Presentice
//
//  Created by PhuongNQ on 1/18/14.
//  Copyright (c) 2014 Presentice. All rights reserved.
//

#import "FindFriendCell.h"

@implementation FindFriendCell
@synthesize followBtn;
@synthesize facebookName;
@synthesize profilePicture;
@synthesize user;
@synthesize delegate;

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if(self){

    }
    return self;
}
-(void)layoutSubviews
{

    [self.followBtn setTitle:NSLocalizedString(@"Follow",nil) forState:UIControlStateNormal]; // space added for centering
    [self.followBtn setTitle:NSLocalizedString(@"Following",nil) forState:UIControlStateSelected];
    [self.followBtn addTarget:self action:@selector(didTapFollowButtonAction:) forControlEvents:UIControlEventTouchUpInside];

}
- (void)setUser:(PFUser *)aUser {
    user = aUser;
}
- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}
+ (CGFloat)heightForCell {
    return 67.0f;
}
/* Inform delegate that the follow button was tapped */
- (void)didTapFollowButtonAction:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(cell:didTapFollowButton:)]) {
        NSLog(@"self.delegate");
        [self.delegate cell:self didTapFollowButton:self.user];
    }
}
@end
