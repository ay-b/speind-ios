//
//  SMDatabase.h
//  Speind
//
//  Created by Sergey Butenko on 24.06.14.
//  Copyright (c) 2014 serejahh inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SMFeedItem;

@interface SMDatabase : NSObject

#pragma mark - Basic

+ (void)createFeeds;
+ (void)insertFeeds:(NSArray *)feeds;
+ (NSArray*)languagesOfFeeds;
+ (NSArray*)countryForLanguage:(NSString*)lang;
+ (NSArray*)selectedFeeds;
+ (void)setSelectedFeed:(SMFeedItem*)item;
+ (void)setSelected:(BOOL)selected feeds:(NSArray*)items;
+ (NSArray*)allFeeds;

#pragma mark Main feeds

+ (NSArray*)feedsProvidersForLang:(NSString*)lang country:(NSString*)country;
+ (NSArray*)feedsWithoutSubcategoryForProvider:(NSString *)provider lang:(NSString*)lang country:(NSString*)country;
+ (NSArray*)subcategoriesForProvider:(NSString*)provider lang:(NSString*)lang country:(NSString*)country;
+ (NSArray*)feedsForSubcategory:(NSString*)subcategory provider:(NSString *)provider lang:(NSString*)lang country:(NSString*)country;

#pragma mark Regional feeds

+ (NSArray*)feedsCitiesForLang:(NSString*)lang country:(NSString*)country;
+ (NSArray*)feedsWithoutSubcategoryForCity:(NSString *)city lang:(NSString*)lang country:(NSString*)country;
+ (NSArray*)subcategoriesForCity:(NSString*)city lang:(NSString*)lang country:(NSString*)country;
+ (NSArray*)feedsForSubcategory:(NSString*)subcategory city:(NSString *)city lang:(NSString*)lang country:(NSString*)country;

#pragma mark - User's feeds

+ (void)createUsersFeeds;
+ (NSArray*)usersFeeds;
+ (NSArray*)selectedUsersFeeds;
+ (void)insertUsersFeed:(SMFeedItem*)feed;
+ (void)updateUsersFeed:(SMFeedItem*)feed;
+ (void)deleteUsersFeed:(SMFeedItem*)feed;

@end
