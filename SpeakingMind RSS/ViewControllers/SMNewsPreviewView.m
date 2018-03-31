//
//  SMNewsPreviewView.m
//  SpeakingMind RSS
//
//  Created by Sergey Butenko on 06.06.14.
//  Copyright (c) 2014 serejahh inc. All rights reserved.
//

#import "SMNewsPreviewView.h"

@interface SMNewsPreviewView ()

@end

@implementation SMNewsPreviewView

- (void)setMask:(BOOL)mask
{
    _mask = mask;
    
    if (mask) {
        UIVisualEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
        UIVisualEffectView *visualEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        visualEffectView.frame = self.bounds;
        [_previewImageView addSubview:visualEffectView];
    }
    else {
        [_previewImageView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    }
}

- (id)debugQuickLookObject
{
    return _previewImageView;
}

@end
