//
//  SMSettingsFeedTableViewCell.h
//  SpeakingMind RSS
//
//  Created by Sergey Butenko on 26.06.14.
//  Copyright (c) 2014 serejahh inc. All rights reserved.
//

#import "SMTableViewCell.h"

@class SMSettingsFeedTableViewCell, SMFeedTreeNode;

@protocol SMSettingsFeedTableViewCellDelegate <NSObject>

- (void)childrenForCellDidUpdated:(SMSettingsFeedTableViewCell*)cell;

@end

@interface SMSettingsFeedTableViewCell : SMTableViewCell

- (void)configureCellWithData:(SMFeedTreeNode*)data;
- (void)moveInputViewWithDepth:(NSInteger)depthLevel;

@property (nonatomic) SMFeedTreeNode *data;
@property id<SMSettingsFeedTableViewCellDelegate> delegate;

@property (weak, nonatomic) IBOutlet UIButton *selectFeedButton;
@property (weak, nonatomic) IBOutlet UIImageView *expandImageView;

- (IBAction)selectFeedButtonPressed:(id)sender;

@end
