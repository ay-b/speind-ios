//
//  SMListsDownloader.m
//  Speind
//
//  Created by Sergey Butenko on 01.07.14.
//  Copyright (c) 2014 serejahh inc. All rights reserved.
//

#import "SMListsDownloader.h"
#import "SMFeedItem.h"
#import "SMDatabase.h"

#import <AFNetworking/AFHTTPRequestOperation.h>
#import <CHCSVParser/CHCSVParser.h>

static const int kCountCols = 9;

@interface SMListsDownloader ()

/*
 * Обновляет файл с списком языков и ссылкой на скачивание файла источников для языка.
 */
- (void)p_updateFeeds;

/*
 * Парсит список источников для заданного пути в фоне или главной очереди.
 */
- (void)parseFeedsFromPath:(NSString *)path inMainQueue:(BOOL)inMainQueue;

@end

@implementation SMListsDownloader
{
    int leftFeeds;
    dispatch_queue_t parseQueue;
}

#pragma mark - Public API

- (instancetype)initWithDelegate:(id<SMListsDownloaderDelegate>)delegate
{
    self = [super init];
    if (self) {
        _delegate = delegate;
        parseQueue = dispatch_queue_create("me.speind.parseList", NULL);
    }
    return self;
}

- (void)updateFeedsList
{
    NSString *urlString = [SMURLRSSResources stringByAppendingPathComponent:SMURLFeedsList];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    
    NSString *path = [DOCUMENTS_DIRECTORY stringByAppendingPathComponent:SMURLFeedsList];
    operation.outputStream = [NSOutputStream outputStreamToFileAtPath:path append:NO];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        DLog(@"Feeds list downloaded");
        [self p_updateFeeds];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DLog(@"List downloading error: %@", error.localizedDescription);
    }];
    
    [operation start];
}

#pragma mark - Private API

- (void)p_updateFeeds
{
    NSString *pathToFile = [DOCUMENTS_DIRECTORY stringByAppendingPathComponent:SMURLFeedsList];
    __block NSArray *tmpFeed = [NSArray arrayWithContentsOfCSVFile:pathToFile options:CHCSVParserOptionsRecognizesBackslashesAsEscapes];
    
    leftFeeds = (int)tmpFeed.count - 1;
    for (int i = 1; i < tmpFeed.count; i++) {// skip the first element - header
        if ([tmpFeed[i] count] < 2) { // last element - an empty row with a single element
            continue;
        }
        NSString *urlString = tmpFeed[i][1];

        NSString *fileName = [[urlString pathComponents] lastObject];
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
        AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
        NSString *path = [DOCUMENTS_DIRECTORY stringByAppendingPathComponent:fileName];
        operation.outputStream = [NSOutputStream outputStreamToFileAtPath:path append:NO];
        
        [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            DLog(@"List downloaded %@", fileName);
            [self p_downloadingDidFinished];
            [self parseFeedsFromPath:path inMainQueue:NO];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
           [self p_downloadingDidFinished];
            DLog(@"List downloading error: %@", error.localizedDescription);
        }];
        [operation start];
        DLog(@"Start download %@", fileName);
    }
}

- (void)parseFeedsFromPath:(NSString *)path inMainQueue:(BOOL)inMainQueue
{
    void (^block)() = ^{
//        DLog(@"start <%@>", [[path pathComponents] lastObject]);
//        NSDate *d1 = [NSDate date];
        NSArray *tmpFeed = [NSArray arrayWithContentsOfCSVFile:path options:CHCSVParserOptionsRecognizesBackslashesAsEscapes | CHCSVParserOptionsTrimsWhitespace];
//        DLog(@"stop <%@>: %lf", [[path pathComponents] lastObject], [[NSDate date] timeIntervalSinceDate:d1]);
        
        NSMutableArray *feeds = [NSMutableArray array];
        for (int i = 1; i<tmpFeed.count; i++) {
            NSArray *item = [tmpFeed objectAtIndex:i];
            if (item.count != kCountCols) {
                continue;
            }
            SMFeedItem *feed = [SMFeedItem feedWithLang:item[0] country:item[1] region:item[2] city:item[3] category:item[4] subcategory:item[5] provider:item[6] vocalizing:item[7] url:item[8]];
            [feeds addObject:feed];
        }
        [SMDatabase insertFeeds:feeds];
    };

    if (inMainQueue) {
        block();
    }
    else {
        dispatch_async(parseQueue, block);
    }
}

- (void)p_downloadingDidFinished
{
    leftFeeds--;
    if (leftFeeds == 0) {
        dispatch_barrier_async(parseQueue, ^{
            [self.delegate listsDownloaderDidFinishDownloading:self];
        });
    }
}

@end
