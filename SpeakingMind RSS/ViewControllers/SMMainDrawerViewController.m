//
//  SMMainDrawerViewController.m
//  Speind
//
//  Created by Sergey Butenko on 3/19/15.
//  Copyright (c) 2015 Speaking Mind. All rights reserved.
//

#import "SMMainDrawerViewController.h"
#import "SMNavigationController.h"

#import <MMDrawerController/MMDrawerVisualState.h>

static const CGFloat kLeftDrawerSize = 283.0;

@interface SMMainDrawerViewController ()

@end

@implementation SMMainDrawerViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupView];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [super viewWillDisappear:animated];
}

- (void)setupView
{
    UIViewController *center = [self.storyboard instantiateViewControllerWithIdentifier:@"MainVC"];
    SMNavigationController *centerContainer = [[SMNavigationController alloc] initWithRootViewController:center];
    UIViewController *leftDrawer = [self.storyboard instantiateViewControllerWithIdentifier:@"SidebarVC"];
    
    [self setCenterViewController:centerContainer];
    [self setLeftDrawerViewController:leftDrawer];
    
    [self setOpenDrawerGestureModeMask:MMOpenDrawerGestureModeBezelPanningCenterView];
    [self setCloseDrawerGestureModeMask:MMCloseDrawerGestureModeAll];
    [self setDrawerVisualStateBlock:[MMDrawerVisualState slideVisualStateBlock]];
    [self setMaximumLeftDrawerWidth:kLeftDrawerSize];
    [self setShowsShadow:NO];
}

@end
