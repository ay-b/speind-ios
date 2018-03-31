//
//  SMNavigationController.m
//  Speind
//
//  Created by Sergey Butenko on 3/9/15.
//  Copyright (c) 2015 Speaking Mind. All rights reserved.
//

#import "SMNavigationController.h"

@interface SMNavigationController ()

@end

@implementation SMNavigationController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // style for navigation bar
    [self.navigationBar setTitleTextAttributes: [NSDictionary dictionaryWithObjectsAndKeys: [UIFont fontWithName:@"HelveticaNeue-Light" size:18], NSFontAttributeName, nil]];
    [self.navigationBar setTintColor:[UIColor lightGrayColor]];
    [self.navigationBar setBarTintColor:[UIColor whiteColor]];
    [self.navigationBar setBackgroundImage:[UIImage new] forBarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];
    [self.navigationBar setShadowImage:[UIImage new]];
    
    UIImage *img = [[UIImage imageNamed:@"button_back"] stretchableImageWithLeftCapWidth:0 topCapHeight:0];
    [[UIBarButtonItem appearance] setBackButtonBackgroundImage:img forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
}

@end
