//
//  NSString+Language.m
//  SpeakingMind RSS
//
//  Created by Sergey Butenko on 10/6/14.
//  Copyright (c) 2014 Speaking Mind. All rights reserved.
//

#import "NSString+Language.h"

#define UNDEFINED_LANGUAGE @"und"

@implementation NSString (Language)

- (NSString*)sm_langOfString
{
    if ([self length] == 0) {
        return nil;
    }

    return (__bridge_transfer NSString*)CFStringTokenizerCopyBestStringLanguage((__bridge CFStringRef)self, CFRangeMake(0, self.length));
}

@end
