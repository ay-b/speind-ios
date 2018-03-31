//
//  SMInfopointsFetcherUtilities.m
//  Speind
//
//  Created by Sergey Butenko on 3/20/15.
//  Copyright (c) 2015 Speaking Mind. All rights reserved.
//

#import "SMInfopointsFetcherUtilities.h"
#import "SMInfopoint.h"
#import "NSString+HTML.h"
#import "RSSParser.h"
#import <AFNetworking/AFNetworking.h>

@implementation SMInfopointsFetcherUtilities

+ (void)checkFeed:(NSString*)urlString resultHandler:(void (^)(BOOL isCorrect))result
{
    NSURLRequest *checkRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    [RSSParser parseRSSFeedForRequest:checkRequest success:^(NSArray *feedItems, RSSInfo *feedInfo) {
        result(feedItems.count > 0);
    } failure:^(NSError *error) {
        result(NO);
    }];
}

+ (void)downloadFullArticleForNews:(SMInfopoint*)item success:(void (^)(NSString* article))success failure:(void (^)(NSError* error))failure
{
    if (item.link.length == 0) {
        if (success) {
            success(nil);
        }
        return;
    }
    
    NSDictionary *parameters = @{@"url" : item.link};
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    [manager POST:@"http://api.speind.me/getArticle/" parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSString *planeText = @"";
        if (responseObject) {
            NSString *htmlString = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
            planeText = [htmlString stringByConvertingHTMLToPlainText];
        }
        
        item.fullArticle = planeText.length == 0 ? item.summary : planeText;
        if (success) {
            success(planeText);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}

@end
