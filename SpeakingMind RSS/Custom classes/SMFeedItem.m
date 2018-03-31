//
//  SMFeedItem.m
//  Speind
//
//  Created by Sergey Butenko on 17.06.14.
//  Copyright (c) 2014 serejahh inc. All rights reserved.
//

#import "SMFeedItem.h"

@interface SMFeedItem ()

@property (nonatomic, readwrite) NSInteger uid;
@property (nonatomic, readwrite) NSString *lang;
@property (nonatomic, readwrite) NSString *country;
@property (nonatomic, readwrite) NSString *region;
@property (nonatomic, readwrite) NSString *city;
@property (nonatomic, readwrite) NSString *category;
@property (nonatomic, readwrite) NSString *subcategory;
@property (nonatomic, readwrite) NSString *provider;
@property (nonatomic, readwrite) NSString *vocalizing;
@property (nonatomic, readwrite) NSString *url;

@end

@implementation SMFeedItem

#pragma mark - Initializing

- (id)initWithLang:(NSString*)lang country:(NSString*)country region:(NSString*)region city:(NSString*)city category:(NSString*)category subcategory:(NSString*)subcategory provider:(NSString*)provider vocalizing:(NSString*)vocalizing url:(NSString*)url
{
    self = [super init];
    if (self) {
        _lang = lang;
        _country = country;
        _region = region;
        _city = city;
        _category = category;
        _subcategory = subcategory;
        _provider = provider;
        _vocalizing = vocalizing;
        _url = url;
    }
    
    return self;
}

- (id)initWithUid:(NSInteger)uid lang:(NSString*)lang country:(NSString*)country region:(NSString*)region city:(NSString*)city category:(NSString*)category subcategory:(NSString*)subcategory provider:(NSString*)provider vocalizing:(NSString*)vocalizing url:(NSString*)url
{
    self = [self initWithLang:lang country:country region:region city:city category:category subcategory:subcategory provider:provider vocalizing:vocalizing url:url];
    if (self) {
        _uid = uid;
    }
    
    return self;
}

+ (instancetype)feedWithLang:(NSString*)lang country:(NSString*)country region:(NSString*)region city:(NSString*)city category:(NSString*)category subcategory:(NSString*)subcategory provider:(NSString*)provider vocalizing:(NSString*)vocalizing url:(NSString*)url
{
    return [[self alloc]initWithLang:lang country:country region:region city:city category:category subcategory:subcategory provider:provider vocalizing:vocalizing url:url];
}

+ (instancetype)feedWithUid:(NSInteger)uid lang:(NSString *)lang country:(NSString *)country region:(NSString *)region city:(NSString *)city category:(NSString *)category subcategory:(NSString *)subcategory provider:(NSString *)provider vocalizing:(NSString *)vocalizing url:(NSString *)url
{
    return [[self alloc]initWithUid:uid lang:lang country:country region:region city:city category:category subcategory:subcategory provider:provider vocalizing:vocalizing url:url];
}
+ (instancetype)userFeedWithUid:(NSInteger)uid provider:(NSString*)provider url:(NSString*)url lang:(NSString*)lang;
{
    return [self feedWithUid:uid lang:lang country:nil region:nil city:nil category:nil subcategory:nil provider:provider vocalizing:nil url:url];
}

- (id)copyWithZone:(NSZone *)zone
{
    SMFeedItem *feed = [[SMFeedItem alloc] initWithUid:self.uid
                                                  lang:[self.lang copyWithZone:zone]
                                               country:[self.country copyWithZone:zone]
                                                region:[self.region copyWithZone:zone]
                                                  city:[self.city copyWithZone:zone]
                                              category:[self.category copyWithZone:zone]
                                           subcategory:[self.subcategory copyWithZone:zone]
                                              provider:[self.provider copyWithZone:zone]
                                            vocalizing:[self.vocalizing copyWithZone:zone]
                                                   url:[self.url copyWithZone:zone]];
    feed.selected = self.isSelected;
    
    return feed;
}

#pragma mark -

- (NSString*)description
{
    return _provider;
}

@end
