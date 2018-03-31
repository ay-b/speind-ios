//
//  SMPlugin.m
//  Speind
//
//  Created by Sergey Butenko on 3/22/15.
//  Copyright (c) 2015 Speaking Mind. All rights reserved.
//

#import "SMPlugin.h"
#import "SMSettings.h"

@interface SMPlugin ()

@property (nonatomic, readwrite) SMPluginType type;
@property (nonatomic, readwrite) NSString* productID;
@property (nonatomic, readwrite) NSString* name;
@property (nonatomic, readwrite, getter=isPurchased) BOOL purchased;
@property (nonatomic, readwrite, getter=isOn) BOOL on;
@property (nonatomic, readwrite) UIImage *icon;

@end

@implementation SMPlugin

+ (NSArray*)availablePlugins
{
    return @[[SMPlugin rssPlugin], [SMPlugin twitterPlugin], [SMPlugin vkPlugin]];
}

+ (instancetype)rssPlugin
{
    SMPlugin *plugin = [SMPlugin new];
    plugin.type = SMPluginTypeRSS;
    plugin.name = LOC(@"RSS");
    plugin.productID = [SMPluginsProductIDPrefix stringByAppendingString:@"rss"];
    plugin.icon = [UIImage imageNamed:@"icon_plugin_rss"];
    
    return plugin;
}

+ (instancetype)twitterPlugin
{
    SMPlugin *plugin = [SMPlugin new];
    plugin.type = SMPluginTypeTwitter;
    plugin.name = LOC(@"Twitter");
    plugin.productID = [SMPluginsProductIDPrefix stringByAppendingString:@"twitter"];
    plugin.icon = [UIImage imageNamed:@"icon_plugin_twitter"];
    
    return plugin;
}

+ (instancetype)vkPlugin
{
    SMPlugin *plugin = [SMPlugin new];
    plugin.type = SMPluginTypeVK;
    plugin.name = LOC(@"Vkontakte");
    plugin.productID = [SMPluginsProductIDPrefix stringByAppendingString:@"vk"];
    plugin.icon = [UIImage imageNamed:@"icon_plugin_vk"];
    
    return plugin;
}

- (BOOL)isPurchased
{
    return [[SMSettings sharedSettings] isProductPurchased:self.productID];
}

- (BOOL)isOn
{
    return [[SMSettings sharedSettings] isPluginEnabled:self.type];
}

- (BOOL)isLoggedIn
{
    switch (self.type) {
        case SMPluginTypeRSS:
            return YES;
        case SMPluginTypeTwitter:
            return [[SMSettings sharedSettings] isTwitterAuthorized];
        case SMPluginTypeVK:
            return [[SMSettings sharedSettings] isVKAuthorized];
    }
}

- (NSString *)segueIdentifier
{
    switch (self.type) {
        case SMPluginTypeRSS:
            return @"toPluginRSS";
        case SMPluginTypeTwitter:
            return @"toPluginTwitter";
        case SMPluginTypeVK:
            return @"toPluginVK";
    }
}

@end
