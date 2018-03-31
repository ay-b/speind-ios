//
//  SMInfopointsDownloader.h
//  Speind
//
//  Created by Sergey Butenko on 3/6/15.
//  Copyright (c) 2015 Speaking Mind. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SMInfopointsDownloader;

@protocol SMInfopointsDownloaderDelegate <NSObject>

@optional

- (void)infopointsDownloader:(SMInfopointsDownloader*)downloader didDownloadInfopoints:(NSArray*)infopoints;
- (void)infopointsDownloader:(SMInfopointsDownloader*)downloader failedWithError:(NSError*)error;

@end

@interface SMInfopointsDownloader : NSObject

- (instancetype)initWithDelegate:(id<SMInfopointsDownloaderDelegate>)delegate;
+ (instancetype)downloaderWithDelegate:(id<SMInfopointsDownloaderDelegate>)delegate;

@property (nonatomic, weak) id<SMInfopointsDownloaderDelegate> delegate;

- (void)requestInfopoints;
- (void)processedInfopoints;
- (NSString*)leftSourcesString;

@end
