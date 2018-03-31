//
//  SMInfopointVK.m
//  SpeakingMind RSS
//
//  Created by Sergey Butenko on 10/23/14.
//  Copyright (c) 2014 Speaking Mind. All rights reserved.
//

#import "SMInfopointVK.h"
#import "NSString+Language.h"

@implementation SMInfopointVK

- (NSString *)lang
{
    return [self.summary sm_langOfString];
}

- (NSString*)vocalizingTextWithPreviuosInfopoint:(SMInfopoint*)infopoint fullArticle:(BOOL)fullArticle
{
    if (fullArticle && self.fullArticle.length > 0) {
        return [NSString stringWithFormat:@"%@", self.fullArticle];
    }
    return self.textVocalizing;
}

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[self class]]) {
        SMInfopointVK *post = object;
        return [self.summary isEqualToString:post.summary];
    }
    return NO;
}

- (NSUInteger)hash
{
    return [self.summary hash];
}

- (UIImage *)sourceIcon
{
    return [UIImage imageNamed:@"icon_feed_vk"];
}

@end
