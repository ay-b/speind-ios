//
//  SMVoicesDownloader.h
//  Speind
//
//  Created by Sergey Butenko on 3/5/15.
//  Copyright (c) 2015 Speaking Mind. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SMVoicesDownloader, SMVoice;

@protocol SMVoicesDownloaderDelegate <NSObject>

@optional

- (void)voicesDownloaderWillDownload:(SMVoicesDownloader*)downloader;
- (void)voicesDownloaderDownload:(SMVoicesDownloader*)downloader progress:(double)progress;
- (void)voicesDownloaderDidDownload:(SMVoicesDownloader*)downloader;
- (void)voicesDownloaderFailedDownloading:(SMVoicesDownloader*)downloader error:(NSError*)error;

- (void)voicesDownloaderWillUnzipArchive:(SMVoicesDownloader*)downloader;
- (void)voicesDownloaderUnzipArchive:(SMVoicesDownloader*)downloader progress:(double)progress;
- (void)voicesDownloaderDidUnzipArchive:(SMVoicesDownloader*)downloader;

@end

@interface SMVoicesDownloader : NSObject

+ (instancetype)downloader;
- (void)refreshVoices;

@property (nonatomic, weak) id<SMVoicesDownloaderDelegate> delegate;

@property (nonatomic, readonly, getter=isDownloading) BOOL downloading;
@property (nonatomic, readonly) double progress;
@property (nonatomic, readonly) SMVoice *nowDownloadingVoice;
@property (nonatomic, readonly) NSArray *leftVoices;

- (void)cancelByProducingResumeData;
+ (void)removeTrashFromDocuments;

@end

