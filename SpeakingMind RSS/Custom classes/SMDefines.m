//
//  SMDefines.m
//  Speind
//
//  Created by Sergey Butenko on 09.07.14.
//  Copyright (c) 2014 serejahh inc. All rights reserved.
//

#import "SMDefines.h"

const NSInteger SMOneDay = 60 * 60 * 24;
const NSInteger SMDefaultInfopointPriority = 3;
const CGFloat SMTableViewCellHeight = 60.0;
const float SMSpeechRate = 0.0625;

/* System */
NSString* const SMBundleVersion = @"CFBundleShortVersionString";
NSString* const SMITunesAppURL = @"https://itunes.apple.com/app/id939502277";

NSString* const SMVoicesProductIDPrefix = @"me.speind.Speind.voices.";
NSString* const SMPluginsProductIDPrefix = @"me.speind.Speind.plugins.";

NSString* const SMTaifunoApiKey = @"a3e50355255741c0ade1643fbecf4596";
NSString* const SMTaifunoUserInfo = @"SMTaifunoUserInfo";
/* System */

/* URLs */
NSString* const SMTwitterURLPrefix = @"sm_twitter";
NSString* const SMFeedbackMail = @"feedback@speind.me";
NSString* const SMURL = @"http://speind.me";
NSString* const SMURLRSSResources = @"http://speind.me/rsssources/";
NSString* const SMURLFeedsList = @"RSS-FeedsList.csv";
NSString* const SMURLVoice = @"http://speind.me/voices/";
NSString* const SMURLVoiceDemo = @"http://speind.me/voices/demos/";
NSString* const SMURLVideoInstruction = @"https://www.youtube.com/watch?v=O4bbOSL4Jb8";
/* URLs */


/* Social */
NSString* const SMTwitterConsumerKey = @"pYqTEFyReNUZs5Gri6scPJNpE";
NSString* const SMTwitterConsumerSecret = @"EQzjRRv5omeAe1sihiMTA6ZvcTS3CnEVtcsyDqvpeR9PkF9Kc7";
const NSUInteger SMTwitterCountTweets = 150;

NSString* const SMVKAppKey = @"4760405";
const NSUInteger SMVKCountPosts = 100;

NSString* const SMFBAppID = @"625834694195969"; 
/* Social */


/* Notifications */
NSString* const SMUnsupportedLocaleNotification = @"UnsupportedDefaultLocale";
NSString* const SMUpdatingIntervalNotification = @"UpdatingIntervalNotification";
NSString* const SMFeedSourcesChangedNofitication = @"FeedSourcesChangedNofitication";
NSString* const SMReadNewsNotification = @"ReadNewsNotification";
NSString* const SMRemoteControlNotification = @"RemoteControlNotification";
NSString* const SMTwitterAuthNotification = @"TwitterAuthNotification";
/* Notifications */


/* Errors */
NSString* const SMVoiceDownloaderErrorDomain = @"SMVoiceDownloaderErrorDomain";
const NSInteger SMVoiceDownloaderNotReachable = 0;
const NSInteger SMVoiceDownloaderSlowConnection = 1;
/* Errors */