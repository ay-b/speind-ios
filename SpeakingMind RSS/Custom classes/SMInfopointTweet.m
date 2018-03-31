//
//  SMInfopointTweet.m
//  Speind
//
//  Created by Sergey Butenko on 10/20/14.
//  Copyright (c) 2014 Speaking Mind. All rights reserved.
//

#import "SMInfopointTweet.h"
#import "NSString+Language.m"

@implementation SMInfopointTweet

- (NSString *)lang
{
    return [self.summary sm_langOfString];
}

- (NSString*)vocalizingTextWithPreviuosInfopoint:(SMInfopoint*)infopoint fullArticle:(BOOL)fullArticle
{
    if (fullArticle && self.fullArticle.length > 0) {
        return [NSString stringWithFormat:@"%@ %@", self.postSenderVocalizing, self.fullArticle];
    }
    return self.textVocalizing;
}

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[self class]]) {
        SMInfopointTweet *tweet = object;
        return [self.summary isEqualToString:tweet.summary];
    }
    return NO;
}

- (NSUInteger)hash
{
    return [self.summary hash];
}

- (UIImage *)sourceIcon
{
    return [UIImage imageNamed:@"icon_feed_twitter"];
}

@end
