//
//  NSMutableArray+Queue.m
//  SpeakingMind RSS
//
//  Created by Sergey Butenko on 9/12/14.
//  Copyright (c) 2014 serejahh inc. All rights reserved.
//

#import "NSMutableArray+Queue.h"

@implementation NSMutableArray (Queue)

- (id)pop
{
    id obj = [self firstObject];
    if (obj) {
        [self removeObjectAtIndex:0];
    }
    return obj;
}

- (void)push:(id)obj
{
    [self addObject: obj];
}

@end
