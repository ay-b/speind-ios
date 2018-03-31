//
//  SMUsersFeedTableViewCell.h
//  SpeakingMind RSS
//
//  Created by Sergey Butenko on 08.07.14.
//  Copyright (c) 2014 serejahh inc. All rights reserved.
//

#import "SMTableViewCell.h"

#import <SWTableViewCell/SWTableViewCell.h>

@class SMUsersFeedTableViewCell;

@protocol SMUsersFeedTableViewCellDelegate <SWTableViewCellDelegate>

- (void)select:(BOOL)selected cell:(SMUsersFeedTableViewCell*)cell;

@end

@interface SMUsersFeedTableViewCell : SWTableViewCell

@property (weak, nonatomic) id<SMUsersFeedTableViewCellDelegate> delegate;

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIButton *selectFeedButton;

+ (UINib*)nib;
- (IBAction)selectFeedButtonPressed;

@end
