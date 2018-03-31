//
//  SMChooseVoiceTableViewCell.m
//  SpeakingMind RSS
//
//  Created by Sergey Butenko on 11/4/14.
//  Copyright (c) 2014 Speaking Mind. All rights reserved.
//

#import "SMChooseVoiceTableViewCell.h"
#import "SMVoice.h"

static const NSTimeInterval kAnimationDuration = 0.3;
static const int kCellSelectedOffset = 62;
static const int kCellUnselectedOffset = 15;

@interface SMChooseVoiceTableViewCell ()

@property (weak, nonatomic) IBOutlet UILabel *languageLabel;
@property (weak, nonatomic) IBOutlet UIImageView *selectedIndicatorView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *leftOffsetConstraint;

@end

@implementation SMChooseVoiceTableViewCell

- (void)awakeFromNib {
    _selectedIndicatorView.layer.cornerRadius = _selectedIndicatorView.frame.size.height/2;
    _selectedIndicatorView.layer.masksToBounds = YES;
    _selectedIndicatorView.layer.borderWidth = 0;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    [UIView animateWithDuration:kAnimationDuration animations:^{
        self.leftOffsetConstraint.constant = selected ? kCellSelectedOffset : kCellUnselectedOffset;
        [self.titleLabel layoutIfNeeded];
        [self.selectedIndicatorView layoutIfNeeded];
    }];
}

- (void)configureWithVoice:(SMVoice*)voice
{
    [self setSelectionStyle:UITableViewCellSelectionStyleNone];
    self.titleLabel.text = voice.title;
    self.languageLabel.text = voice.lang;
}

@end
