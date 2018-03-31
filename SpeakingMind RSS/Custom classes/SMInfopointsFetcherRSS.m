//
//  SMInfopointsFetcherRSS.m
//  Speind
//
//  Created by Sergey Butenko on 3/20/15.
//  Copyright (c) 2015 Speaking Mind. All rights reserved.
//

#import "SMInfopointsFetcherRSS.h"
#import "SMInfopointNews.h"
#import "SMFeedItem.h"
#import "NSMutableArray+Queue.h"

#import "NSString+HTML.h"
#import "MWFeedParser.h"
#import <AFNetworking/AFNetworking.h>

static const BOOL kDetailLogging = YES;

@interface SMInfopointsFetcherRSS () <MWFeedParserDelegate>

@property NSMutableArray *feeds;
@property NSMutableArray *items;

@property MWFeedInfo *feedInfo;
@property SMFeedItem *currentFeed;

@end

@implementation SMInfopointsFetcherRSS

#pragma mark - Dowloading feeds

- (void)fetchForFeeds:(NSArray*)feeds
{
    _feeds = [NSMutableArray arrayWithArray:feeds];
    DLog(@"Parsing started: %lu feeds", (unsigned long)feeds.count);
    [self p_downloadNextFeed];
}

- (NSArray*)p_convertItems:(NSArray*)rssItems forFeed:(SMFeedItem*)feed feedInfo:(MWFeedInfo*)feedInfo
{
    NSMutableArray *myItems = [NSMutableArray array];
    
    for (MWFeedItem *rawItem in rssItems) {
        NSString *img = rawItem.image;
        if (!img) {
            for (NSDictionary *enclosure in rawItem.enclosures) {
                if ([enclosure[@"type"] rangeOfString:@"image"].location != NSNotFound) {
                    img = enclosure[@"url"];
                    break;
                }
            }
        }
        NSString *summary = [rawItem.summary stringByConvertingHTMLToPlainText];
        if (summary.length == 0) {
            continue;
        }
        
        SMInfopointNews *item = [SMInfopointNews newsWithTitle:rawItem.title link:rawItem.link summary:summary pubDate:rawItem.date enclosure:img];
        item.priority = SMDefaultInfopointPriority;
        item.lang = feed.lang;
        item.postSender = feedInfo.title;
        item.senderIcon = feedInfo.icon;
        item.postSenderVocalizing = feed.vocalizing;
        
        [myItems addObject:item];
    }
    
    return myItems;
}

- (void)p_downloadNextFeed
{
    self.currentFeed = [_feeds pop];
    
    if (!self.currentFeed) {
        DLog(@"Parsing finished");
        [self.delegate fetcherFinished:self];
        return;
    }
    
    MWFeedParser* parser = [[MWFeedParser alloc] initWithFeedURL:[NSURL URLWithString:self.currentFeed.url]];
    parser.delegate = self;
    parser.feedParseType = ParseTypeFull;
    parser.connectionType = ConnectionTypeAsynchronously;
    
    if (kDetailLogging) {
        DLog(@"Start parsing feed: %@", parser.url.absoluteString);
    }
    [parser parse];
}

#pragma mark - MWFeedParser delegate

- (void)feedParserDidStart:(MWFeedParser *)parser
{
    _items = [NSMutableArray array];
}

- (void)feedParser:(MWFeedParser *)parser didParseFeedInfo:(MWFeedInfo *)info
{
    _feedInfo = info;
}

- (void)feedParser:(MWFeedParser *)parser didParseFeedItem:(MWFeedItem *)item
{
    [_items addObject:item];
}

- (void)feedParserDidFinish:(MWFeedParser *)parser
{
    NSArray *infopoints = [self p_convertItems:_items forFeed:[self.currentFeed copy] feedInfo:_feedInfo];
    [self.delegate fetcher:self receiveInfopoints:infopoints];
    [self p_downloadNextFeed];
}

- (void)feedParser:(MWFeedParser *)parser didFailWithError:(NSError *)error
{
    if (kDetailLogging) {
        DLog(@"Parsing failed %@", parser.url.absoluteString);
    }
    [self feedParserDidFinish:parser];
}

@end
