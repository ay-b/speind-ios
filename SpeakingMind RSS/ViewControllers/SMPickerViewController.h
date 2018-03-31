//
//  SMPickerViewController.h
//  Speind
//
//  Created by Sergey Butenko on 2/25/15.
//  Copyright (c) 2015 Speaking Mind. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SMPickerViewControllerDelegate <NSObject>

- (void)pickItemAtIndex:(NSInteger)index forOption:(NSInteger)option;

@end

@interface SMPickerViewController : UIViewController

@property (nonatomic, weak) id<SMPickerViewControllerDelegate> delegate;

@property (nonatomic) NSString *titleString;

/*
 * Detail = YES means that a data source object description represented like "<value> <details>", otherwise "<details>".
 */
@property (nonatomic, getter=isDetail) BOOL detail;
@property (nonatomic) NSArray *dataSource;

@property (nonatomic) NSInteger selectedIndex;
@property (nonatomic) NSInteger option;

@end
