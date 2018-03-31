//
//  SMSettingsVoicesViewController.m
//  SpeakingMind RSS
//
//  Created by Sergey Butenko on 09.07.14.
//  Copyright (c) 2014 serejahh inc. All rights reserved.
//

#import "SMSettingsVoicesViewController.h"
#import "SMSettingsVoicesTableViewCell.h"
#import "SMSwitchTableViewCell.h"
#import "SMTableViewCell.h"
#import "SMSubtitleTableViewCell.h"
#import "SMVoicesDownloader.h"
#import "SMVoiceManager.h"
#import "SMSectionView.h"
#import "SMDemoSpeechSynthesizer.h"
#import "SMPickerViewController.h"
#import "AcapelaSpeech+Speind.h"

#import <MBProgressHUD/MBProgressHUD.h>
#import <AFNetworking/AFNetworkReachabilityManager.h>
#import <RMStore/RMStore.h>

static const int kSettingsSection = 0;
static const int kSpeechRateRow = 0;
static const int kDownloadOverWiFiRow = 1;
static const int kRestorePurchasesRow = 2;

static const int kSectionHeight = 30;

static NSString* const kToPickerSegue = @"toPicker";

static NSString* const kVoiceCellIdentifier = @"VoiceCell";
static NSString* const kSwitchCellIdentifier = @"SwitchCell";
static NSString* const kSimpleCellIdentifier = @"SimpleCell";
static NSString* const kSubtitleCellIdentifier = @"SubtitleCell";

@interface SMSettingsVoicesViewController () <SMSettingsVoicesTableViewCellDelegate, UITableViewDelegate, UITableViewDataSource, RMStoreObserver, SMVoicesDownloaderDelegate, SMDemoSpeechSynthesizerDelegate, SMPickerViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic) NSArray *voices;
@property (nonatomic) NSArray *languages;

@property (nonatomic) SMDemoSpeechSynthesizer* demoSynthesizer;
@property (nonatomic) SMVoice *nowPlayingVoice;
@property (nonatomic) NSIndexPath *nowPlayingIndexPath;;

@end

@implementation SMSettingsVoicesViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.title = LOC(@"Voices");
    
    [SMVoicesDownloader downloader].delegate = self;
    [self.tableView registerNib:[SMSettingsVoicesTableViewCell nib] forCellReuseIdentifier:kVoiceCellIdentifier];
    [self.tableView registerNib:[SMSwitchTableViewCell nib] forCellReuseIdentifier:kSwitchCellIdentifier];
    [self.tableView registerNib:[SMTableViewCell nib] forCellReuseIdentifier:kSimpleCellIdentifier];
    [self.tableView registerNib:[SMSubtitleTableViewCell nib] forCellReuseIdentifier:kSubtitleCellIdentifier];
}

- (NSArray *)languages
{
    if (!_languages) {
        _languages = [[SMVoiceManager sharedManager] availableLanguages];
    }
    return _languages;
}

- (void)viewDidDisappear:(BOOL)animated
{
    [self.demoSynthesizer stopSpeakingDemo];
    [super viewDidDisappear:animated];
}

#warning rewrite
- (void)p_checkVoice:(SMVoice*)voice
{
    NSArray *smVoices = [AcapelaSpeech availableSMVoices];
    for (SMVoice* existsVoice in smVoices) {
        if ([voice.name isEqualToString:existsVoice.name]) {
            voice.state = SMVoiceDownloaded;
        }
    }
    
    if (voice.isNativeVoice) {
        voice.state = SMVoiceDownloaded;
    }
    
    // current for some language
    NSArray *currentVoices = [[SMSettings sharedSettings] currentVoices];
    for (NSString *currentVoice in currentVoices) {
        if ([currentVoice hasPrefix:voice.uid]) {
            voice.state = SMVoiceCurrent;
            break;
        }
    }
}

- (void)disableScreen:(BOOL)disable
{
    self.navigationController.interactivePopGestureRecognizer.enabled = !disable;
    [[UIApplication sharedApplication] setIdleTimerDisabled:disable ? disable : [[SMSettings sharedSettings] isAlwaysTurnOnScreen]];
}

- (void)stateSwitchChanged:(UISwitch*)sender
{
    if (sender.tag == kDownloadOverWiFiRow) {
        [[SMSettings sharedSettings] setDownloadVoiceOnlyViaWiFi:sender.isOn];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:kToPickerSegue]) {
        SMPickerViewController *vc = segue.destinationViewController;
        vc.titleString = LOC(@"Speech rate");
        vc.dataSource = [[SMSettings sharedSettings] speechRateDisplaying];
        vc.selectedIndex = [[SMSettings sharedSettings] selectedSpeechRateIndex];
        vc.delegate = self;
    }
}

#pragma mark - Store Kit

- (void)p_restorePurchases
{
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    [[RMStore defaultStore]restoreTransactionsOnSuccess:^(NSArray *transactions) {
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        
        for (SKPaymentTransaction *t in transactions) {
            [[SMSettings sharedSettings] addPuchaseWithProductID:t.payment.productIdentifier];
        }
        [[SMVoicesDownloader downloader] refreshVoices];
        [self.tableView reloadData];
        
        [[[UIAlertView alloc] initWithTitle:LOC(@"Thank you") message:LOC(@"Purchases restored") delegate:nil cancelButtonTitle:LOC(@"OK") otherButtonTitles: nil] show];
    } failure:^(NSError *error) {
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        [[[UIAlertView alloc] initWithTitle:LOC(@"Error") message:error.localizedDescription delegate:nil cancelButtonTitle:LOC(@"OK") otherButtonTitles: nil] show];
    }];
}

- (void)p_buyVoice:(SMVoice*)voice
{
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    [[RMStore defaultStore] addPayment:voice.productID success:^(SKPaymentTransaction *transaction) {
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        [[SMSettings sharedSettings] addPuchaseWithProductID:transaction.payment.productIdentifier];
        [[SMVoicesDownloader downloader] refreshVoices];
        [self.tableView reloadData];
    } failure:^(SKPaymentTransaction *transaction, NSError *error) {
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    }];
}

#pragma mark - SMDemoSpeechSynthesizer Delegate

- (SMDemoSpeechSynthesizer *)demoSynthesizer
{
    if (!_demoSynthesizer) {
        _demoSynthesizer = [[SMDemoSpeechSynthesizer alloc] initWithDelegate:self];
    }
    return _demoSynthesizer;
}

- (void)demoSpeechSynthesizerdidFinishSpeaking:(SMDemoSpeechSynthesizer *)sender
{
    SMSettingsVoicesTableViewCell *nowPlayingCell = (SMSettingsVoicesTableViewCell*)[self.tableView cellForRowAtIndexPath:self.nowPlayingIndexPath];
    [nowPlayingCell stop];
    [self stopDemoForCell:nowPlayingCell];
}

#pragma mark - SMSettingsVoicesTableViewCell Delegate

- (void)playDemoForCell:(SMSettingsVoicesTableViewCell*)cell
{
    if (![[AFNetworkReachabilityManager sharedManager] isReachable]) {
        [[[UIAlertView alloc] initWithTitle:LOC(@"Error") message:LOC(@"No internet connection") delegate:nil cancelButtonTitle:nil otherButtonTitles:LOC(@"OK"), nil] show];
        [cell stop];
        return;
    }
    
    SMSettingsVoicesTableViewCell *nowPlayingCell = (SMSettingsVoicesTableViewCell*)[self.tableView cellForRowAtIndexPath:self.nowPlayingIndexPath];
    [nowPlayingCell stop];
    
    self.nowPlayingIndexPath = [self.tableView indexPathForCell:cell];
    self.nowPlayingVoice = cell.voice;
    [self.demoSynthesizer startSpeakingDemoForVoice:self.nowPlayingVoice];
}

- (void)stopDemoForCell:(SMSettingsVoicesTableViewCell*)cell
{
    [self.demoSynthesizer stopSpeakingDemo];
    self.nowPlayingIndexPath = nil;
    self.nowPlayingVoice = nil;
}

- (void)buyVoiceForCell:(SMSettingsVoicesTableViewCell*)cell
{
    [self p_buyVoice:cell.voice];
}

- (void)setCurrentVoiceForCell:(SMSettingsVoicesTableViewCell*)cell
{
    [[SMSettings sharedSettings] setSelectedVoice:cell.voice];
    [self.tableView reloadData];
}

#pragma mark - UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.languages.count + 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == kSettingsSection) {
        return @[@(kSpeechRateRow), @(kDownloadOverWiFiRow), @(kRestorePurchasesRow)].count;
    }
    return [[SMVoiceManager sharedManager] voicesForLanguage:self.languages[section - 1]].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == kSettingsSection) {
        if (indexPath.row == kSpeechRateRow) {
            SMSubtitleTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kSubtitleCellIdentifier forIndexPath:indexPath];
            cell.titleLabel.text = LOC(@"Speech rate");
            cell.subtitleLabel.text = [[SMSettings sharedSettings] selectedSpeechRateValue];
            cell.valueSubtitleLabel.text = nil;
            return cell;
        }
        if (indexPath.row == kDownloadOverWiFiRow) {
            SMSwitchTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kSwitchCellIdentifier forIndexPath:indexPath];
            [cell.stateSwitch addTarget:self action:@selector(stateSwitchChanged:) forControlEvents:UIControlEventValueChanged];
            cell.stateSwitch.tag = indexPath.row;
            cell.stateSwitch.on = [[SMSettings sharedSettings] isDownloadVoiceOnlyViaWiFi];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.titleLabel.text = LOC(@"Download via WiFi only");
            return cell;
        }
        if (indexPath.row == kRestorePurchasesRow) {
            SMTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kSimpleCellIdentifier forIndexPath:indexPath];
            cell.titleLabel.text = LOC(@"Restore purchases");
            cell.style = SMTableViewCellStyleRestore;
            return cell;
        }
    }
    
    SMSettingsVoicesTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kVoiceCellIdentifier forIndexPath:indexPath];
    NSArray *voices = [[SMVoiceManager sharedManager] voicesForLanguage:self.languages[indexPath.section-1]];
    SMVoice *voice = voices[indexPath.row];
    [self p_checkVoice:voice];
    
    [cell configureCellWithVoice:voice delegate:self];
    if ([[[SMVoicesDownloader downloader] nowDownloadingVoice] isEqual:voice]) {
        [cell downloadingProgress:[[SMVoicesDownloader downloader] progress]];
    }
    else if ([[[SMVoicesDownloader downloader] leftVoices] containsObject:voice]) {
        [cell inQueue];
    }
    else {
        [cell availableToBuy];
    }
    
    if ([voice isEqual:self.nowPlayingVoice]) {
        [cell play];
    }
    else {
        [cell stop];
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return section != kSettingsSection ? kSectionHeight : 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    SMSectionView *sectionView = [[SMSectionView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, kSectionHeight)];
    sectionView.titleLabel.text = self.languages[section - 1];
    return sectionView;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == kSettingsSection) {
        if (indexPath.row == kSpeechRateRow) {
            [self performSegueWithIdentifier:kToPickerSegue sender:self];
        }
        else if (indexPath.row == kRestorePurchasesRow) {
            [self p_restorePurchases];
        }
    }
}

#pragma mark - SMVoicesDownloader Delegate

- (void)voicesDownloaderDownload:(SMVoicesDownloader*)downloader progress:(double)progress
{
    [self.tableView reloadData];
}

#pragma mark - SMPickerViewController Delegate

- (void)pickItemAtIndex:(NSInteger)index forOption:(NSInteger)option
{
    [[SMSettings sharedSettings] setSelectedSpeechRateIndex:index];
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:kSpeechRateRow inSection:kSettingsSection]] withRowAnimation:UITableViewRowAnimationFade];
}

@end
