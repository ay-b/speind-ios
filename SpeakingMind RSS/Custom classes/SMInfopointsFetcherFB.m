//
//  SMInfopointsFetcherFB.m
//  Speind
//
//  Created by Sergey Butenko on 3/20/15.
//  Copyright (c) 2015 Speaking Mind. All rights reserved.
//

#import "SMInfopointsFetcherFB.h"
#import "SMFBBuilder.h"

#import <Facebook-iOS-SDK/FacebookSDK/FacebookSDK.h>

@implementation SMInfopointsFetcherFB

- (void)fetch
{
    if (!FBSession.activeSession.isOpen) {
        [FBSession openActiveSessionWithReadPermissions:@[@"public_profile", @"user_posts"] allowLoginUI:NO
        completionHandler:^(FBSession *session, FBSessionState state, NSError *error) {
            if (error) {
                DLog(@"FB login error: %@", error.localizedDescription);
            }
            else if (session.isOpen) {
                [self fetch];
            }
        }];
        return;
    }

    [self downloadPosts];
}

- (void)downloadPosts
{
    if ([[SMSettings sharedSettings] isFBPluginEnabled]) {
        NSNumber *limit = @(100);
        NSString *locale = [[NSLocale currentLocale] localeIdentifier];
        NSString *graph = [NSString stringWithFormat:@"me/home"];
        NSDictionary *param = @{@"limit" : limit,
                                @"locale" : locale};
        FBRequest *request = [FBRequest requestWithGraphPath:graph parameters:param HTTPMethod:@"GET"];
        
        [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            if (error) {
                [self.delegate receivingFailedWithError:error];
                DLog(@"FB fetch posts error: %@", error.localizedDescription);
                return;
            }

            NSArray *posts = [[SMFBBuilder sharedBuilder] infopointsForPosts:result];
            NSLog(@"FB posts: %lu", (unsigned long)posts.count);
            [self.delegate receiveInfopoints:posts];
        }];
    }
}

@end
