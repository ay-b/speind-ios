//
//  SMDefines.h
//  Speind
//
//  Created by Sergey Butenko on 09.07.14.
//  Copyright (c) 2014 serejahh inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SMSettings.h"

#define SMHasMoreThanTreeInchDisplay [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone && [UIScreen mainScreen].bounds.size.height >= 568.0
#define SMiOS8 [[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0f

#define DOCUMENTS_DIRECTORY [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) firstObject]

#define SMGrayColor [UIColor colorWithRed:211/255.0 green:216/255.0 blue:217/255.0 alpha:1]
#define SMLightGrayColor [UIColor colorWithRed:0.89 green:0.91 blue:0.91 alpha:1]
#define SMDarkGrayColor [UIColor colorWithRed:0.68 green:0.71 blue:0.71 alpha:1]
#define SMBlueColor [UIColor colorWithRed:40/255.0 green:193/255.0 blue:226/255.0 alpha:1]
#define SMRedColor [UIColor colorWithRed:251/255.0 green:86/255.0 blue:66/255.0 alpha:1]

extern const NSInteger SMOneDay;
extern const NSInteger SMDefaultInfopointPriority;
extern const CGFloat SMTableViewCellHeight;
extern const float SMSpeechRate;

/* System */
extern NSString* const SMBundleVersion;
extern NSString* const SMITunesAppURL;

extern NSString* const SMVoicesProductIDPrefix;
extern NSString* const SMPluginsProductIDPrefix;

extern NSString* const SMTaifunoApiKey;
extern NSString* const SMTaifunoUserInfo;
/* System */

 
/* URLs */
extern NSString* const SMTwitterURLPrefix;
extern NSString* const SMFeedbackMail;
extern NSString* const SMURL;
extern NSString* const SMURLRSSResources;
extern NSString* const SMURLFeedsList;
extern NSString* const SMURLVoice;
extern NSString* const SMURLVoiceDemo;
extern NSString* const SMURLVideoInstruction;
/* URLs */


/* Social */
extern NSString* const SMTwitterConsumerKey;
extern NSString* const SMTwitterConsumerSecret;
extern const NSUInteger SMTwitterCountTweets;

extern NSString* const SMVKAppKey;
extern const NSUInteger SMVKCountPosts;

extern NSString* const SMFBAppID;
/* Social */


/* Notifications */
extern NSString* const SMUnsupportedLocaleNotification;
extern NSString* const SMUpdatingIntervalNotification;
extern NSString* const SMFeedSourcesChangedNofitication;
extern NSString* const SMReadNewsNotification;
extern NSString* const SMRemoteControlNotification;
extern NSString* const SMTwitterAuthNotification;
/* Notifications */


/* Errors */
extern NSString* const SMVoiceDownloaderErrorDomain;
extern const NSInteger SMVoiceDownloaderNotReachable;
extern const NSInteger SMVoiceDownloaderSlowConnection;
/* Errors */


typedef enum : NSUInteger {
    SMAddFeedStateCorrect,
    SMAddFeedStateIncorrectURL,
    SMAddFeedStateNoData,
    SMAddFeedStateNotReachable
} SMAddFeedState;


#ifdef DEBUG
#   define DLog(x, ...) NSLog((@"%s [Line %d] " x), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
#   define DLog(x, ...)
#endif

#define LOC(key) NSLocalizedString((key), @"")