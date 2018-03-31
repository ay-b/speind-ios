//
//  SMInfopointsDownloader.m
//  Speind
//
//  Created by Sergey Butenko on 3/6/15.
//  Copyright (c) 2015 Speaking Mind. All rights reserved.
//

#import "SMInfopointsDownloader.h"
#import "SMInfopointsFetcherRSS.h"
#import "SMInfopointsFetcherVK.h"
#import "SMInfopointsFetcherTWT.h"
#import "SMDatabase.h"

#define SMOptionsHasValue(options, value) (((options) & (value)) == (value))

typedef NS_OPTIONS(NSUInteger, SMInfopointsDownloaderLeftSources) {
    SMInfopointsDownloaderLeftSourcesRSS = 1 << 0,
    SMInfopointsDownloaderLeftSourcesVK = 1 << 1,
    SMInfopointsDownloaderLeftSourcesTWT = 1 << 2,
};

@interface SMInfopointsDownloader () <SMInfopointReceiver>

@property (nonatomic) SMInfopointsFetcherRSS* rssDownloader;
@property (nonatomic) SMInfopointsFetcherTWT* twitterDownloader;
@property (nonatomic) SMInfopointsFetcherVK* vkDownloader;

@property (nonatomic) NSMutableArray *infopointsQueue;
@property (nonatomic) BOOL delegateReadyToReceiving;
@property (nonatomic) SMInfopointsDownloaderLeftSources leftSources;

- (void)p_sendInfopoints;

@end

@implementation SMInfopointsDownloader

- (instancetype)initWithDelegate:(id<SMInfopointsDownloaderDelegate>)delegate
{
    self = [self init];
    if (self) {
        _delegate = delegate;
    }
    return self;
}

+ (instancetype)downloaderWithDelegate:(id<SMInfopointsDownloaderDelegate>)delegate
{
    return [[self alloc] initWithDelegate:delegate];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _infopointsQueue = [NSMutableArray array];
        _rssDownloader = [SMInfopointsFetcherRSS fetcherWithDelegate:self];
        _vkDownloader = [SMInfopointsFetcherVK fetcherWithDelegate:self];
        _twitterDownloader = [SMInfopointsFetcherTWT fetcherWithDelegate:self];
    }
    return self;
}

- (void)requestInfopoints
{
    self.delegateReadyToReceiving = YES;
    
    if ([[SMSettings sharedSettings] isRSSPluginEnabled]) {
        self.leftSources = self.leftSources | SMInfopointsDownloaderLeftSourcesRSS;
        
        NSMutableArray *allFeeds = [NSMutableArray array];
        [allFeeds addObjectsFromArray:[SMDatabase selectedFeeds]];
        [allFeeds addObjectsFromArray:[SMDatabase selectedUsersFeeds]];
        [_rssDownloader fetchForFeeds:allFeeds];
    }
        
    if ([[SMSettings sharedSettings] isVKAuthorized] && [[SMSettings sharedSettings] isVKPluginEnabled]) {
        self.leftSources = self.leftSources | SMInfopointsDownloaderLeftSourcesVK;
        [_vkDownloader fetch];
    }
    
    if ([[SMSettings sharedSettings] isTwitterAuthorized] && [[SMSettings sharedSettings] isTwitterPluginEnabled]) {
        self.leftSources = self.leftSources | SMInfopointsDownloaderLeftSourcesTWT;
        [_twitterDownloader fetch];
    }
}

- (void)processedInfopoints
{
    self.delegateReadyToReceiving = YES;
    [self p_sendInfopoints];
}

- (void)p_sendInfopoints
{
    if (!self.delegateReadyToReceiving || ![self.delegate respondsToSelector:@selector(infopointsDownloader:didDownloadInfopoints:)]) {
        return;
    }
    
    __weak typeof(self)weakSelf = self;
    @synchronized(weakSelf.infopointsQueue) {
        NSArray *infopoints = [self.infopointsQueue firstObject];
        if (infopoints) {
            [self.infopointsQueue removeObjectAtIndex:0];
            self.delegateReadyToReceiving = NO;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate infopointsDownloader:self didDownloadInfopoints:infopoints];
            });
        }
    }
}

- (NSString*)leftSourcesString
{
    NSMutableArray *sources = [NSMutableArray array];
    if (SMOptionsHasValue(self.leftSources, SMInfopointsDownloaderLeftSourcesRSS)) {
        [sources addObject:LOC(@"RSS")];
    }
    if (SMOptionsHasValue(self.leftSources, SMInfopointsDownloaderLeftSourcesTWT)) {
        [sources addObject:LOC(@"Twitter")];
    }
    if (SMOptionsHasValue(self.leftSources, SMInfopointsDownloaderLeftSourcesVK)) {
        [sources addObject:LOC(@"Vkontakte")];
    }
    
    return [[sources valueForKey:@"description"] componentsJoinedByString:@", "];
}

#pragma mark - SMInfopointReceiver

- (void)fetcher:(SMInfopointsFetcher*)fetcher receiveInfopoints:(NSArray*)infopoints
{
    if ([fetcher isKindOfClass:[SMInfopointsFetcherVK class]]) {
        self.leftSources = self.leftSources & ~SMInfopointsDownloaderLeftSourcesVK;
    }
    else if ([fetcher isKindOfClass:[SMInfopointsFetcherTWT class]]) {
        self.leftSources = self.leftSources & ~SMInfopointsDownloaderLeftSourcesTWT;
    }
    
    __weak typeof(self)weakSelf = self;
    @synchronized(weakSelf.infopointsQueue) {
        [self.infopointsQueue addObject:infopoints];
    }
    
    [self p_sendInfopoints];
}

- (void)fetcher:(SMInfopointsFetcher*)fetcher receivingFailedWithError:(NSError*)error;
{
    DLog(@"%@ fetch error: %@", NSStringFromClass([fetcher class]), error.localizedDescription);
    
    if ([fetcher isKindOfClass:[SMInfopointsFetcherRSS class]]) {
        self.leftSources = self.leftSources & ~SMInfopointsDownloaderLeftSourcesRSS;
    }
    else if ([fetcher isKindOfClass:[SMInfopointsFetcherVK class]]) {
        self.leftSources = self.leftSources & ~SMInfopointsDownloaderLeftSourcesVK;
    }
    else if ([fetcher isKindOfClass:[SMInfopointsFetcherTWT class]]) {
        self.leftSources = self.leftSources & ~SMInfopointsDownloaderLeftSourcesTWT;
    }
    
    if ([self.delegate respondsToSelector:@selector(infopointsDownloader:failedWithError:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate infopointsDownloader:self failedWithError:error];
        });
    }
}

- (void)fetcherFinished:(SMInfopointsFetcher*)fetcher
{
    self.leftSources = self.leftSources & ~SMInfopointsDownloaderLeftSourcesRSS;
}

@end
