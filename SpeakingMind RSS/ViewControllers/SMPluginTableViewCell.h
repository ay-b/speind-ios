//
//  SMPluginTableViewCell.h
//  Speind
//
//  Created by Sergey Butenko on 2/25/15.
//  Copyright (c) 2015 Speaking Mind. All rights reserved.
//

#import "SMTableViewCell.h"

@class SMPlugin;

@interface SMPluginTableViewCell : SMTableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *pluginIconImageView;

- (void)setupWithPlugin:(SMPlugin*)plugin;

@end
