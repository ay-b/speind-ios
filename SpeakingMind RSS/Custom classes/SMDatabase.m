//
//  SMDatabase.m
//  Speind
//
//  Created by Sergey Butenko on 24.06.14.
//  Copyright (c) 2014 serejahh inc. All rights reserved.
//

#import "SMDatabase.h"
#import "SMFeedItem.h"

#import <FMDB/FMDB.h>

@implementation SMDatabase

+ (FMDatabase*)db
{
    return [FMDatabase databaseWithPath:[self pathToDB]];
}

+ (NSString*)pathToDB
{
    return [DOCUMENTS_DIRECTORY stringByAppendingPathComponent:@"news.sqlite"];
}

+ (void)removeDatabase
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:[self pathToDB] error:nil];
}

+ (SMFeedItem*)feedFromResult:(FMResultSet*)result
{
    NSInteger uid = [result intForColumn:@"id"];
    NSString *lang = [result stringForColumn:@"lang"];
    NSString *country = [result stringForColumn:@"country"];
    NSString *region = [result stringForColumn:@"region"];
    NSString *city = [result stringForColumn:@"city"];
    NSString *category = [result stringForColumn:@"category"];
    NSString *subcategory = [result stringForColumn:@"subcategory"];
    NSString *provider = [result stringForColumn:@"provider"];
    NSString *vocalizing = [result stringForColumn:@"vocalizing"];
    NSString *url = [result stringForColumn:@"url"];
    BOOL selected = [result boolForColumn:@"selected"];
    
    SMFeedItem *item = [SMFeedItem feedWithUid:uid lang:lang country:country region:region city:city category:category subcategory:subcategory provider:provider vocalizing:vocalizing url:url];
    item.selected = selected;
    return item;
}

+ (SMFeedItem*)userFeedFromResult:(FMResultSet*)result
{
    NSInteger uid = [result intForColumn:@"id"];
    NSString *lang = [result stringForColumn:@"lang"];
    NSString *provider = [result stringForColumn:@"provider"];
    NSString *url = [result stringForColumn:@"url"];
    BOOL selected = [result boolForColumn:@"selected"];
    
    SMFeedItem *item = [SMFeedItem userFeedWithUid:uid provider:provider url:url lang:lang];
    item.selected = selected;
    
    return item;
}


#pragma mark - Basic

+ (void)createFeeds
{
    FMDatabase *db = [self db];
    if ([db open]) {
        [db executeUpdate:@"CREATE TABLE IF NOT EXISTS feeds (id INTEGER PRIMARY KEY, lang TEXT, country TEXT, region TEXT, city TEXT, category TEXT, subcategory TEXT, provider TEXT, vocalizing TEXT, url TEXT UNIQUE, selected INTEGER)"];
        [db close];
    }
}

+ (void)insertFeeds:(NSArray *)feeds
{
    FMDatabase *db = [self db];
    if (![db open]) return;
    
    [db beginTransaction];
    for (SMFeedItem *item in feeds) {
        [db executeUpdate:@"INSERT OR IGNORE INTO feeds (lang, country, region, city, category, subcategory, provider, vocalizing, url, selected) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", [item.lang lowercaseString], item.country, item.region, item.city, item.category, item.subcategory, item.provider, item.vocalizing, item.url, @0];
    }
    if (![db commit]) {
        DLog(@"Failed inset into feeds");
    }
    
    [db beginTransaction];
    for (SMFeedItem *item in feeds) {
        [db executeUpdate:@"UPDATE feeds SET lang = ?, country = ?, region = ?, city = ?, category = ?, subcategory = ?, provider = ?, vocalizing = ? WHERE url = ?", [item.lang lowercaseString], item.country, item.region, item.city, item.category, item.subcategory, item.provider, item.vocalizing, item.url];
    }
    if (![db commit]) {
        DLog(@"Failed inset into feeds");
    }
    
    [db close];
}

+ (NSArray*)languagesOfFeeds
{
    FMDatabase *db = [self db];
    if ([db open]) {
        NSMutableArray *languages = [NSMutableArray array];
        FMResultSet *result = [db executeQuery:@"SELECT DISTINCT lang FROM feeds"];
        while ([result next]) {
            [languages addObject:[result stringForColumn:@"lang"]];
        }
        [db close];
        
        return [languages sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    }
    return nil;
}

+ (NSArray*)countryForLanguage:(NSString*)lang
{
    FMDatabase *db = [self db];
    if ([db open]) {
        NSMutableArray *countries = [NSMutableArray array];
        FMResultSet *result = [db executeQuery:@"SELECT DISTINCT country FROM feeds where lang = ? COLLATE NOCASE", lang];
        while ([result next]) {
            [countries addObject:[result stringForColumn:@"country"]];
        }
        [db close];
        
        return [countries sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    }
    return nil;
}

+ (NSArray*)selectedFeeds
{
    FMDatabase *db = [self db];
    if (![db open]) return nil;
    
    NSMutableArray *feeds = [NSMutableArray array];
    FMResultSet *result = [db executeQuery:@"SELECT * FROM feeds WHERE selected = 1"];
    while ([result next]) {
        [feeds addObject:[self feedFromResult:result]];
    }
    
    [db close];
    return feeds;
}

+ (void)setSelectedFeed:(SMFeedItem*)item
{
    [self setSelected:YES feeds:@[item]];
}

+ (void)setSelected:(BOOL)selected feeds:(NSArray *)items
{
    FMDatabase *db = [self db];
    if (![db open]) return;
    
    [db beginTransaction];
    for (SMFeedItem *item in items) {
        [db executeUpdate:@"UPDATE feeds SET selected = ? WHERE id = ?", @(selected), @(item.uid)];
    }
    if (![db commit]) {
        DLog(@"Failed updating feeds");
    }
    
    [db close];
}

+ (NSArray*)allFeeds
{
    FMDatabase *db = [self db];
    if (![db open]) return nil;
    
    NSMutableArray *feeds = [NSMutableArray array];
    FMResultSet *result = [db executeQuery:@"SELECT * FROM feeds"];
    while ([result next]) {
        [feeds addObject:[self feedFromResult:result]];
    }
    
    [db close];
    return feeds;
}

#pragma mark - Main feeds

+ (NSArray*)feedsProvidersForLang:(NSString*)lang country:(NSString*)country
{
    FMDatabase *db = [self db];
    if (![db open]) return nil;
    
    NSMutableArray *providers = [NSMutableArray array];
    FMResultSet *result = [db executeQuery:@"SELECT DISTINCT provider FROM feeds WHERE city = '' AND lang LIKE ? AND country = ?", lang, country];
    while ([result next]) {
        [providers addObject:[result stringForColumn:@"provider"]];
    }
    
    [db close];
    return [providers sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
}

+ (NSArray*)feedsWithoutSubcategoryForProvider:(NSString *)provider lang:(NSString*)lang country:(NSString*)country
{
    FMDatabase *db = [self db];
    if (![db open]) return nil;
    
    NSMutableArray *feeds = [NSMutableArray array];
    FMResultSet *result = [db executeQuery:@"SELECT * FROM feeds WHERE provider = ? AND city = '' AND subcategory = '' AND lang LIKE ? AND country = ?", provider, lang, country];
    while ([result next]) {
        [feeds addObject:[self feedFromResult:result]];
    }
    [db close];
    
    [feeds sortUsingComparator:^NSComparisonResult(SMFeedItem *obj1, SMFeedItem *obj2) {
        return [obj1.category caseInsensitiveCompare:obj2.category];
    }];
    return feeds;
}

+ (NSArray*)subcategoriesForProvider:(NSString*)provider lang:(NSString*)lang country:(NSString*)country
{
    FMDatabase *db = [self db];
    if (![db open]) return nil;
    
    NSMutableArray *subcategories = [NSMutableArray array];
    FMResultSet *result = [db executeQuery:@"SELECT DISTINCT subcategory FROM feeds WHERE provider = ? AND city = '' AND subcategory <> '' AND lang LIKE ? AND country = ?", provider, lang, country];
    while ([result next]) {
        [subcategories addObject:[result stringForColumn:@"subcategory"]];
    }
    
    [db close];
    return [subcategories sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
}

+ (NSArray*)feedsForSubcategory:(NSString*)subcategory provider:(NSString *)provider lang:(NSString*)lang country:(NSString*)country
{
    FMDatabase *db = [self db];
    if (![db open]) return nil;
    
    NSMutableArray *feeds = [NSMutableArray array];
    FMResultSet *result = [db executeQuery:@"SELECT * FROM feeds WHERE provider = ? AND city = '' AND subcategory = ? AND lang LIKE ? AND country = ?", provider, subcategory, lang, country];
    while ([result next]) {
        [feeds addObject:[self feedFromResult:result]];
    }
    
    [db close];
    
    [feeds sortUsingComparator:^NSComparisonResult(SMFeedItem *obj1, SMFeedItem *obj2) {
        return [obj1.category caseInsensitiveCompare:obj2.category];
    }];
    return feeds;
}

#pragma mark - Regional feeds 

+ (NSArray*)feedsCitiesForLang:(NSString*)lang country:(NSString*)country
{
    FMDatabase *db = [self db];
    if (![db open]) return nil;
    
    NSMutableArray *cities = [NSMutableArray array];
    FMResultSet *result = [db executeQuery:@"SELECT DISTINCT city FROM feeds WHERE city <> '' AND lang LIKE ? AND country = ? ", lang, country];
    while ([result next]) {
        [cities addObject:[result stringForColumn:@"city"]];
    }
    
    [db close];
    return [cities sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
}

+ (NSArray*)feedsWithoutSubcategoryForCity:(NSString *)city lang:(NSString*)lang country:(NSString*)country
{
    FMDatabase *db = [self db];
    if (![db open]) return nil;
    
    NSMutableArray *feeds = [NSMutableArray array];
    FMResultSet *result = [db executeQuery:@"SELECT * FROM feeds WHERE city = ? AND subcategory = '' AND lang LIKE ? AND country = ?", city, lang, country];
    while ([result next]) {
        [feeds addObject:[self feedFromResult:result]];
    }
    [db close];
    
    [feeds sortUsingComparator:^NSComparisonResult(SMFeedItem *obj1, SMFeedItem *obj2) {
        return [obj1.category caseInsensitiveCompare:obj2.category];
    }];
    return feeds;
}

+ (NSArray*)subcategoriesForCity:(NSString*)city lang:(NSString*)lang country:(NSString*)country
{
    FMDatabase *db = [self db];
    if (![db open]) return nil;
    
    NSMutableArray *subcategories = [NSMutableArray array];
    FMResultSet *result = [db executeQuery:@"SELECT DISTINCT subcategory FROM feeds WHERE city = ? AND subcategory <> '' AND lang LIKE ? AND country = ?", city, lang, country];
    while ([result next]) {
        [subcategories addObject:[result stringForColumn:@"subcategory"]];
    }
    
    [db close];
    return [subcategories sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
}

+ (NSArray*)feedsForSubcategory:(NSString*)subcategory city:(NSString *)city lang:(NSString*)lang country:(NSString*)country
{
    FMDatabase *db = [self db];
    if (![db open]) return nil;
    
    NSMutableArray *feeds = [NSMutableArray array];
    FMResultSet *result = [db executeQuery:@"SELECT * FROM feeds WHERE city = ? AND subcategory = ? AND lang LIKE ? AND country = ?", city, subcategory, lang, country];
    while ([result next]) {
        [feeds addObject:[self feedFromResult:result]];
    }
    [db close];
    
    [feeds sortUsingComparator:^NSComparisonResult(SMFeedItem *obj1, SMFeedItem *obj2) {
        return [obj1.category caseInsensitiveCompare:obj2.category];
    }];
    return feeds;
}

#pragma mark - User's feeds

+ (void)createUsersFeeds
{
    FMDatabase *db = [self db];
    if ([db open]) {
        [db executeUpdate:@"CREATE TABLE IF NOT EXISTS users_feeds (id INTEGER PRIMARY KEY, lang TEXT, provider TEXT, url TEXT UNIQUE, selected INTEGER DEFAULT 1)"];
        [db close];
    }
}

+ (NSArray*)usersFeeds
{
    FMDatabase *db = [self db];
    if (![db open]) return nil;
    
    NSMutableArray *feeds = [NSMutableArray array];
    FMResultSet *result = [db executeQuery:@"SELECT * FROM users_feeds"];
    while ([result next]) {
        [feeds addObject:[self userFeedFromResult:result]];
    }
    [db close];
    
    [feeds sortUsingComparator:^NSComparisonResult(SMFeedItem *obj1, SMFeedItem *obj2) {
        return [obj1.category caseInsensitiveCompare:obj2.category];
    }];
    return feeds;
}

+ (NSArray*)selectedUsersFeeds
{
    FMDatabase *db = [self db];
    if (![db open]) return nil;
    
    NSMutableArray *feeds = [NSMutableArray array];
    FMResultSet *result = [db executeQuery:@"SELECT * FROM users_feeds WHERE selected = 1"];
    while ([result next]) {
        [feeds addObject:[self userFeedFromResult:result]];
    }
    [db close];
    
    [feeds sortUsingComparator:^NSComparisonResult(SMFeedItem *obj1, SMFeedItem *obj2) {
        return [obj1.category caseInsensitiveCompare:obj2.category];
    }];
    return feeds;
}

+ (void)insertUsersFeed:(SMFeedItem*)feed
{
    FMDatabase *db = [self db];
    if ([db open]) {
        [db executeUpdate:@"INSERT OR REPLACE INTO users_feeds (lang, provider, url) values (?, ?, ?)", feed.lang, feed.provider, feed.url];
        [db close];
    }
}

+ (void)updateUsersFeed:(SMFeedItem*)feed
{
    FMDatabase *db = [self db];
    if ([db open]) {
        [db executeUpdate:@"UPDATE OR REPLACE users_feeds SET lang = ?, provider = ?, url = ?, selected = ? WHERE id = ?", feed.lang, feed.provider, feed.url, @(feed.selected), @(feed.uid)];
        [db close];
    }
}

+ (void)deleteUsersFeed:(SMFeedItem*)feed
{
    FMDatabase *db = [self db];
    if ([db open]) {
        [db executeUpdate:@"DELETE FROM users_feeds WHERE id = ?", @(feed.uid)];
        [db close];
    }
}

@end
