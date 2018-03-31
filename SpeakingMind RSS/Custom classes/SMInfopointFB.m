//
//  SMInfopointFB.m
//  Speind
//
//  Created by Sergey Butenko on 3/7/15.
//  Copyright (c) 2015 Speaking Mind. All rights reserved.
//

#import "SMInfopointFB.h"
#import "NSString+Language.h"

@implementation SMInfopointFB

@synthesize placeholder = _placeholder;

- (NSString *)placeholder
{
    if (!_placeholder) {
        _placeholder = @"placeholder_music";
    }
    return _placeholder;
}

- (NSString *)lang
{
    return [self.summary sm_langOfString];
}


- (NSString*)vocalizingTextWithPreviuosInfopoint:(SMInfopoint*)infopoint fullArticle:(BOOL)fullArticle
{
    return self.textVocalizing;
}

- (NSString *)description
{
    return [self summary];
}

@end
