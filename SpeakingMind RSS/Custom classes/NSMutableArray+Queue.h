//
//  NSMutableArray+Queue.h
//  SpeakingMind RSS
//
//  Created by Sergey Butenko on 9/12/14.
//  Copyright (c) 2014 serejahh inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableArray (Queue)

- (id)pop;
- (void)push:(id)obj;

@end
