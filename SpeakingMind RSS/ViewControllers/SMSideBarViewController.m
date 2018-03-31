//
//  SMSideBarViewController.m
//  ;
//
//  Created by Sergey Butenko on 3/5/15.
//  Copyright (c) 2015 Speaking Mind. All rights reserved.
//

#import "SMSideBarViewController.h"
#import "SMSideBarTableViewCell.h"
#import "SMSideBarPluginTableViewCell.h"
#import "SMPluginViewController.h"
#import "SMPlugin.h"

#import <UIViewController+MMDrawerController.h>

static NSString*const kSimpleCellIdentifier = @"SideBarCell";
static NSString*const kPluginCellIdentifier = @"PluginCell";

static NSString*const kSettingsSegue = @"toSettings";
static NSString*const kAboutSegue    = @"toAbout";

static const int kSettingsRow = 0;
static const int kFeedbackRow = 1;
static const int kRateUsRow   = 2;

static const int kConfirmButton = 0;
static const int kCancelButton  = 1;

@interface SMSideBarViewController () <UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate>

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic) NSArray *plugins;
@property (nonatomic) SMPlugin *processingPlugin;

@end

@implementation SMSideBarViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.plugins = [SMPlugin availablePlugins];
    
    [self.tableView registerNib:[SMSideBarTableViewCell nib] forCellReuseIdentifier:kSimpleCellIdentifier];
    [self.tableView registerNib:[SMSideBarPluginTableViewCell nib] forCellReuseIdentifier:kPluginCellIdentifier];
    self.tableView.tableFooterView = [UIView new];
}

- (void)stateSwitchChanged:(UISwitch*)sender
{
    self.processingPlugin = self.plugins[sender.tag];
    
    if (!self.processingPlugin.isLoggedIn && sender.isOn && self.processingPlugin.isPurchased) {
        NSString *title = [NSString stringWithFormat:LOC(@"Auth in plugin %@"), self.processingPlugin.name];
        [[[UIAlertView alloc] initWithTitle:title message:nil delegate:self cancelButtonTitle:LOC(@"Yes") otherButtonTitles:LOC(@"No"), nil] show];
    }
    else {
        [[SMSettings sharedSettings] setPlugin:self.processingPlugin.type enabled:sender.isOn];
        self.processingPlugin = nil;
    }
}

#pragma mark - UITableViewDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.plugins.count + @[@(kSettingsRow), @(kFeedbackRow), @(kRateUsRow)].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row < self.plugins.count) {
        SMSideBarPluginTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kPluginCellIdentifier forIndexPath:indexPath];
        SMPlugin *plugin = self.plugins[indexPath.row];
        cell.stateSwitch.tag = indexPath.row;
        [cell setupWithPlugin:plugin];
        [cell.stateSwitch addTarget:self action:@selector(stateSwitchChanged:) forControlEvents:UIControlEventValueChanged];
        cell.userInteractionEnabled = plugin.isPurchased;
    
        return cell;
    }

    NSString *title;
    UIImage *icon;
    NSInteger row = indexPath.row - self.plugins.count;
    if (row == kSettingsRow) {
        title = LOC(@"Title - Settings");
        icon = [UIImage imageNamed:@"icon_settings"];
    }
    else if (row == kFeedbackRow) {
        title = LOC(@"Title - Feedback");
        icon = [UIImage imageNamed:@"icon_feedback"];
    }
    else if (row == kRateUsRow) {
        title = LOC(@"Title - Rate us");
        icon = [UIImage imageNamed:@"icon_about"];
    }
    
    SMSideBarTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kSimpleCellIdentifier forIndexPath:indexPath];
    cell.titleLabel.text = title;
    cell.iconImageView.image = icon;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self.mm_drawerController closeDrawerAnimated:YES completion:nil];
    
    if (indexPath.row < self.plugins.count) {
        SMPlugin *plugin = self.plugins[indexPath.row];
        if (plugin.isPurchased) {
            [self performSegueWithIdentifier:plugin.segueIdentifier sender:nil];
        }
        return;
    }
    
    NSInteger row = indexPath.row - self.plugins.count;
    if (row == kSettingsRow) {
        [self performSegueWithIdentifier:kSettingsSegue sender:nil];
    }
    else if (row == kFeedbackRow) {
        [self performSegueWithIdentifier:kAboutSegue sender:nil];
    }
    else if (row == kRateUsRow) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:SMITunesAppURL]];
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

#pragma mark - UIAlertView Delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == kConfirmButton) {
        [self performSegueWithIdentifier:self.processingPlugin.segueIdentifier sender:nil];
    }
    else if (buttonIndex == kCancelButton) {
        [self.tableView reloadData];
    }
    self.processingPlugin = nil;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if (self.processingPlugin.type == SMPluginTypeTwitter || self.processingPlugin.type == SMPluginTypeVK) {
        SMPluginViewController *vc = (SMPluginViewController*)segue.destinationViewController;
        vc.loginImmediately = YES;
    }
}

@end
