//
//  SMListsDownloader.h
//  Speind
//
//  Created by Sergey Butenko on 01.07.14.
//  Copyright (c) 2014 serejahh inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SMListsDownloader;

@protocol SMListsDownloaderDelegate <NSObject>

- (void)listsDownloaderDidFinishDownloading:(SMListsDownloader*)downloader;

@end

@interface SMListsDownloader : NSObject

@property id<SMListsDownloaderDelegate> delegate;
- (instancetype)initWithDelegate:(id<SMListsDownloaderDelegate>)delegate;

/**
 * Обновляет списки с источниками. Обновление должно происходить раз в день.
 */
- (void)updateFeedsList;

/*
 * Парсинг скачанного CSV файла.
 */
- (void)parseFeedsFromPath:(NSString *)path inMainQueue:(BOOL)inMainQueue;

@end
