//
//  SMFeedItem.h
//  Speind
//
//  Created by Sergey Butenko on 17.06.14.
//  Copyright (c) 2014 serejahh inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SMFeedItem : NSObject <NSCopying>

@property (nonatomic, readonly) NSInteger uid;
@property (nonatomic, readonly) NSString *lang;
@property (nonatomic, readonly) NSString *country;
@property (nonatomic, readonly) NSString *region;
@property (nonatomic, readonly) NSString *city;
@property (nonatomic, readonly) NSString *category;
@property (nonatomic, readonly) NSString *subcategory;
@property (nonatomic, readonly) NSString *provider;
@property (nonatomic, readonly) NSString *vocalizing;
@property (nonatomic, readonly) NSString *url;
@property (nonatomic, getter = isSelected) BOOL selected;

- (id)initWithLang:(NSString*)lang country:(NSString*)country region:(NSString*)region city:(NSString*)city category:(NSString*)category subcategory:(NSString*)subcategory provider:(NSString*)provider vocalizing:(NSString*)vocalizing url:(NSString*)url;
- (id)initWithUid:(NSInteger)uid lang:(NSString*)lang country:(NSString*)country region:(NSString*)region city:(NSString*)city category:(NSString*)category subcategory:(NSString*)subcategory provider:(NSString*)provider vocalizing:(NSString*)vocalizing url:(NSString*)url;

+ (instancetype)feedWithLang:(NSString*)lang country:(NSString*)country region:(NSString*)region city:(NSString*)city category:(NSString*)category subcategory:(NSString*)subcategory provider:(NSString*)provider vocalizing:(NSString*)vocalizing url:(NSString*)url;

+ (instancetype)feedWithUid:(NSInteger)uid lang:(NSString*)lang country:(NSString*)country region:(NSString*)region city:(NSString*)city category:(NSString*)category subcategory:(NSString*)subcategory provider:(NSString*)provider vocalizing:(NSString*)vocalizing url:(NSString*)url;

+ (instancetype)userFeedWithUid:(NSInteger)uid provider:(NSString*)provider url:(NSString*)url lang:(NSString*)lang;

@end

