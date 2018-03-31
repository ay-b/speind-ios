//
//  SMUsersFeedTableViewCell.m
//  SpeakingMind RSS
//
//  Created by Sergey Butenko on 08.07.14.
//  Copyright (c) 2014 serejahh inc. All rights reserved.
//

#import "SMUsersFeedTableViewCell.h"

@interface SMUsersFeedTableViewCell ()

@end

@implementation SMUsersFeedTableViewCell

@dynamic delegate;

+ (UINib*)nib
{
    return [UINib nibWithNibName:NSStringFromClass([self class]) bundle:nil];
}

- (IBAction)selectFeedButtonPressed
{
    BOOL isSelected = !_selectFeedButton.isSelected;
    _selectFeedButton.selected = isSelected;
    [self.delegate select:isSelected cell:self];
}

@end
