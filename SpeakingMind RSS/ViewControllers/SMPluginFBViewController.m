//
//  SMPluginFBViewController.m
//  SpeakingMind RSS
//
//  Created by Sergey Butenko on 10/6/14.
//  Copyright (c) 2014 Speaking Mind. All rights reserved.
//

#import "SMPluginFBViewController.h"
#import "SMDefines.h"   
#import "SMSettings.h"
#import "SMFBBuilder.h"

#import <Facebook-iOS-SDK/FacebookSDK/FacebookSDK.h>

@interface SMPluginFBViewController ()

@property BOOL needUpdateFeeds;

- (IBAction)loginButtonPressed:(UIButton *)sender;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;

- (IBAction)enabledSwitchChanged:(UISwitch*)sender;
@property (weak, nonatomic) IBOutlet UISwitch *enabledSwitch;
@property (weak, nonatomic) IBOutlet UIImageView *loginIconImageView;

@end

@implementation SMPluginFBViewController

- (NSString *)nibName
{
    return @"SMPluginTwitterViewController";
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.title = LOC(@"Facebook");
    [self p_updateView];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if (self.needUpdateFeeds) {
        [[NSNotificationCenter defaultCenter] postNotificationName:SMUpdatingIntervalNotification object:self];
    }
}

- (IBAction)loginButtonPressed:(UIButton *)sender
{
    if (FBSession.activeSession.isOpen) {
        [self p_loggedIn:NO];
    }
    else {
        [self authorize];
    }
}

- (IBAction)enabledSwitchChanged:(UISwitch*)sender
{
    [[SMSettings sharedSettings] setFBPluginEnabled:sender.isOn];
}

- (void)p_updateView
{
    self.enabledSwitch.on = [[SMSettings sharedSettings] isFBPluginEnabled];
    if (FBSession.activeSession.isOpen) {
        [self.loginButton setTitle:LOC(@"Sign out") forState:UIControlStateNormal];
    }
    else {
        [self.loginButton setTitle:LOC(@"Sign in") forState:UIControlStateNormal];
    }
    self.loginIconImageView.highlighted = FBSession.activeSession.isOpen;
}


- (void)p_loggedIn:(BOOL)logged
{
    self.enabledSwitch.on = logged;
    [self enabledSwitchChanged:self.enabledSwitch];
    if (logged) {
        self.needUpdateFeeds = YES;
    }
    else {
        [FBSession.activeSession closeAndClearTokenInformation];
    }
    [self p_updateView];
}

- (void)authorize
{
    if (!FBSession.activeSession.isOpen) {
        [FBSession openActiveSessionWithReadPermissions:@[@"public_profile", @"user_posts"] allowLoginUI:YES
        completionHandler:^(FBSession *session, FBSessionState state, NSError *error) {
            if (error) {
                DLog(@"FB login error: %@", error.localizedDescription);
            }
            else if (session.isOpen) {
                [self authorize];
            }
        }];
        return;
    }
    [self p_loggedIn:YES];
}

@end
