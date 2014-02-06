//
//  QuestionListTableCell.h
//  Presentice
//
//  Created by レー フックダイ on 2/6/14.
//  Copyright (c) 2014 Presentice. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface QuestionListTableCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *userProfilePicture;
@property (weak, nonatomic) IBOutlet UILabel *postedUser;
@property (weak, nonatomic) IBOutlet UILabel *postedTime;
@property (weak, nonatomic) IBOutlet UILabel *videoName;
@property (weak, nonatomic) IBOutlet UILabel *viewsNum;

@end
