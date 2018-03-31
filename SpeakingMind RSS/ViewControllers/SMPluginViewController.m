//
//  SMPluginViewController.m
//  Speind
//
//  Created by Sergey Butenko on 3/18/15.
//  Copyright (c) 2015 Speaking Mind. All rights reserved.
//

#import "SMPluginViewController.h"
#import "SMTableViewCell.h"
#import "SMSwitchTableViewCell.h"

static NSString* const kSimpleCellIdentifier = @"SimpleCell";
static NSString* const kSwitchCellIdentifier = @"SwitchCell";

static const int kEnabledRow = 0;
static const int kSignInRow = 1;

@interface SMPluginViewController () <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation SMPluginViewController

- (NSString *)nibName
{
    return @"SMPluginViewController";
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.tableView registerNib:[SMTableViewCell nib] forCellReuseIdentifier:kSimpleCellIdentifier];
    [self.tableView registerNib:[SMSwitchTableViewCell nib] forCellReuseIdentifier:kSwitchCellIdentifier];
    
    if (self.loginImmediately) {
        [self loginButtonPressed];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if (self.needsUpdateFeeds) {
        [[NSNotificationCenter defaultCenter] postNotificationName:SMUpdatingIntervalNotification object:self];
    }
}

- (void)updateView
{
    [self.tableView reloadData];
}

#pragma mark - Abstract

- (BOOL)isPluginAuthorized
{
    [NSException raise:NSInternalInconsistencyException format:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)];
    return NO;
}

- (BOOL)isPluginEnabled
{
    [NSException raise:NSInternalInconsistencyException format:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)];
    return NO;
}

- (void)stateSwitchChanged:(UISwitch*)sender
{
    [NSException raise:NSInternalInconsistencyException format:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)];
}

- (void)loginButtonPressed
{
    [NSException raise:NSInternalInconsistencyException format:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)];
}

#pragma mark - UITableViewDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return @[@(kEnabledRow), @(kSignInRow)].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SMTableViewCell *someCell;
    
    if (indexPath.row == kEnabledRow) {
        SMSwitchTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kSwitchCellIdentifier forIndexPath:indexPath];
        [cell.stateSwitch addTarget:self action:@selector(stateSwitchChanged:) forControlEvents:UIControlEventValueChanged];
        cell.stateSwitch.on = [self isPluginEnabled];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.titleLabel.text = LOC(@"Enabled");
        return cell;
    }
    else if (indexPath.row == kSignInRow) {
        someCell = [tableView dequeueReusableCellWithIdentifier:kSimpleCellIdentifier forIndexPath:indexPath];
        someCell.style = [self isPluginAuthorized] ? SMTableViewCellStyleSignOut : SMTableViewCellStyleSignIn;
        someCell.titleLabel.text = [self isPluginAuthorized] ? LOC(@"Sign out") : LOC(@"Sign in");
    }
    
    return someCell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.row == kSignInRow) {
        [self loginButtonPressed];
    }
}

- (UIView*)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    return [[UIView alloc] initWithFrame:CGRectZero];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.01f;
}

@end
