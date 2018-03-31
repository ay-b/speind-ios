//
//  SMNewsItem.h
//  Speind
//
//  Created by Sergey Butenko on 02.06.14.
//  Copyright (c) 2014 serejahh inc. All rights reserved.
//

#import "SMInfopoint.h"

@interface SMInfopointNews : SMInfopoint

/** deprecated */
@property NSInteger uid;

- (id)initWithTitle:(NSString*)title link:(NSString*)link summary:(NSString*)summary pubDate:(NSDate*)pubDate enclosure:(NSString*)enclosure;
- (id)initWithUid:(NSInteger)uid prioriry:(NSInteger)prioriry title:(NSString*)title link:(NSString*)link summary:(NSString*)summary fullArticle:(NSString*)fullArticle pubDate:(NSDate*)pubDate enclosure:(NSString*)enclosure;

+ (instancetype)newsWithTitle:(NSString*)title link:(NSString*)link summary:(NSString*)summary pubDate:(NSDate*)pubDate enclosure:(NSString*)enclosure;
+ (instancetype)newsWithUid:(NSInteger)uid prioriry:(NSInteger)prioriry title:(NSString*)title link:(NSString*)link summary:(NSString*)summary fullArticle:(NSString*)fullArticle pubDate:(NSDate*)pubDate enclosure:(NSString*)enclosure;

@end