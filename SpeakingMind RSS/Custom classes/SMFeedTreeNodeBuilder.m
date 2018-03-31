//
//  SMFeedTreeNodeBuilder.m
//  Speind
//
//  Created by Sergey Butenko on 25.06.14.
//  Copyright (c) 2014 serejahh inc. All rights reserved.
//

#import "SMFeedTreeNodeBuilder.h"
#import "SMFeedTreeNode.h"
#import "SMDatabase.h"

/*
 Главные:
    подкатегории без городов
        категории для подкатегорий^
            потоки для подкатегории^ и категории^
    категории без подкатегорий
        потоки без подкатегории^ и с категорией^

 Региональные:
    города
        подкатегории для города^
            категории для подкатегории^
                потоки для подкатегории^ и категории^
        категории без под категории для города
            потоки без подкатегории^ и с категорией^
*/

@interface SMFeedTreeNodeBuilder ()

@property (nonatomic) NSString *lang;
@property (nonatomic) NSString *country;

/**
 * Провайдеры главных новостей.
 */
- (NSArray*)p_providers;
- (NSArray*)p_mainFeedWithoutSubcategoryForProvider:(NSString*)provider;
- (NSArray*)p_mainFeedWithSubcategoryForProvider:(NSString*)provider;

/**
 * Города, представленные, представленные в региональных новостях.
 */
- (NSArray*)p_cities;
- (NSArray*)p_regionalFeedWithoutSubcategoryForCity:(NSString*)city;
- (NSArray*)p_regionalFeedWithSubcategoryForCity:(NSString*)city;

@end

@implementation SMFeedTreeNodeBuilder

+ (instancetype)sharedBuilder
{
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{
        instance = [self new];
    });
    return instance;
}

- (NSArray*)feedForLang:(NSString*)lang country:(NSString*)country
{
    self.lang = lang;
    self.country = country;
    
    NSArray *providers = [self p_providers];
    NSArray *cities = [self p_cities];
    
    NSMutableArray *resultFeed = [NSMutableArray array];
    if (providers.count > 0) {
        SMFeedTreeNode *mainFeed = [SMFeedTreeNode dataObjectWithName:LOC(@"Main news") children:providers];
        [resultFeed addObject:mainFeed];
    }
    if (cities.count > 0) {
        SMFeedTreeNode *regionalFeed = [SMFeedTreeNode dataObjectWithName:LOC(@"Regional news") children:cities];
        [resultFeed addObject:regionalFeed];
    }
    return resultFeed;
}

#pragma mark - Main feeds

- (NSArray*)p_providers
{
    NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
    NSMutableArray *providersResult = [NSMutableArray array];
    NSArray *providers = [SMDatabase feedsProvidersForLang:self.lang country:self.country];
    
    for (NSString *provider in providers) {
        NSMutableSet *childrenForProvider = [NSMutableSet set];
        [childrenForProvider addObjectsFromArray:[self p_mainFeedWithSubcategoryForProvider:provider]]; // higher priority than without subcategory
        [childrenForProvider addObjectsFromArray:[self p_mainFeedWithoutSubcategoryForProvider:provider]];
        NSArray *children = [childrenForProvider.allObjects sortedArrayUsingDescriptors:@[descriptor]];
        
        SMFeedTreeNode *providerData = [SMFeedTreeNode dataObjectWithName:provider children:children];
        [providersResult addObject:providerData];
    }
    [providersResult sortUsingDescriptors:@[descriptor]];
    
    return providersResult;
}

- (NSArray*)p_mainFeedWithoutSubcategoryForProvider:(NSString*)provider
{
    NSMutableArray *childrenForProvider = [NSMutableArray array];
    NSArray *feeds = [SMDatabase feedsWithoutSubcategoryForProvider:provider lang:self.lang country:self.country];

    for (SMFeedItem *feed in feeds) {
        SMFeedTreeNode *feedData = [SMFeedTreeNode dataObjectWithName:feed.category feed:feed];
        [childrenForProvider addObject:feedData];
    }
    
    return childrenForProvider;
}

- (NSArray*)p_mainFeedWithSubcategoryForProvider:(NSString*)provider
{
    NSArray *subcategories = [SMDatabase subcategoriesForProvider:provider lang:self.lang country:self.country];
    NSMutableArray *childrenForSubcategory = [NSMutableArray array];
    
    for (NSString *subcategory in subcategories) {
        NSArray *feeds = [SMDatabase feedsForSubcategory:subcategory provider:provider lang:self.lang country:self.country];

        NSMutableArray *childrenForProvider = [NSMutableArray array];
        for (SMFeedItem *feed in feeds) {
            SMFeedTreeNode *feedData = [SMFeedTreeNode dataObjectWithName:feed.category feed:feed];
            [childrenForProvider addObject:feedData];
        }
        SMFeedTreeNode *subcategoryData = [SMFeedTreeNode dataObjectWithName:subcategory children:childrenForProvider];
        [childrenForSubcategory addObject:subcategoryData];
    }

    return childrenForSubcategory;
}

#pragma mark - Regional feeds

- (NSArray*)p_cities
{
    NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
    NSMutableArray *citiesResult = [NSMutableArray array];
    NSArray *cities = [SMDatabase feedsCitiesForLang:self.lang country:self.country];
    
    for (NSString *city in cities) {
        NSMutableSet *childrenForCity = [NSMutableSet set];
        [childrenForCity addObjectsFromArray:[self p_regionalFeedWithSubcategoryForCity:city]];
        [childrenForCity addObjectsFromArray:[self p_regionalFeedWithoutSubcategoryForCity:city]];
        NSArray *children = [childrenForCity.allObjects sortedArrayUsingDescriptors:@[descriptor]];
        
        SMFeedTreeNode *cityData = [SMFeedTreeNode dataObjectWithName:city children:children];
        [citiesResult addObject:cityData];
    }
    [citiesResult sortUsingDescriptors:@[descriptor]];
    
    return citiesResult;
}

- (NSArray*)p_regionalFeedWithoutSubcategoryForCity:(NSString*)city
{
    NSMutableSet *childrenForProvider = [NSMutableSet set];
    NSArray *feeds = [SMDatabase feedsWithoutSubcategoryForCity:city lang:self.lang country:self.country];
    
    for (SMFeedItem *feed in feeds) {
        SMFeedTreeNode *feedData = [SMFeedTreeNode dataObjectWithName:feed.category feed:feed];
        [childrenForProvider addObject:feedData];
    }
    NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
    NSArray *children = [childrenForProvider.allObjects sortedArrayUsingDescriptors:@[descriptor]];
    
    return children;
}

- (NSArray*)p_regionalFeedWithSubcategoryForCity:(NSString*)city
{
    NSArray *subcategories = [SMDatabase subcategoriesForCity:city lang:self.lang country:self.country];
    NSMutableArray *childrenForSubcategory = [NSMutableArray array];
    
    for (NSString *subcategory in subcategories) {
        NSArray *feeds = [SMDatabase feedsForSubcategory:subcategory city:city lang:self.lang country:self.country];
        
        NSMutableArray *childrenForProvider = [NSMutableArray array];
        for (SMFeedItem *feed in feeds) {
            SMFeedTreeNode *feedData = [SMFeedTreeNode dataObjectWithName:feed.category feed:feed];
            [childrenForProvider addObject:feedData];
        }
        SMFeedTreeNode *subcategoryData = [SMFeedTreeNode dataObjectWithName:subcategory children:childrenForProvider];
        [childrenForSubcategory addObject:subcategoryData];
    }
    
    return childrenForSubcategory;
}

@end
