//
//  SMPluginTwitterViewController.m
//  SpeakingMind RSS
//
//  Created by Sergey Butenko on 10/6/14.
//  Copyright (c) 2014 Speaking Mind. All rights reserved.
//

#import "SMPluginTwitterViewController.h"
#import <STTwitter/STTwitter.h>

static NSString* const kVerifierKey = @"oauth_verifier";

@interface SMPluginTwitterViewController ()

@property (nonatomic) STTwitterAPI *twitter;

@end

@implementation SMPluginTwitterViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.title = LOC(@"Twitter");
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(authViaWebDone:) name:SMTwitterAuthNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SMTwitterAuthNotification object:nil];
    [super viewWillDisappear:animated];
}

- (void)p_loggedIn:(BOOL)logged
{
    if (logged) {
        self.needsUpdateFeeds = YES;
    }
    else {
        [[SMSettings sharedSettings] setTwitterPluginLogout];
    }
    [[SMSettings sharedSettings] setTwitterPluginEnabled:logged];
    [self updateView];
}

- (void)p_login
{
    self.twitter = [STTwitterAPI twitterAPIOSWithFirstAccount];
    [self.twitter verifyCredentialsWithSuccessBlock:^(NSString *username) {
        [[SMSettings sharedSettings] setTwitterAccessToken:@"" accessTokenSecret:@""];
        [self p_loggedIn:YES];
    } errorBlock:^(NSError *error) {
        DLog(@"Twitter account error: %@", [error localizedDescription]);
        [self p_loginViaWeb];
    }];
}

- (void)p_loginViaWeb
{
    if ([[SMSettings sharedSettings] isTwitterAuthorized]) { // restore session
        self.twitter = [STTwitterAPI twitterAPIWithOAuthConsumerKey:SMTwitterConsumerKey consumerSecret:SMTwitterConsumerSecret oauthToken:[[SMSettings sharedSettings] twitterAccessToken] oauthTokenSecret:[[SMSettings sharedSettings] twitterAccessTokenSecret]];
            [self.twitter verifyCredentialsWithSuccessBlock:^(NSString *username) {} errorBlock:^(NSError *error) {
                DLog(@"Twitter account error: %@", [error localizedDescription]);
            }];
    }
    else {
        self.twitter = [STTwitterAPI twitterAPIWithOAuthConsumerKey:SMTwitterConsumerKey consumerSecret:SMTwitterConsumerSecret];
        [self.twitter postTokenRequest:^(NSURL *url, NSString *oauthToken) {
            [[UIApplication sharedApplication] openURL:url];
        } authenticateInsteadOfAuthorize:NO
                            forceLogin:@(YES)
                            screenName:nil
                         oauthCallback:[SMTwitterURLPrefix stringByAppendingString:@"://twitter_access_tokens/"]
                            errorBlock:^(NSError *error) {
                                DLog(@"Twitter web auth error: %@", error);
                            }];
    }
}

#pragma mark - Auth via web

- (void)authViaWebDone:(NSNotification*)notif
{
    NSString *verifier = notif.userInfo[kVerifierKey];
    [self.twitter postAccessTokenRequestWithPIN:verifier successBlock:^(NSString *oauthToken, NSString *oauthTokenSecret, NSString *userID, NSString *screenName) {
        [[SMSettings sharedSettings] setTwitterAccessToken:_twitter.oauthAccessToken accessTokenSecret:_twitter.oauthAccessTokenSecret];
        [self p_loggedIn:YES];
    } errorBlock:^(NSError *error) {
        DLog(@"Twitter login error: %@", [error localizedDescription]);
    }];
}

#pragma mark - Overriding

- (BOOL)isPluginAuthorized
{
    return [[SMSettings sharedSettings] isTwitterAuthorized];
}

- (BOOL)isPluginEnabled
{
    return [[SMSettings sharedSettings] isTwitterPluginEnabled];
}

- (void)stateSwitchChanged:(UISwitch*)sender
{
    if (sender.isOn) {
        self.needsUpdateFeeds = YES;
    }
    [[SMSettings sharedSettings] setTwitterPluginEnabled:sender.isOn];
}

- (void)loginButtonPressed
{
    if ([[SMSettings sharedSettings] isTwitterAuthorized]) {
        [self p_loggedIn:NO];
    }
    else {
        [self p_login];
    }
}

@end