//
//  SMSettingsViewController.m
//  SpeakingMind RSS
//
//  Created by Sergey Butenko on 02.06.14.
//  Copyright (c) 2014 serejahh inc. All rights reserved.
//

#import "SMSettingsViewController.h"
#import "SMTableViewCell.h"
#import "SMSwitchTableViewCell.h"
#import "SMSubtitleTableViewCell.h"
#import "SMPluginTableViewCell.h"
#import "SMPickerViewController.h"
#import "SMSectionView.h"
#import "SMPlugin.h"
#import "SMVoicesDownloader.h"

#import <RMStore/RMStore.h>
#import <MBProgressHUD/MBProgressHUD.h>

static NSString* const kSimpleCellIdentifier   = @"SimpleCell";
static NSString* const kSwitchCellIdentifier   = @"SwitchCell";
static NSString* const kSubtitleCellIdentifier = @"SubtitleCell";
static NSString* const kPluginCellIdentifier   = @"PluginCell";

static NSString* const kToPickerSegue = @"toPicker";
static NSString* const kToVoicesSegue = @"toVoices";

static const int kSectionHeight  = 30;
static const int kMainSection    = 0;
static const int kPluginsSection = 1;

static const int kReadNewsRow         = 0;
static const int kPollingIntervalRow  = 1;
static const int kStoreHistoryRow     = 2;
static const int kReadFullArticleRow  = 3;
static const int kDownloadOverWiFiRow = 4;
static const int kTurnOnScreeRow      = 5;
static const int kVoicesRow           = 6;
static const int kRestorePurchasesRow = 0;

@interface SMSettingsViewController () <UITableViewDelegate, UITableViewDataSource, SMPickerViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic) NSArray *readNews;
@property (nonatomic) NSArray *saveHistory;
@property (nonatomic) NSArray *pollingIntervals;
@property (nonatomic) NSArray *plugins;

@end

@implementation SMSettingsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.title = NSLocalizedString(@"Title - Settings", nil);
    [self p_prepareTableView];
}

- (void)p_prepareTableView
{
    [self.tableView registerNib:[SMTableViewCell nib] forCellReuseIdentifier:kSimpleCellIdentifier];
    [self.tableView registerNib:[SMSwitchTableViewCell nib] forCellReuseIdentifier:kSwitchCellIdentifier];
    [self.tableView registerNib:[SMSubtitleTableViewCell nib] forCellReuseIdentifier:kSubtitleCellIdentifier];
    [self.tableView registerNib:[SMPluginTableViewCell nib] forCellReuseIdentifier:kPluginCellIdentifier];
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = SMTableViewCellHeight;
}

- (void)p_restorePurchases
{
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [[RMStore defaultStore] restoreTransactionsOnSuccess:^(NSArray *transactions) {
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        
        for (SKPaymentTransaction *t in transactions) {
            [[SMSettings sharedSettings] addPuchaseWithProductID:t.payment.productIdentifier];
        }
        [[SMVoicesDownloader downloader] refreshVoices];
        [self.tableView reloadData];
        
        [[[UIAlertView alloc] initWithTitle:LOC(@"Thank you") message:LOC(@"Purchases restored") delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
    } failure:^(NSError *error) {
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        [[[UIAlertView alloc] initWithTitle:LOC(@"Error") message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
    }];
}

- (void)p_buyPluginWithProductID:(NSString*)productID
{
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    [[RMStore defaultStore] addPayment:productID success:^(SKPaymentTransaction *transaction) {
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        [[SMSettings sharedSettings] addPuchaseWithProductID:transaction.payment.productIdentifier];
        [self.tableView reloadData];
    } failure:^(SKPaymentTransaction *transaction, NSError *error) {
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    }];
}

- (void)stateSwitchChanged:(UISwitch*)sender
{
    if (sender.tag == kReadFullArticleRow) {
        [[SMSettings sharedSettings] setReadFullArticle:sender.isOn];
    }
    else if (sender.tag == kDownloadOverWiFiRow) {
        [[SMSettings sharedSettings] setLoadImagesOnlyViaWiFi:sender.isOn];
    }
    else if (sender.tag == kTurnOnScreeRow) {
        [[SMSettings sharedSettings] setAlwaysTurnOnScreen:sender.isOn];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:kToPickerSegue]) {
        UITableViewCell *cell = sender;
        NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
        
        NSString *title;
        NSArray *dataSource;
        NSInteger selectedIndex = -1;
        BOOL isDetail;
        if (indexPath.row == kReadNewsRow) {
            title = LOC(@"Max play time");
            dataSource = self.readNews;
            selectedIndex = [[SMSettings sharedSettings] selectedReadArticleIndex];
            isDetail = NO;
        }
        else if (indexPath.row == kPollingIntervalRow) {
            title = LOC(@"Refresh rate");
            dataSource = self.pollingIntervals;
            selectedIndex = [[SMSettings sharedSettings] selectedUpdatingIntervalIndex];
            isDetail = YES;
        }
        else if (indexPath.row == kStoreHistoryRow) {
            title = LOC(@"Store time");
            dataSource = self.saveHistory;
            selectedIndex = [[SMSettings sharedSettings] selectedSaveHistoryIndex];
            isDetail = YES;
        }
        
        SMPickerViewController *vc = segue.destinationViewController;
        vc.titleString = title;
        vc.dataSource = dataSource;
        vc.selectedIndex = selectedIndex;
        vc.detail = isDetail;
        vc.delegate = self;
        vc.option = indexPath.row;
    }
}

#pragma mark - Lazy init

- (NSArray *)plugins
{
    if (!_plugins) {
        _plugins = [SMPlugin availablePlugins];
    }
    return _plugins;
}

- (NSArray *)readNews
{
    if (!_readNews) {
        _readNews = [[SMSettings sharedSettings] readArticleDisplaying];
    }
    return _readNews;
}

- (NSArray *)saveHistory
{
    if (!_saveHistory) {
        _saveHistory = [[SMSettings sharedSettings] saveHistoryDisplaying];
    }
    return _saveHistory;
}

- (NSArray *)pollingIntervals
{
    if (!_pollingIntervals) {
        _pollingIntervals = [[SMSettings sharedSettings] updatingIntervalDisplaying];
    }
    return _pollingIntervals;
}

#pragma mark - UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return @[@(kMainSection), @(kPluginsSection)].count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == kMainSection) {
        return @[@(kReadNewsRow), @(kPollingIntervalRow), @(kStoreHistoryRow), @(kReadFullArticleRow), @(kDownloadOverWiFiRow), @(kTurnOnScreeRow), @(kVoicesRow)].count;
    }
    else {
        return @[@(kRestorePurchasesRow)].count + self.plugins.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == kMainSection) {
        if (indexPath.row < kReadFullArticleRow) {
            SMSubtitleTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kSubtitleCellIdentifier forIndexPath:indexPath];
            
            NSString *title;
            NSString *subtitle;
            if (indexPath.row == kReadNewsRow) {
                title = LOC(@"Max play time");
                subtitle = self.readNews[[[SMSettings sharedSettings] selectedReadArticleIndex]];
            }
            else if (indexPath.row == kPollingIntervalRow) {
                title = LOC(@"Refresh rate");
                subtitle = self.pollingIntervals[[[SMSettings sharedSettings] selectedUpdatingIntervalIndex]];
            }
            else if (indexPath.row == kStoreHistoryRow) {
                title = LOC(@"Store time");
                subtitle = self.saveHistory[[[SMSettings sharedSettings] selectedSaveHistoryIndex]];
            }
            cell.titleLabel.text = title;
            
            if (indexPath.row == kReadNewsRow) {
                cell.subtitleLabel.text = subtitle;
                cell.valueSubtitleLabel.text = @"";
            }
            else {
                NSArray *subtitleComponents = [subtitle componentsSeparatedByString:@" "];
                cell.valueSubtitleLabel.text = subtitleComponents[0];
                cell.subtitleLabel.text = subtitleComponents[1];
            }
            
            return cell;
        }
        else if (indexPath.row < kVoicesRow) {
            SMSwitchTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kSwitchCellIdentifier forIndexPath:indexPath];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            [cell.stateSwitch addTarget:self action:@selector(stateSwitchChanged:) forControlEvents:UIControlEventValueChanged];
            cell.stateSwitch.tag = indexPath.row;
       
            NSString *title;
            if (indexPath.row == kReadFullArticleRow) {
                title = LOC(@"Read full article");
                cell.stateSwitch.on = [[SMSettings sharedSettings] isReadFullArticle];
            }
            else if (indexPath.row == kDownloadOverWiFiRow) {
                title = LOC(@"Download images on mobile net");
                cell.stateSwitch.on = [[SMSettings sharedSettings] isLoadImagesOnlyViaWiFi];
            }
            else if (indexPath.row == kTurnOnScreeRow) {
                title = LOC(@"Screen turned on");
                cell.stateSwitch.on = [[SMSettings sharedSettings] isAlwaysTurnOnScreen];
            }
            cell.titleLabel.text = title;
        
            return cell;
        }
        else if (indexPath.row == kVoicesRow) {
            SMTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kSimpleCellIdentifier forIndexPath:indexPath];
            cell.titleLabel.text = LOC(@"Voices");
            cell.style = SMTableViewCellStyleSegue;
            return cell;
        }
    }
    else if (indexPath.section == kPluginsSection) {
        if (indexPath.row == kRestorePurchasesRow) {
            SMTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kSimpleCellIdentifier forIndexPath:indexPath];
            cell.titleLabel.text = LOC(@"Restore purchases");
            cell.style = SMTableViewCellStyleRestore;
            return cell;
        }
        else {
            SMPluginTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kPluginCellIdentifier forIndexPath:indexPath];
            SMPlugin *plugin = self.plugins[indexPath.row - 1];
            [cell setupWithPlugin:plugin];
            return cell;
        }
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    if (indexPath.section == kMainSection) {
        if (indexPath.row < kReadFullArticleRow) {
            [self performSegueWithIdentifier:kToPickerSegue sender:cell];
        }
        else if (indexPath.row == kVoicesRow) {
            [self performSegueWithIdentifier:kToVoicesSegue sender:cell];
        }
    }
    else if (indexPath.section == kPluginsSection) {
        if (indexPath.row == kRestorePurchasesRow) {
            [self p_restorePurchases];
        }
        else {
            SMPlugin *plugin = self.plugins[indexPath.row - 1];
            #if TARGET_IPHONE_SIMULATOR
            [self performSegueWithIdentifier:plugin.segueIdentifier sender:self];
            #else
            if (plugin.isPurchased) {
                [self performSegueWithIdentifier:plugin.segueIdentifier sender:self];
            }
            else {
                [self p_buyPluginWithProductID:plugin.productID];
            }
            #endif
        }
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

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return section ? kSectionHeight : 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    SMSectionView *sectionView = [[SMSectionView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, kSectionHeight)];
    sectionView.titleLabel.text = LOC(@"Plugins");
    return sectionView;
}

#pragma mark - SMPickerViewControllerDelegate

- (void)pickItemAtIndex:(NSInteger)index forOption:(NSInteger)option
{
    if (option == kReadNewsRow) {
        [[SMSettings sharedSettings] setSelectedReadArticleValue:index];
        [[NSNotificationCenter defaultCenter] postNotificationName:SMReadNewsNotification object:self];
    }
    else if (option == kPollingIntervalRow) {
        [[SMSettings sharedSettings] setSelectedUpdatingIntervalIndex:index];
        [[NSNotificationCenter defaultCenter] postNotificationName:SMUpdatingIntervalNotification object:self];
    }
    else if (option == kStoreHistoryRow) {
        [[SMSettings sharedSettings] setSelectedSaveHistoryIndex:index];
    }
    
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:option inSection:kMainSection]] withRowAnimation:UITableViewRowAnimationFade];
}

@end
