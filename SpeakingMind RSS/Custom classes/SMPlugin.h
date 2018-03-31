//
//  SMPlugin.h
//  Speind
//
//  Created by Sergey Butenko on 3/22/15.
//  Copyright (c) 2015 Speaking Mind. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, SMPluginType) {
    SMPluginTypeRSS,
    SMPluginTypeTwitter,
    SMPluginTypeVK
};

@interface SMPlugin : NSObject

+ (NSArray*)availablePlugins;

+ (instancetype)rssPlugin;
+ (instancetype)vkPlugin;
+ (instancetype)twitterPlugin;

@property (nonatomic, readonly) SMPluginType type;
@property (nonatomic, readonly) NSString* productID;
@property (nonatomic, readonly) NSString* name;
@property (nonatomic, readonly, getter=isPurchased) BOOL purchased;
@property (nonatomic, readonly, getter=isOn) BOOL on;
@property (nonatomic, readonly, getter=isLoggedIn) BOOL loggedIn;
@property (nonatomic, readonly) UIImage *icon;
@property (nonatomic, readonly) NSString *segueIdentifier;

@end
