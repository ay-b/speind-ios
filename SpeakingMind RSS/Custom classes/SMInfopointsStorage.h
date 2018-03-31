//
//  SMInfopointsStorage.h
//  Speind
//
//  Created by Sergey Butenko on 12/3/14.
//  Copyright (c) 2014 Speaking Mind. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SMInfopointsStorage : NSObject

+ (instancetype)sharedInstance;

@property (nonatomic) NSMutableArray *data;
@property (nonatomic) NSNumber *currentIndex;
@property (nonatomic) NSNumber *playerIndex;

- (void)saveData;

@end
