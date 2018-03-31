//
//  SMPluginVKViewController.m
//  SpeakingMind RSS
//
//  Created by Sergey Butenko on 10/6/14.
//  Copyright (c) 2014 Speaking Mind. All rights reserved.
//

#import "SMPluginVKViewController.h"
#import <VK-ios-sdk/VKSdk.h>

@interface SMPluginVKViewController () <VKSdkDelegate>
@end

@implementation SMPluginVKViewController

- (void)viewDidLoad
{
    [VKSdk initializeWithDelegate:self andAppId:SMVKAppKey];
    [VKSdk wakeUpSession];
    
    [super viewDidLoad];
    self.navigationItem.title = LOC(@"Vkontakte");
}

- (void)p_loggedIn:(BOOL)logged
{
    if (logged) {
        self.needsUpdateFeeds = YES;
        [[SMSettings sharedSettings] setVKPluginEnabled:YES];
    }
    else {
        [VKSdk forceLogout];
    }
    [[SMSettings sharedSettings] setVKPluginEnabled:logged];
    [self updateView];
}

#pragma mark - VK SDK Delegate

- (void)vkSdkNeedCaptchaEnter:(VKError *)captchaError {}

- (void)vkSdkTokenHasExpired:(VKAccessToken *)expiredToken {}

- (void)vkSdkUserDeniedAccess:(VKError *)authorizationError {}

- (void)vkSdkShouldPresentViewController:(UIViewController *)controller
{
    [self presentViewController:controller animated:YES completion:nil];
}

- (void)vkSdkReceivedNewToken:(VKAccessToken *)newToken
{
    [self p_loggedIn:YES];
}

#pragma mark - Overriding

- (BOOL)isPluginAuthorized
{
    return [VKSdk isLoggedIn];
}

- (BOOL)isPluginEnabled
{
    return [[SMSettings sharedSettings] isVKPluginEnabled];
}

- (void)stateSwitchChanged:(UISwitch*)sender
{
    if (sender.isOn) {
        self.needsUpdateFeeds = YES;
    }
    [[SMSettings sharedSettings] setVKPluginEnabled:sender.isOn];
}

- (void)loginButtonPressed
{
    if ([VKSdk isLoggedIn]) {
        [self p_loggedIn:NO];
    }
    else {
        [VKSdk authorize:@[VK_PER_WALL, VK_PER_FRIENDS, VK_PER_OFFLINE] revokeAccess:YES forceOAuth:NO inApp:NO];
    }
}

@end