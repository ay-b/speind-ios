//
//  RSSParser.h
//  RSSParser
//
//  Created by Thibaut LE LEVIER on 1/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RSSItem.h"
#import "RSSInfo.h"

@interface RSSParser : NSObject <NSXMLParserDelegate> {
    RSSItem *currentItem;
    RSSInfo *feedInfo;
    NSString *enclouser;
    NSMutableArray *items;
    NSMutableString *tmpString;
    void (^block)(NSArray *feedItems, RSSInfo *feedInfo);
    void (^failblock)(NSError *error);
}



+ (void)parseRSSFeedForRequest:(NSURLRequest *)urlRequest
                       success:(void (^)(NSArray *feedItems, RSSInfo *feedInfo))success
                       failure:(void (^)(NSError *error))failure;

- (void)parseRSSFeedForRequest:(NSURLRequest *)urlRequest
                       success:(void (^)(NSArray *feedItems, RSSInfo *feedInfo))success
                       failure:(void (^)(NSError *error))failure;


@end
