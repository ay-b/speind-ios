//
//  SMDetailPickerTableViewCell.m
//  Speind
//
//  Created by Sergey Butenko on 2/25/15.
//  Copyright (c) 2015 Speaking Mind. All rights reserved.
//

#import "SMDetailPickerTableViewCell.h"

@implementation SMDetailPickerTableViewCell

- (void)configureWithString:(NSString*)string
{
    NSArray *titleComponenets = [string componentsSeparatedByString:@" "];
    self.valueLabel.text = titleComponenets[0];
    self.titleLabel.text = titleComponenets[1];
}

@end
