//
//  SMSettingsFeedTableViewCell.m
//  SpeakingMind RSS
//
//  Created by Sergey Butenko on 26.06.14.
//  Copyright (c) 2014 serejahh inc. All rights reserved.
//

#import "SMSettingsFeedTableViewCell.h"
#import "SMDatabase.h"
#import "SMFeedTreeNode.h"

static const int kDefaultOffsetSize = 5;
static const int kDepthLevelOffsetSize = 20;

@interface SMSettingsFeedTableViewCell ()
{
    NSMutableArray *queueUpdating;
}

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *leftOffsetConstraint;

@end

@implementation SMSettingsFeedTableViewCell

- (void)configureCellWithData:(SMFeedTreeNode*)data
{
    _data = data;
    
    self.titleLabel.text = data.name;
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    if (data.feed) {
        self.selectFeedButton.selected = data.feed.isSelected;
    }
    else {
        self.selectFeedButton.selected = data.isSelected;
    }
}

- (void)moveInputViewWithDepth:(NSInteger)depthLevel
{
    self.leftOffsetConstraint.constant = kDefaultOffsetSize + depthLevel * kDepthLevelOffsetSize;
    [self.selectFeedButton layoutIfNeeded];
}

#pragma mark - Selection feeds

- (IBAction)selectFeedButtonPressed:(id)sender
{
    BOOL isSelected = !_data.isSelected;
    _data.selected = isSelected;

    // update children
    queueUpdating = [NSMutableArray array];
    if (!_data.children) {
        [queueUpdating addObject:_data.feed];
    }
    else if (!isSelected) { // for true "selected" should NOT call else block!
        [self select:isSelected feedItems:_data.children];
    }
    
    [SMDatabase setSelected:isSelected feeds:queueUpdating];
    queueUpdating = nil;
    
    [self.delegate childrenForCellDidUpdated:self];
}

- (void)select:(BOOL)selected feedItems:(NSArray*)items
{
    if (!items) {
        return;
    }
    
    for (SMFeedTreeNode *data in items) {
        data.selected = selected;
        
        if (data.feed) {
            [queueUpdating addObject:data.feed];
        }
        [self select:selected feedItems:data.children];
    }
}

@end
