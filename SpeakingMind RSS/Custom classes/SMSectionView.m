//
//  SMSectionView.m
//  Speind
//
//  Created by Sergey Butenko on 3/1/15.
//  Copyright (c) 2015 Speaking Mind. All rights reserved.
//

#import "SMSectionView.h"

static const int kLeftOffset = 18.0;

@interface SMSectionView ()

@property (nonatomic, readwrite) UILabel *titleLabel;

@end

@implementation SMSectionView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.accessibilityElementsHidden = YES;
        self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(kLeftOffset, 0, frame.size.width - kLeftOffset, frame.size.height)];
        self.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:13];
        self.titleLabel.textColor = SMDarkGrayColor;
        [self addSubview:self.titleLabel];
    }
    
    return self;
}

- (void)drawRect:(CGRect)rect
{
    [SMLightGrayColor setFill];
    UIRectFill(rect);
}

@end
