//
//  SMPluginViewController.h
//  Speind
//
//  Created by Sergey Butenko on 3/18/15.
//  Copyright (c) 2015 Speaking Mind. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SMPluginViewController : UIViewController

- (BOOL)isPluginAuthorized;
- (BOOL)isPluginEnabled;
- (void)stateSwitchChanged:(UISwitch*)sender;
- (void)loginButtonPressed;
- (void)updateView;

@property (nonatomic) BOOL needsUpdateFeeds;
@property (nonatomic) BOOL loginImmediately;

@end
