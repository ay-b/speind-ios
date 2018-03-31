//
//  SMSimplePickerTableViewCell.h
//  Speind
//
//  Created by Sergey Butenko on 2/25/15.
//  Copyright (c) 2015 Speaking Mind. All rights reserved.
//

#import "SMTableViewCell.h"

@interface SMSimplePickerTableViewCell : SMTableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *selectedIndicatorView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *leftOffsetConstraint;

/**
 * For simple cell: string is a string without space.
 * For details: string separates by space. Left part - title, right part - value.
 */
- (void)configureWithString:(NSString*)string;

@end
