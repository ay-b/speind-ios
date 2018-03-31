//
//  SMSideBarPluginTableViewCell.m
//  Speind
//
//  Created by Sergey Butenko on 3/22/15.
//  Copyright (c) 2015 Speaking Mind. All rights reserved.
//

#import "SMSideBarPluginTableViewCell.h"
#import "SMPlugin.h"

@implementation SMSideBarPluginTableViewCell

- (void)setupWithPlugin:(SMPlugin*)plugin
{
    [super setupWithPlugin:plugin];
    
    self.style = SMTableViewCellStyleNone;
    self.selectionStyle = UITableViewCellSelectionStyleGray;
    self.stateSwitch.on = plugin.isOn;
}

@end
