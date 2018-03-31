//
//  SMInfopointsFetcherVK.m
//  Speind
//
//  Created by Sergey Butenko on 3/20/15.
//  Copyright (c) 2015 Speaking Mind. All rights reserved.
//

#import "SMInfopointsFetcherVK.h"
#import "SMVKBuilder.h"

#import <VK-ios-sdk/VKSdk.h>

@implementation SMInfopointsFetcherVK

- (void)fetch
{
    [VKSdk initializeWithDelegate:nil andAppId:SMVKAppKey];
    if (![VKSdk wakeUpSession]) {
        return;
    }
    
    __weak typeof(self)weakSelf = self;
    VKRequest *user = [VKRequest requestWithMethod:@"newsfeed.get" andParameters:@{@"count" : @(SMVKCountPosts), @"filters" : @"post, photo"} andHttpMethod:@"GET"];
    [user executeWithResultBlock:^(VKResponse *response) {
        NSArray *posts = [[SMVKBuilder sharedBuilder] infopointsForPosts:[response json]];
        [weakSelf.delegate fetcher:weakSelf receiveInfopoints:posts];
    } errorBlock:^(NSError *error) {
        [weakSelf.delegate fetcher:weakSelf receivingFailedWithError:error];
    }];
}

@end
