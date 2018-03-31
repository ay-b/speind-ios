//
//  SMSwitch.m
//  Speind
//
//  Created by Sergey Butenko on 2/25/15.
//  Copyright (c) 2015 Speaking Mind. All rights reserved.
//

#import "SMSwitch.h"
#import <QuartzCore/QuartzCore.h>

static const int kSwitchSize = 16.0;

@implementation SMSwitch

- (void)awakeFromNib
{
    self.layer.cornerRadius = kSwitchSize;
    self.layer.masksToBounds = YES;
}

- (void)drawRect:(CGRect)rect
{
    self.onTintColor = SMBlueColor;
    self.tintColor = SMGrayColor;

    [SMGrayColor setFill];
    UIRectFill(rect);
}

@end
