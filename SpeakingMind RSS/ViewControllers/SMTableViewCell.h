//
//  SMSimpleTableViewCell.h
//  Speind
//
//  Created by Sergey Butenko on 2/25/15.
//  Copyright (c) 2015 Speaking Mind. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, SMTableViewCellStyle) {
    SMTableViewCellStyleSegue = 0,
    SMTableViewCellStyleNone,
    SMTableViewCellStyleBuy,
    SMTableViewCellStyleRestore,
    SMTableViewCellStyleCancel,
    SMTableViewCellStyleSignIn,
    SMTableViewCellStyleSignOut,
    SMTableViewCellStyleVideo,
    SMTableViewCellStyleCheck
};

/**
 * Basic TableViewCell class with helpers.
 */
@interface SMTableViewCell : UITableViewCell

/**
 * Use this selectod for registerNib:forCellReuseIdentifier:.
 *
 * @return UINib for xib with name equals to class name.
 */
+ (UINib*)nib;

/**
 * Left title.
 */
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

/**
 * Style for current cell.
 */
@property (nonatomic) SMTableViewCellStyle style;

@end