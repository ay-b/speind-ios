//
//  SMRoundedImageView.m
//  Speind
//
//  Created by Sergey Butenko on 4/14/15.
//  Copyright (c) 2015 Speaking Mind. All rights reserved.
//

#import "SMRoundedImageView.h"

@implementation SMRoundedImageView

- (void)setImage:(UIImage *)image
{
    [super setImage:image];
    [self setRounded];
}

- (void)setRounded
{
    self.layer.cornerRadius = self.frame.size.width/2;
    self.layer.borderColor = SMGrayColor.CGColor;
    self.layer.borderWidth = 1.0;
    self.layer.masksToBounds = YES;
    self.clipsToBounds = YES;
}

@end
