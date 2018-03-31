//
//  SMChooseChannelsTableViewCell.m
//  Speind
//
//  Created by Sergey Butenko on 11/5/14.
//  Copyright (c) 2014 Speaking Mind. All rights reserved.
//

#import "SMChooseChannelsTableViewCell.h"

@interface SMChooseChannelsTableViewCell ()

@property (weak, nonatomic) IBOutlet UIImageView *selectedImageView;

@end

@implementation SMChooseChannelsTableViewCell

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    [self.selectedImageView setHighlighted:selected];
}

@end
