//
//  SMPluginTableViewCell.m
//  Speind
//
//  Created by Sergey Butenko on 2/25/15.
//  Copyright (c) 2015 Speaking Mind. All rights reserved.
//

#import "SMPluginTableViewCell.h"

@implementation SMPluginTableViewCell

- (void)setupWithPlugin:(SMPlugin*)plugin
{
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.style = plugin.isPurchased ? SMTableViewCellStyleSegue : SMTableViewCellStyleBuy;
    
    self.titleLabel.text = plugin.name;
    self.pluginIconImageView.image = plugin.icon;
}

@end
