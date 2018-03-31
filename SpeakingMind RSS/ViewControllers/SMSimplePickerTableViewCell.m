//
//  SMSimplePickerTableViewCell.m
//  Speind
//
//  Created by Sergey Butenko on 2/25/15.
//  Copyright (c) 2015 Speaking Mind. All rights reserved.
//

#import "SMSimplePickerTableViewCell.h"

static const NSTimeInterval kAnimationDuration = 0.3;
static const int kCellSelectedOffset = 52; // 2 - left cell margin
static const int kCellUnselectedOffset = 20;

@interface SMSimplePickerTableViewCell ()

@end

@implementation SMSimplePickerTableViewCell

- (void)awakeFromNib
{
    _selectedIndicatorView.layer.cornerRadius = _selectedIndicatorView.frame.size.height/2;
    _selectedIndicatorView.layer.masksToBounds = YES;
    _selectedIndicatorView.layer.borderWidth = 0;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    [UIView animateWithDuration:kAnimationDuration animations:^{
        self.leftOffsetConstraint.constant = selected ? kCellSelectedOffset : kCellUnselectedOffset;
        for (UIView *view in self.subviews) {
            [view layoutIfNeeded];
        }
    }];
}

- (void)configureWithString:(NSString*)string
{
    self.titleLabel.text = string;
}

@end
