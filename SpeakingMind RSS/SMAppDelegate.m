//
//  SMAppDelegate.m
//  SpeakingMind RSS
//
//  Created by Sergey Butenko on 02.06.14.
//  Copyright (c) 2014 serejahh inc. All rights reserved.
//

#import "SMAppDelegate.h"
#import "SMListsDownloader.h"
#import "SMFeedItem.h"
#import "SMVoicesDownloader.h"
#import "STTwitterAPI+Speind.h"

#import "VKSdk.h"
#import "AcapelaSpeech.h"
#import "TFTaifuno.h"
#import <FacebookSDK/FacebookSDK.h>
#import <AFNetworking/AFNetworkActivityIndicatorManager.h>
#import <AFNetworking/AFNetworkReachabilityManager.h>
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>

static const int kMinimalUpdatingInterval = 1;
static const int kNoBadges = 0;

@interface SMAppDelegate () <UIApplicationDelegate, SMListsDownloaderDelegate>

@property (nonatomic) SMListsDownloader *listsDownloader;

@end

@implementation SMAppDelegate

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (void)remoteControlReceivedWithEvent:(UIEvent *)receivedEvent
{
    [[NSNotificationCenter defaultCenter] postNotificationName:SMRemoteControlNotification object:receivedEvent];
}

#pragma mark - Application delegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    [Fabric with:@[CrashlyticsKit]];
    [[TFTaifuno sharedInstance] setApiKey:SMTaifunoApiKey];
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [self becomeFirstResponder];
    [self p_requestRegisterNotifications];
    [[UIApplication sharedApplication] setIdleTimerDisabled:[[SMSettings sharedSettings] isAlwaysTurnOnScreen]];

    [[SMSettings sharedSettings] updateSettings];
    [AcapelaSpeech setVoicesDirectoryArray:@[DOCUMENTS_DIRECTORY]];
    
    // there may be no Taifuno push; not necessary to synchronize
    NSDictionary *userInfo = launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey];
    [[NSUserDefaults standardUserDefaults] setObject:userInfo forKey:SMTaifunoUserInfo];
    
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    application.applicationIconBadgeNumber = kNoBadges;
    [FBAppEvents activateApp];
    [FBAppCall handleDidBecomeActive];
    [[SMSettings sharedSettings] cleanImageCache];
    [[TFTaifuno sharedInstance] didBecomeActive];
    
    NSDate *lastUpdateDate = [[SMSettings sharedSettings] lastUpdatingList];
    int agoDays = [[NSDate date] timeIntervalSinceDate:lastUpdateDate] / SMOneDay;
    if (agoDays >= kMinimalUpdatingInterval || !lastUpdateDate) {
        [self.listsDownloader updateFeedsList];
    }
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [FBSession.activeSession close];
    [[SMVoicesDownloader downloader] cancelByProducingResumeData];
    [SMVoicesDownloader removeTrashFromDocuments];
    [[TFTaifuno sharedInstance] saveTaifuno];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    if ([[url scheme] hasPrefix:[NSString stringWithFormat:@"vk%@", SMVKAppKey]]) {
        return [VKSdk processOpenURL:url fromApplication:sourceApplication];
    }
    else if ([[url scheme] hasPrefix:[NSString stringWithFormat:@"fb%@", SMFBAppID]]) {
        return [FBAppCall handleOpenURL:url sourceApplication:sourceApplication];
    }
    else if ([[url scheme] hasPrefix:SMTwitterURLPrefix]) {
        return [STTwitterAPI sm_handleTwitterOpenURL:url sourceApplication:sourceApplication];
    }
    return YES;
}

#pragma mark - Push notifications

- (void)p_requestRegisterNotifications
{
    UIApplication *application = [UIApplication sharedApplication];
    
    if ([application respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert) categories:nil];
        [application registerUserNotificationSettings:settings];
    }
    else {
        [application registerForRemoteNotificationTypes:UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound];
    }
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    NSString *token = [[[[deviceToken description] stringByReplacingOccurrencesOfString:@"<" withString:@""] stringByReplacingOccurrencesOfString:@">" withString:@""] stringByReplacingOccurrencesOfString:@" " withString:@""];
    [[TFTaifuno sharedInstance] registerDeviceToken:token];
    
    DLog(@"Push token is: %@", token);
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    DLog(@"Failed to get push token: %@", error);
}

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
{
    [application registerForRemoteNotifications];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    [[TFTaifuno sharedInstance] didRecieveNewNotification:userInfo];
    if ([[UIApplication sharedApplication] applicationState] != UIApplicationStateActive) {
        [[TFTaifuno sharedInstance] startChatOnViewController:self.window.rootViewController withInfo:[[SMSettings sharedSettings] taifunoUserInfo]];
    }
}

#pragma mark - SMListsDownloader Delegate

- (void)listsDownloaderDidFinishDownloading:(SMListsDownloader*)downloader
{
    DLog(@"All feed lists updated");
    [[SMSettings sharedSettings] setLastUpdatingList:[NSDate date]];
}

- (SMListsDownloader *)listsDownloader
{
    if (!_listsDownloader) {
        _listsDownloader = [[SMListsDownloader alloc] initWithDelegate:self];
    }
    return _listsDownloader;
}

@end
