//
//  SMVKBuilder.h
//  SpeakingMind RSS
//
//  Created by Sergey Butenko on 10/22/14.
//  Copyright (c) 2014 Speaking Mind. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * Converts the JSON data to infopoints.
 */
@interface SMVKBuilder : NSObject

+ (instancetype)sharedBuilder;

/**
 * Converts JSON data to infopoint.
 *
 * @return Array of SMInfopointVK objects.
 *
 */
- (NSArray*)infopointsForPosts:(NSDictionary*)posts;

@end
