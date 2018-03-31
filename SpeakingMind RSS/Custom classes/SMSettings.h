//
//  SMSettings.h
//  Speind
//
//  Created by Sergey Butenko on 9/23/14.
//  Copyright (c) 2014 serejahh inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SMPlugin.h"

@class SMVoice;

typedef NS_ENUM(NSUInteger, SMReadArticleType) {
    SMReadArticleAll,
    SMReadArticleOne,
    SMReadArticleFiveMinutes,
    SMReadArticleTenMinutes,
    SMReadArticleFifteenMinutes
};

@interface SMSettings : NSObject

+ (instancetype)sharedSettings;
- (void)setDefaults;
- (void)updateSettings;
- (void)cleanImageCache;
- (void)selectDefaultVoices;

- (NSString*)taifunoUserInfo;

@property (nonatomic, readonly) NSArray *supportedLanguages;
@property (nonatomic, readonly) NSArray *supportedLocales;

#pragma mark - First launch

- (BOOL)isAlreadyStarted;
- (void)setAlreadyStarted;
- (BOOL)isFirstLaunch;
- (void)setFirstLaunch;
- (void)selectFirstFeedForLang:(NSString*)lang;

#pragma mark - Last updating list

- (void)setLastUpdatingList:(NSDate*)date;
- (NSDate*)lastUpdatingList;

#pragma mark - Speech rate

- (NSArray*)speechRateDisplaying;
- (NSInteger)selectedSpeechRateIndex;
- (NSString*)selectedSpeechRateValue;
- (void)setSelectedSpeechRateIndex:(NSInteger)index;
- (double)selectedSpeechRate;

#pragma mark - Read article

- (NSArray*)readArticleDisplaying;
- (NSInteger)selectedReadArticleIndex;
- (void)setSelectedReadArticleValue:(NSInteger)index;
- (SMReadArticleType)selectedReadArticleValue;
- (NSTimeInterval)timeForReadArticleValue:(SMReadArticleType)value;

#pragma mark - Save history

- (NSArray*)saveHistoryDisplaying;
- (NSInteger)selectedSaveHistoryIndex;
- (NSInteger)selectedSaveHistoryValue;
- (void)setSelectedSaveHistoryIndex:(NSInteger)index;

#pragma mark - Updating interval

- (NSArray*)updatingIntervalDisplaying;
- (NSInteger)selectedUpdatingIntervalIndex;
- (NSInteger)selectedUpdatingIntervalValue;
- (void)setSelectedUpdatingIntervalIndex:(NSInteger)index;

#pragma mark - Selected voice

- (NSString*)selectedVoiceForLanguage:(NSString*)language;
- (void)setSelectedVoice:(SMVoice*)voice;
- (BOOL)isNativeTTSForLanguage:(NSString*)language;
- (NSArray*)currentVoices;

#pragma mark - Read full article

- (BOOL)isReadFullArticle;
- (void)setReadFullArticle:(BOOL)read;

#pragma mark - Load images only via WiFi

- (BOOL)isLoadImagesOnlyViaWiFi;
- (void)setLoadImagesOnlyViaWiFi:(BOOL)state;

#pragma mark - Download voices only via WiFi

- (BOOL)isDownloadVoiceOnlyViaWiFi;
- (void)setDownloadVoiceOnlyViaWiFi:(BOOL)state;

#pragma mark - Always turn on screen

- (BOOL)isAlwaysTurnOnScreen;
- (void)setAlwaysTurnOnScreen:(BOOL)state;

#pragma mark - FirstVoiceDownloaded

- (BOOL)isFirstVoiceChoosen;
- (void)firstVoiceChoosen;

#pragma mark - Plugins

- (BOOL)isPluginEnabled:(SMPluginType)plugin;
- (void)setPlugin:(SMPluginType)plugin enabled:(BOOL)enabled;

#pragma mark Twitter

- (BOOL)isTwitterPluginEnabled;
- (void)setTwitterPluginEnabled:(BOOL)enabled;
- (BOOL)isTwitterAuthorized;
- (void)setTwitterAccessToken:(NSString*)accessToken accessTokenSecret:(NSString*)accessTokenSecret;
- (NSString*)twitterAccessToken;
- (NSString*)twitterAccessTokenSecret;
- (void)setTwitterPluginLogout;

#pragma mark VK

- (BOOL)isVKPluginEnabled;
- (void)setVKPluginEnabled:(BOOL)enabled;
- (BOOL)isVKAuthorized;

#pragma mark RSS

- (BOOL)isRSSPluginEnabled;
- (void)setRSSPluginEnabled:(BOOL)enabled;

#pragma mark - Purchases

- (void)addPuchaseWithProductID:(NSString*)productID;
- (NSArray*)purchases;
- (BOOL)isProductPurchased:(NSString*)productID;

- (NSArray*)inavailableProducts;
- (void)setInavailableProducts:(NSArray*)products;

@end