//
//  NSAttributedString+Speind.m
//  Speind
//
//  Created by Sergey Butenko on 4/28/15.
//  Copyright (c) 2015 Speaking Mind. All rights reserved.
//

#import "NSAttributedString+Speind.h"

@implementation NSAttributedString (Speind)

+ (instancetype)sm_progressStringWithProgress:(double)progress
{
    if (progress < 0) progress = 0;
    if (progress > 1) progress = 1;
    
    UIFont *boldFont = [UIFont fontWithName:@"HelveticaNeue-Bold" size:15.0];
    NSDictionary *progressAttributes = [NSDictionary dictionaryWithObject:boldFont forKey:NSFontAttributeName];
    NSString *progressString = [NSString stringWithFormat:@" %i%%", (int)(progress * 100)];
    NSAttributedString *progressAttributedString = [[NSAttributedString alloc] initWithString:progressString attributes:progressAttributes];
    
    NSMutableAttributedString *statusString = [[NSMutableAttributedString alloc] initWithString:LOC(@"Downloading")];
    [statusString appendAttributedString:progressAttributedString];
    
    return [statusString copy];
}

@end
