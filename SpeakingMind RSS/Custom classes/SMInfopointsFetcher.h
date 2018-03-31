

//
//  SMInfopointsFetcher.h
//  Speind
//
//  Created by Sergey Butenko on 3/20/15.
//  Copyright (c) 2015 Speaking Mind. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SMInfopointsFetcher;

@protocol SMInfopointReceiver <NSObject>

- (void)fetcher:(SMInfopointsFetcher*)fetcher receiveInfopoints:(NSArray*)infopoints;
- (void)fetcher:(SMInfopointsFetcher*)fetcher receivingFailedWithError:(NSError*)error;
- (void)fetcherFinished:(SMInfopointsFetcher*)fetcher;

@end

/**
 * Abstract class for fetching data for each plugin.
 */
@interface SMInfopointsFetcher : NSObject

+ (instancetype)fetcherWithDelegate:(id<SMInfopointReceiver>)delegate;
- (instancetype)initWithDelegate:(id<SMInfopointReceiver>)delegate;

@property (nonatomic, weak) id<SMInfopointReceiver> delegate;

- (void)fetch;

@end
