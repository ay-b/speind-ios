//
//  SMInfopointsFetcherTWT.m
//  Speind
//
//  Created by Sergey Butenko on 3/20/15.
//  Copyright (c) 2015 Speaking Mind. All rights reserved.
//

#import "SMInfopointsFetcherTWT.h"
#import "SMTweetBuilder.h"

#import <STTwitter/STTwitter.h>

@interface SMInfopointsFetcherTWT ()

@property (nonatomic) STTwitterAPI *twitter;

@end

@implementation SMInfopointsFetcherTWT

- (void)fetch
{
    __weak typeof(self)weakSelf = self;
    _twitter = [STTwitterAPI twitterAPIOSWithFirstAccount];
    [_twitter verifyCredentialsWithSuccessBlock:^(NSString *username) {
        [weakSelf downloadTimeline];
    } errorBlock:^(NSError *error) {
        if ([[SMSettings sharedSettings] isTwitterAuthorized]) {
            _twitter = [STTwitterAPI twitterAPIWithOAuthConsumerKey:SMTwitterConsumerKey consumerSecret:SMTwitterConsumerSecret oauthToken:[[SMSettings sharedSettings] twitterAccessToken] oauthTokenSecret:[[SMSettings sharedSettings] twitterAccessTokenSecret]];
            [_twitter verifyCredentialsWithSuccessBlock:^(NSString *username) {
                [weakSelf downloadTimeline];
            } errorBlock:^(NSError *error) {
                [weakSelf.delegate fetcher:self receivingFailedWithError:error];
            }];
        }
    }];
}

- (void)downloadTimeline
{
    __weak typeof(self)weakSelf = self;
    if ([[SMSettings sharedSettings] isTwitterPluginEnabled]) {
        [self.twitter getHomeTimelineSinceID:nil count:SMTwitterCountTweets successBlock:^(NSArray *statuses) {
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                NSArray *tweets = [[SMTweetBuilder sharedBuilder] infopointsForTweets:statuses];
                [weakSelf.delegate fetcher:weakSelf receiveInfopoints:tweets];
            });
        } errorBlock:^(NSError *error) {
            [weakSelf.delegate fetcher:weakSelf receivingFailedWithError:error];
        }];
    }
}

@end
