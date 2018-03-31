//
//  RSSInfo.h
//  SpeakingMind RSS
//
//  Created by Sergey Butenko on 9/12/14.
//  Copyright (c) 2014 serejahh inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RSSInfo : NSObject

@property (strong,nonatomic) NSString *language;
@property (strong,nonatomic) NSString *title;
@property (strong,nonatomic) NSString *feedDescription;
@property (strong,nonatomic) NSString *iconURL;

@end
