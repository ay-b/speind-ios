//
//  SMInfopointsFetcherUtilities.h
//  Speind
//
//  Created by Sergey Butenko on 3/20/15.
//  Copyright (c) 2015 Speaking Mind. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SMInfopoint;

@interface SMInfopointsFetcherUtilities : NSObject

+ (void)checkFeed:(NSString*)urlString resultHandler:(void (^)(BOOL isCorrect))result;
+ (void)downloadFullArticleForNews:(SMInfopoint*)item success:(void (^)(NSString* article))success failure:(void (^)(NSError* error))failure;

@end
