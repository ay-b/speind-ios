//
//  SMTweetBuilder.h
//  Speind
//
//  Created by Sergey Butenko on 10/11/14.
//  Copyright (c) 2014 Speaking Mind. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SMTweetBuilder : NSObject

+ (instancetype)sharedBuilder;

/**
 * Converts JSON data to infopoint.
 *
 * @return Array of SMInfopointTweet objects.
 *
 */
- (NSArray*)infopointsForTweets:(NSArray*)tweets;

@end
