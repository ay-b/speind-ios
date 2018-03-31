//
//  SMSettings.m
//  Speind
//
//  Created by Sergey Butenko on 9/23/14.
//  Copyright (c) 2014 serejahh inc. All rights reserved.
//

#import "SMSettings.h"
#import "SMVoice.h"
#import "SMDatabase.h"
#import "SMFeedItem.h"
#import "SMVoiceManager.h"
#import "SMLanguage.h"
#import "UIDevice+Speind.h"

#import <Lockbox/Lockbox.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import <VK-ios-sdk/VKSdk.h>

/*  Key for data in NSUserDefaults */
NSString* const kFirstLaunch = @"FirstLaunch";

NSString* const kLastUpdatingList = @"LastUpdatingList";

NSString* const kReadArticle = @"ReadArticle";
NSString* const kSaveHistory = @"SaveHistory";
NSString* const kSpeechRate = @"SpeechRate";

NSString* const kReadFullArticle = @"ReadFullArticle";
NSString* const kLoadImagesOnlyViaWiFi = @"LoadImagesOnlyViaWiFi";
NSString* const kAlwaysTurnOnScreen = @"AlwaysTurnOnScreen";
NSString* const kFirstVoiceChoosen = @"FirstVoiceDownloaded";
NSString* const kUpdatingInterval = @"UpdatingInterval";
NSString* const kDownloadVoiceOnlyViaWiFi = @"DownloadVoiceOnlyViaWiFi";

NSString* const kTwitterAuthorized = @"TwitterAuthorized";
NSString* const kTwitterAccessToken = @"TwitterAccessToken";
NSString* const kTwitterAccessTokenSecret = @"TwitterAccessTokenSecret";
NSString* const kTwitterEnabled = @"TwitterEnabled";
NSString* const kTWTUpdatingInterval = @"TWTUpdatingInterval";

NSString* const kVKEnabled = @"VKEnabled";
NSString* const kRSSEnabled = @"RSSEnabled";

NSString* const kVKUpdatingInterval = @"VKUpdatingInterval";

NSString* const kPurchasesArray = @"PurchasesArray";
NSString* const kAvailableProducts = @"AvailableProducts";
/*  Key for data in NSUserDefaults */

static const NSTimeInterval kOneMinute = 60;

@interface SMSettings ()

@property (nonatomic) NSArray *readArticleDisplying;

@property (nonatomic) NSArray *saveHistoryDisplying;
@property (nonatomic) NSArray *saveHistoryValues;

@property (nonatomic) NSArray *updatingIntervalDisplying;
@property (nonatomic) NSArray *updatingIntervalValues;

@property (nonatomic) NSArray *speechRateDisplying;
@property (nonatomic) NSArray *speechRateValues;

@property (nonatomic, readwrite) NSArray *supportedLocales;
@property (nonatomic, readwrite) NSArray *supportedLanguages;

@property Lockbox *storage;

@end

@implementation SMSettings

#pragma mark - Arrays

- (NSArray *)readArticleDisplying
{
    if (!_readArticleDisplying) {
        _readArticleDisplying = @[LOC(@"Till the end"), LOC(@"Not more than 1 at once"), LOC(@"Not longer that 5 min"), LOC(@"Not longer that 10 min"), LOC(@"Not longer that 15 min")];
    }
    return _readArticleDisplying;
}

- (NSArray *)saveHistoryDisplying
{
    if (!_saveHistoryDisplying) {
        _saveHistoryDisplying = @[LOC(@"1 day"), LOC(@"3 days")];
    }
    return _saveHistoryDisplying;
}

- (NSArray *)saveHistoryValues
{
    if (!_saveHistoryValues) {
        _saveHistoryValues = @[@1, @3];
    }
    return _saveHistoryValues;
}

- (NSArray *)updatingIntervalDisplying
{
    if (!_updatingIntervalDisplying) {
        _updatingIntervalDisplying = @[LOC(@"5 minutes"), LOC(@"15 minutes"), LOC(@"30 minutes"), LOC(@"1 hour"), LOC(@"5 hours")];
    }
    return _updatingIntervalDisplying;
}

- (NSArray *)updatingIntervalValues
{
    if (!_updatingIntervalValues) {
        _updatingIntervalValues = @[@(5*60), @(15*60), @(30*60), @(60*60), @(5*60*60)];
    }
    return _updatingIntervalValues;
}

- (NSArray *)supportedLocales
{
    if (!_supportedLocales) {
        _supportedLocales = @[@"ru", @"en", @"fr", @"es"];
    }
    return _supportedLocales;
}

- (NSArray*)supportedLanguages
{
    if (!_supportedLanguages) {
        NSArray *langs = [SMDatabase languagesOfFeeds];
        NSMutableSet *feeds = [NSMutableSet set];
        for (NSString *lang in langs) {
            SMLanguage *smLang = [SMLanguage langWithLocaleIdentifier:lang];
            if (smLang) {
                [feeds addObject:smLang];
            }
        }
        
        _supportedLanguages = [feeds.allObjects sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    }
    return _supportedLanguages;
}

#pragma mark -

+ (instancetype)sharedSettings
{
    static SMSettings *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [SMSettings new];
        shared.storage = [[Lockbox alloc] initWithKeyPrefix:@"SpeindPrivate_"];
    });
    return shared;
}

- (void)setDefaults
{
    [self setSelectedUpdatingIntervalIndex:0];
    [self setSelectedSaveHistoryIndex:0];
    [self setSelectedSpeechRateIndex:2];
    [self setLoadImagesOnlyViaWiFi:YES];
    [self setPlugin:SMPluginTypeRSS enabled:YES];
    [self setDownloadVoiceOnlyViaWiFi:YES];
    [self selectDefaultVoices];
}

- (void)updateSettings
{
    double prevVersion = [[NSUserDefaults standardUserDefaults] doubleForKey:@"LastAppVersion"];
    if (prevVersion < 1.1) {
        [self setPlugin:SMPluginTypeRSS enabled:YES];
        [self addPuchaseWithProductID:[SMPlugin rssPlugin].productID];
        [self setDownloadVoiceOnlyViaWiFi:YES];
        [self selectDefaultVoices];
    }
    if (prevVersion < 1.2) {
        [self setSelectedSpeechRateIndex:2];
        [self addPuchaseWithProductID:[SMPlugin vkPlugin].productID];
        [self addPuchaseWithProductID:[SMPlugin twitterPlugin].productID];
    }
    
    double currentVersion = [[[[NSBundle mainBundle] infoDictionary] objectForKey:SMBundleVersion] doubleValue];
    [[NSUserDefaults standardUserDefaults] setDouble:currentVersion forKey:@"LastAppVersion"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)cleanImageCache
{
    NSTimeInterval age = [self selectedSaveHistoryValue] * SMOneDay;
    [[SDImageCache sharedImageCache] setMaxCacheAge:age];
    [[SDImageCache sharedImageCache] cleanDisk];
}

- (void)selectDefaultVoices
{
    NSArray *languages = [[SMVoiceManager sharedManager] availableLanguages];
    for (NSString *language in languages) {
        SMVoice *voice = [SMVoice nativeVoiceForLang:language];
        [[SMSettings sharedSettings] setSelectedVoice:voice];
    }
}

#pragma mark - First launch

- (BOOL)isAlreadyStarted
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"AlreadyStarted"];
}

- (void)setAlreadyStarted
{
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"AlreadyStarted"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)isFirstLaunch
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"FirstLaunch"];
}

- (void)setFirstLaunch
{
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"FirstLaunch"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)selectFirstFeedForLang:(NSString*)lang
{
    NSString *selectedFeed = @"";
    if ([lang isEqualToString:@"ru"]) {
        selectedFeed = @"lenta.ru";
    }
    else if ([lang isEqualToString:@"en"]) {
        selectedFeed = @"http://feeds.bbci.co.uk/news/world/rss.xml";
    }
    else if ([lang isEqualToString:@"es"]) {
        selectedFeed = @"http://ep00.epimg.net/rss/internacional/portada.xml";
    }
    else if ([lang isEqualToString:@"fr"]) {
        selectedFeed = @"http://www.leparisien.fr/international/rss.xml";
    }
    
    NSArray *feeds = [SMDatabase allFeeds];
    for (SMFeedItem *feed in feeds) {
        NSRange range = [feed.url rangeOfString:selectedFeed];
        if (range.location != NSNotFound) {
            [SMDatabase setSelectedFeed:feed];
            break;
        }
    }
}

#pragma mark - Last updating list

- (void)setLastUpdatingList:(NSDate*)date
{
    [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:kLastUpdatingList];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSDate*)lastUpdatingList
{
    NSDate *date = [[NSUserDefaults standardUserDefaults] objectForKey:kLastUpdatingList];
    return date;
}

#pragma mark - Read article

- (NSArray*)readArticleDisplaying
{
    return self.readArticleDisplying;
}

- (NSInteger)selectedReadArticleIndex
{
    NSInteger index = [[NSUserDefaults standardUserDefaults] integerForKey:kReadArticle];
    return index;
}

- (void)setSelectedReadArticleValue:(NSInteger)index
{
    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:kReadArticle];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (SMReadArticleType)selectedReadArticleValue
{
    NSInteger index = [[NSUserDefaults standardUserDefaults] integerForKey:kReadArticle];
    return (SMReadArticleType)index;
}

- (NSTimeInterval)timeForReadArticleValue:(SMReadArticleType)value
{
    if (value == SMReadArticleFiveMinutes) {
        return 5 * kOneMinute;
    }
    else if (value == SMReadArticleTenMinutes) {
        return 10 * kOneMinute;
    }
    else if (value == SMReadArticleFifteenMinutes) {
        return 15 * kOneMinute;
    }
    return 0;
}

#pragma mark - Speech rate

- (NSArray*)speechRateDisplaying
{
    if (!_speechRateDisplying) {
        _speechRateDisplying = @[@"x0.5", @"x0.75", @"x1", @"x1.25", @"x1.5", @"x2"];
    }
    return _speechRateDisplying;
}

- (NSInteger)selectedSpeechRateIndex
{
    NSInteger index = [[NSUserDefaults standardUserDefaults] integerForKey:kSpeechRate];
    return index;
}

- (void)setSelectedSpeechRateIndex:(NSInteger)index
{
    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:kSpeechRate];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString*)selectedSpeechRateValue
{
    NSInteger index = [[NSUserDefaults standardUserDefaults] integerForKey:kSpeechRate];
    return [[self speechRateDisplaying] objectAtIndex:index];
}

- (double)selectedSpeechRate
{
    NSInteger index = [[NSUserDefaults standardUserDefaults] integerForKey:kSpeechRate];
    NSNumber *rate = [[self speechRatesValue] objectAtIndex:index];
    return [rate doubleValue];
}

- (NSArray *)speechRatesValue
{
    if (!_speechRateValues) {
        _speechRateValues = @[@(0.5), @(0.75), @(1.0), @(1.25), @(1.5), @(2.0)];
    }
    return _speechRateValues;
}

#pragma mark - Save history

- (NSArray *)saveHistoryDisplaying
{
    return self.saveHistoryDisplying;
}

- (NSInteger)selectedSaveHistoryValue;
{
    NSInteger index = [[NSUserDefaults standardUserDefaults] integerForKey:kSaveHistory];
    return [self.saveHistoryValues[index] intValue];
}

- (NSInteger)selectedSaveHistoryIndex
{
    NSInteger index = [[NSUserDefaults standardUserDefaults] integerForKey:kSaveHistory];
    return index;
}

- (void)setSelectedSaveHistoryIndex:(NSInteger)index
{
    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:kSaveHistory];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - Updating interval

- (NSArray*)updatingIntervalDisplaying
{
    return self.updatingIntervalDisplying;
}

- (NSInteger)selectedUpdatingIntervalIndex
{
    return [[NSUserDefaults standardUserDefaults] integerForKey:kUpdatingInterval];
}

- (NSInteger)selectedUpdatingIntervalValue
{
    NSInteger index = [self selectedUpdatingIntervalIndex];
    return [[self.updatingIntervalValues objectAtIndex:index] intValue];
}

- (void)setSelectedUpdatingIntervalIndex:(NSInteger)index
{
    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:kUpdatingInterval];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - Selected voice

#define kPrefixForSelectedLanguage @"SMSelectedVoiceFor%@"
#define kPrefixForSelectedLanguageTTS @"SMSelectedVoiceIsNativeFor%@"

- (NSString*)selectedVoiceForLanguage:(NSString*)language
{
    if (!language) return nil;
    
    NSString *key = [NSString stringWithFormat:kPrefixForSelectedLanguage, language];
    return [[NSUserDefaults standardUserDefaults] stringForKey:key];
}

- (void)setSelectedVoice:(SMVoice*)voice
{
    if (!voice) return;
    
    NSString *keyVoice = [NSString stringWithFormat:kPrefixForSelectedLanguage, voice.storedUid];
    [[NSUserDefaults standardUserDefaults] setObject:voice.storedValue forKey:keyVoice];
    
    NSString *keyTTS = [NSString stringWithFormat:kPrefixForSelectedLanguageTTS, voice.storedUid];
    [[NSUserDefaults standardUserDefaults] setBool:voice.isNativeVoice forKey:keyTTS];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)isNativeTTSForLanguage:(NSString*)language
{
    if (!language) return NO;
    
    NSString *key = [NSString stringWithFormat:kPrefixForSelectedLanguageTTS, language];
    return [[NSUserDefaults standardUserDefaults] boolForKey:key];
}

- (NSArray*)currentVoices
{
    NSMutableArray *voices = [NSMutableArray array];
    for (NSString *lang in self.supportedLocales) {
        NSString *key = [NSString stringWithFormat:kPrefixForSelectedLanguage, lang];
        NSString *voice = [[NSUserDefaults standardUserDefaults] stringForKey:key];
        if (voice) {
            [voices addObject:voice];
        }
    }
    
    return voices;
}

#pragma mark - Read full article

- (BOOL)isReadFullArticle
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:kReadFullArticle];
}

- (void)setReadFullArticle:(BOOL)state
{
    [[NSUserDefaults standardUserDefaults] setBool:state forKey:kReadFullArticle];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - Load images only via WiFi

- (BOOL)isLoadImagesOnlyViaWiFi
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:kLoadImagesOnlyViaWiFi];
}

- (void)setLoadImagesOnlyViaWiFi:(BOOL)state
{
    [[NSUserDefaults standardUserDefaults] setBool:state forKey:kLoadImagesOnlyViaWiFi];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - Download voices only via WiFi

- (BOOL)isDownloadVoiceOnlyViaWiFi
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:kDownloadVoiceOnlyViaWiFi];
}

- (void)setDownloadVoiceOnlyViaWiFi:(BOOL)state
{
    [[NSUserDefaults standardUserDefaults] setBool:state forKey:kDownloadVoiceOnlyViaWiFi];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - Always turn on screen

- (BOOL)isAlwaysTurnOnScreen
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:kAlwaysTurnOnScreen];
}

- (void)setAlwaysTurnOnScreen:(BOOL)state
{
    [[UIApplication sharedApplication] setIdleTimerDisabled:state];
    
    [[NSUserDefaults standardUserDefaults] setBool:state forKey:kAlwaysTurnOnScreen];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - FirstVoiceDownloaded

- (BOOL)isFirstVoiceChoosen
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:kFirstVoiceChoosen];
}

- (void)firstVoiceChoosen
{
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kFirstVoiceChoosen];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - Social
#pragma mark Twitter

- (BOOL)isTwitterAuthorized
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:kTwitterAuthorized];
}

- (void)setTwitterAccessToken:(NSString*)accessToken accessTokenSecret:(NSString*)accessTokenSecret
{
    [Lockbox setString:accessToken forKey:kTwitterAccessToken];
    [Lockbox setString:accessTokenSecret forKey:kTwitterAccessTokenSecret];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kTwitterAuthorized];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setTwitterPluginLogout
{
    [Lockbox setString:nil forKey:kTwitterAccessToken];
    [Lockbox setString:nil forKey:kTwitterAccessTokenSecret];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kTwitterAuthorized];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString*)twitterAccessToken
{
    return [Lockbox stringForKey:kTwitterAccessToken];
}

- (NSString*)twitterAccessTokenSecret
{
    return [Lockbox stringForKey:kTwitterAccessTokenSecret];
}

- (BOOL)isTwitterPluginEnabled
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:kTwitterEnabled];
}

- (void)setTwitterPluginEnabled:(BOOL)enabled
{
    [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:kTwitterEnabled];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark VK

- (BOOL)isVKPluginEnabled
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:kVKEnabled];
}

- (void)setVKPluginEnabled:(BOOL)enabled
{
    [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:kVKEnabled];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)isVKAuthorized
{
    return [VKSdk isLoggedIn];
}

#pragma mark - Purchases

- (void)addPuchaseWithProductID:(NSString*)productID
{
    NSMutableSet *purchases = [[Lockbox setForKey:kPurchasesArray] mutableCopy];
    if (!purchases) {
        purchases = [NSMutableSet set];
    }
    [purchases addObject:productID];
    [Lockbox setSet:purchases forKey:kPurchasesArray];
}

- (NSArray*)purchases
{
    return [Lockbox setForKey:kPurchasesArray].allObjects;
}

- (BOOL)isProductPurchased:(NSString*)productID
{
    NSMutableSet *purchases = [[Lockbox setForKey:kPurchasesArray] mutableCopy];
    for (NSString *uid in purchases) {
        if ([uid isEqualToString:productID]) {
            return YES;
        }
    }
    
    return NO;
}

- (NSArray*)inavailableProducts
{
    NSArray *arr = [[NSUserDefaults standardUserDefaults] arrayForKey:kAvailableProducts];
    return arr ? arr : @[];
}

- (void)setInavailableProducts:(NSArray*)products
{
    [[NSUserDefaults standardUserDefaults] setObject:products forKey:kAvailableProducts];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


- (BOOL)isPluginEnabled:(SMPluginType)plugin
{
    BOOL on = NO;
    switch (plugin) {
        case SMPluginTypeRSS:
            on = [[SMSettings sharedSettings] isRSSPluginEnabled];
            break;
        case SMPluginTypeTwitter:
            on = [[SMSettings sharedSettings] isTwitterPluginEnabled];
            break;
        case SMPluginTypeVK:
            on = [[SMSettings sharedSettings] isVKPluginEnabled];
            break;
    }
    return on;
}

- (void)setPlugin:(SMPluginType)plugin enabled:(BOOL)enabled
{
    switch (plugin) {
        case SMPluginTypeRSS:
            [[SMSettings sharedSettings] setRSSPluginEnabled:enabled];
            break;
        case SMPluginTypeTwitter:
            [[SMSettings sharedSettings] setTwitterPluginEnabled:enabled];
            break;
        case SMPluginTypeVK:
            [[SMSettings sharedSettings] setVKPluginEnabled:enabled];
            break;
    }
}

- (BOOL)isRSSPluginEnabled
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:kRSSEnabled];
}

- (void)setRSSPluginEnabled:(BOOL)enabled
{
    [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:kRSSEnabled];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString*)taifunoUserInfo
{
    NSMutableString *info = [NSMutableString string];
    
    NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:SMBundleVersion];
    NSString *build = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    [info appendFormat:@"App name: %@ %@ (%@);\n", appName, version, build];
    
    [info appendFormat:@"Device: %@;\n", [[UIDevice currentDevice] sm_deviceName]];
    [info appendFormat:@"OS: iOS %@;\n", [[UIDevice currentDevice] systemVersion]];
    
    return [info copy];
}

@end