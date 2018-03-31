//
//  SMFBBuilder.h
//  Speind
//
//  Created by Sergey Butenko on 3/7/15.
//  Copyright (c) 2015 Speaking Mind. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FBGraphObject;

@interface SMFBBuilder : NSObject

+ (instancetype)sharedBuilder;

/**
 * Converts FBGraphObject data to infopoint.
 *
 * @return Array of SMInfopointFB objects.
 *
 */
- (NSArray*)infopointsForPosts:(FBGraphObject*)posts;

@end
