//
//  SMSimpleTableViewCell.m
//  Speind
//
//  Created by Sergey Butenko on 2/25/15.
//  Copyright (c) 2015 Speaking Mind. All rights reserved.
//

#import "SMTableViewCell.h"

@interface SMTableViewCell ()

@property (weak, nonatomic) IBOutlet UIImageView *accessoryImageView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *widthConstraint;

@end

@implementation SMTableViewCell

+ (UINib*)nib
{
    return [UINib nibWithNibName:NSStringFromClass([self class]) bundle:nil];
}

- (void)setStyle:(SMTableViewCellStyle)style
{
    _style = style;
    
    UIImage *icon;
    switch (_style) {
        case SMTableViewCellStyleSegue:
            icon = [UIImage imageNamed:@"icon_accessory"];
            break;
        case SMTableViewCellStyleNone:
            icon = nil;
            break;
        case SMTableViewCellStyleBuy:
            icon = [UIImage imageNamed:@"icon_buy"];
            break;
        case SMTableViewCellStyleRestore:
            icon = [UIImage imageNamed:@"icon_restore_purchases"];
            break;
        case SMTableViewCellStyleCancel:
            icon = [UIImage imageNamed:@"icon_cancel"];
            break;
        case SMTableViewCellStyleSignIn:
            icon = [UIImage imageNamed:@"icon_authorize"];
            self.titleLabel.text = LOC(@"Sign in");
            break;
        case SMTableViewCellStyleSignOut:
            icon = [UIImage imageNamed:@"icon_cancel"];
            self.titleLabel.text = LOC(@"Sign out");
            break;
        case SMTableViewCellStyleVideo:
            icon = [UIImage imageNamed:@"icon_play"];
            break;
        case SMTableViewCellStyleCheck:
            icon = [UIImage imageNamed:@"icon_check_feed"];
            break;  
    }
    
    self.accessoryImageView.image = icon;
}

@end
