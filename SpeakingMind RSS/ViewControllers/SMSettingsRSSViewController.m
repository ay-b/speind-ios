//
//  SMSettingsRSSViewController.m
//  SpeakingMind RSS
//
//  Created by Sergey Butenko on 20.06.14.
//  Copyright (c) 2014 serejahh inc. All rights reserved.
//

#import "SMSettingsRSSViewController.h"
#import "SMDatabase.h"
#import "SMFeedTreeNodeBuilder.h"
#import "SMSettingsFeedTableViewCell.h"
#import "SMTableViewCell.h"
#import "SMPickerViewController.h"
#import "SMSubtitleTableViewCell.h"
#import "SMSwitchTableViewCell.h"
#import "SMFeedTreeNode.h"
#import "AcapelaSpeech+Speind.h"

#import "RATreeView.h"
#import <AFNetworking/AFNetworking.h>

static NSString* const kLastUsedCountry = @"RSSLastUsedCountry";
static NSString* const kLastUsedLanguage = @"RSSLastUsedLanguage";

static NSString* const kToUserFeedsSegue = @"toUserFeeds";
static NSString* const kToPickerSegue = @"toPicker";

static NSString* const kSimpleCellIdentifier = @"SimpleCell";
static NSString* const kSubtitleCellIdentifier = @"SubtitleCell";
static NSString* const kSwitchCellIdentifier = @"SwitchCell";

static const int kCountRows = 4;
static const int kEnableRow = 0;
static const int kUserFeedsRow = 1;
static const int kLanguageRow = 2;
static const int kCountryRow = 3;

static const int kFeedRowHeight = 44;

@interface SMSettingsRSSViewController () <UITableViewDelegate, UITableViewDataSource, RATreeViewDelegate, RATreeViewDataSource, SMSettingsFeedTableViewCellDelegate, SMPickerViewControllerDelegate>

#pragma mark - UI

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet RATreeView *treeView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *acitiviryIndicator;

#pragma mark - Data

@property (nonatomic) NSArray *data;
@property BOOL needUpdateFeeds;

@property (nonatomic) NSArray *languages;
@property (nonatomic) NSArray *countries;
@property (nonatomic) SMLanguage *selectedLanguage;
@property (nonatomic) NSString *selectedCountry;

@end

@implementation SMSettingsRSSViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.title = LOC(@"RSS");
    
    self.languages = [[SMSettings sharedSettings] supportedLanguages];
    [self p_updateCountriesWithFirstStart:YES];
    
    self.tableView.rowHeight = SMTableViewCellHeight;
    [self.tableView registerNib:[SMTableViewCell nib] forCellReuseIdentifier:kSimpleCellIdentifier];
    [self.tableView registerNib:[SMSubtitleTableViewCell nib] forCellReuseIdentifier:kSubtitleCellIdentifier];
    [self.tableView registerNib:[SMSwitchTableViewCell nib] forCellReuseIdentifier:kSwitchCellIdentifier];
    
    [self p_prepareTreeView];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if (self.needUpdateFeeds) { //
        [[NSNotificationCenter defaultCenter] postNotificationName:SMFeedSourcesChangedNofitication object:self];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if (![segue.identifier isEqualToString:kToPickerSegue]) {
        return;
    }
    
    NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
    
    SMPickerViewController *vc = segue.destinationViewController;
    vc.delegate = self;
    vc.option = indexPath.row;
    
    if (indexPath.row == kCountryRow) {
        vc.dataSource = indexPath.row == kCountryRow ? self.countries : self.languages;
        vc.selectedIndex = [self.countries indexOfObject:self.selectedCountry];
    }
    else {
        vc.dataSource = indexPath.row == kCountryRow ? self.countries : self.languages;
        vc.selectedIndex = [self.languages indexOfObject:self.selectedLanguage];
    }
    
    vc.dataSource = indexPath.row == kCountryRow ? self.countries : self.languages;
    vc.titleString = indexPath.row == kCountryRow ? LOC(@"Country") : LOC(@"Language");
}

#pragma mark - Private

- (void)p_prepareTreeView
{
    [self.treeView registerNib:[SMSettingsFeedTableViewCell nib] forCellReuseIdentifier:@"FeedCell"];

    _treeView.delegate = self;
    _treeView.dataSource = self;
    _treeView.rowHeight = kFeedRowHeight;
    _treeView.separatorStyle = RATreeViewCellSeparatorStyleNone;
    [self p_updateTreeViewData];
}

- (void)p_updateTreeViewData
{
    self.data = nil;
    [_treeView reloadData];
    [_acitiviryIndicator startAnimating];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        self.data = [[SMFeedTreeNodeBuilder sharedBuilder] feedForLang:self.selectedLanguage.shortLocale country:self.selectedCountry];
        dispatch_async(dispatch_get_main_queue(), ^{
            [_acitiviryIndicator stopAnimating];
            [_treeView reloadData];
            
            CATransition *animation = [CATransition animation];
            [animation setType:kCATransitionFade];
            [animation setSubtype:kCATransitionFromBottom];
            [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
            [animation setFillMode:kCAFillModeBoth];
            [animation setDuration:.3];
            [[self.treeView layer] addAnimation:animation forKey:@"UITableViewReloadDataAnimationKey"];
        });
    });
}

- (void)stateSwitchChanged:(UISwitch*)sender
{
    [[SMSettings sharedSettings] setRSSPluginEnabled:sender.isOn];
}

- (void)p_updateCountriesWithFirstStart:(BOOL)firstStart
{
    _countries = [SMDatabase countryForLanguage:self.selectedLanguage.shortLocale];
    NSString *selectedCountry = _selectedCountry;
    NSInteger index = [self.countries indexOfObject:selectedCountry];
    
    if (self.countries.count == 0) {
        [self.navigationController popViewControllerAnimated:YES];
    }
    else {
        if (firstStart) {
            _selectedCountry = [[NSUserDefaults standardUserDefaults] objectForKey:kLastUsedCountry];
            
            // if country has never choosen
            if (!_selectedCountry && [self.countries containsObject:[self myCountry]]) {
                _selectedCountry = [self myCountry];
            }
        }
        
        if (!firstStart || !_selectedCountry)  {
           _selectedCountry = self.countries[index == NSNotFound ? 0 : index];
        }
        
        [[NSUserDefaults standardUserDefaults] setObject:self.selectedCountry forKey:kLastUsedCountry];
        [self.tableView reloadData];
    }
}

- (NSString*)myCountry
{
    NSString *myLang = [NSLocale preferredLanguages][0];
    NSLocale *myLocale = [NSLocale currentLocale];
    NSString *country = [myLocale displayNameForKey: NSLocaleCountryCode value: myLang];
    return country;
}

- (SMLanguage*)mySMLanguage
{
    NSString *myLang = [NSLocale preferredLanguages][0];
    SMLanguage *lang = [SMLanguage langWithLocaleIdentifier:myLang];
    return lang;
}

#pragma mark - Lazy

- (SMLanguage *)selectedLanguage
{
    // restore the last used language
    if (!_selectedLanguage) {
        NSString *locale = [[NSUserDefaults standardUserDefaults] objectForKey:kLastUsedLanguage];
        _selectedLanguage = [SMLanguage langWithLocaleIdentifier:locale];
    }
    
    // try to select a preffered language if it exists in our languages
    if (!_selectedLanguage && [self.languages containsObject:[self mySMLanguage]]) {
        _selectedLanguage = [self mySMLanguage];
    }
    
    // if it still unselected - select the first language
    if (!_selectedLanguage) {
        _selectedLanguage = [self.languages firstObject];
    }
    
    return _selectedLanguage;
}

#pragma mark - TreeView Data Source

- (UITableViewCell *)treeView:(RATreeView *)treeView cellForItem:(SMFeedTreeNode*)item treeNodeInfo:(RATreeNodeInfo *)treeNodeInfo
{
    SMSettingsFeedTableViewCell *cell = [treeView dequeueReusableCellWithIdentifier:@"FeedCell"];
    [cell configureCellWithData:item];
    [cell moveInputViewWithDepth:treeNodeInfo.treeDepthLevel];
    cell.delegate = self;
    cell.expandImageView.hidden = item.isFeed;
    cell.expandImageView.transform = CGAffineTransformMakeRotation(!treeNodeInfo.isExpanded ? 0 : M_PI/2);
    cell.backgroundColor = treeNodeInfo.treeDepthLevel == 0 ? [UIColor whiteColor] : [UIColor groupTableViewBackgroundColor];
    
    return cell;
}

- (NSInteger)treeView:(RATreeView *)treeView numberOfChildrenOfItem:(id)item
{
    if (item == nil) {
        return [self.data count];
    }
    
    SMFeedTreeNode *data = item;
    return [data.children count];
}

- (id)treeView:(RATreeView *)treeView child:(NSInteger)index ofItem:(id)item
{
    SMFeedTreeNode *data = item;
    if (item == nil) {
        return [self.data objectAtIndex:index];
    }
    
    return [data.children objectAtIndex:index];
}

- (BOOL)treeView:(RATreeView *)treeView canEditRowForItem:(id)item treeNodeInfo:(RATreeNodeInfo *)treeNodeInfo
{
    return NO;
}

- (void)treeView:(RATreeView *)treeView didSelectRowForItem:(SMFeedTreeNode*)item treeNodeInfo:(RATreeNodeInfo *)treeNodeInfo;
{
    SMSettingsFeedTableViewCell *cell = (SMSettingsFeedTableViewCell*)[_treeView cellForItem:item];
    cell.expandImageView.transform = CGAffineTransformMakeRotation(treeNodeInfo.isExpanded ? 0 : M_PI/2);
    
    if (item.isFeed) {
        [cell selectFeedButtonPressed:nil];
    }
}

#pragma mark - SMSettingsFeedTableViewCell Delegate

- (void)childrenForCellDidUpdated:(SMSettingsFeedTableViewCell *)cell
{
    self.needUpdateFeeds = YES;
    
    SMFeedTreeNode *d0 = [self.data firstObject];
    SMFeedTreeNode *d1 = [self.data lastObject];
    [d0 updateSelection];
    [d1 updateSelection];
    
    [self.treeView reloadRows];
}

#pragma mark - UITableView Delegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return kCountRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == kEnableRow) {
        SMSwitchTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kSwitchCellIdentifier forIndexPath:indexPath];
        cell.titleLabel.text = LOC(@"Enabled");
        cell.stateSwitch.on = [[SMSettings sharedSettings] isRSSPluginEnabled];
        [cell.stateSwitch addTarget:self action:@selector(stateSwitchChanged:) forControlEvents:UIControlEventValueChanged];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
    }
    else if (indexPath.row == kUserFeedsRow) {
        SMTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kSimpleCellIdentifier forIndexPath:indexPath];
        cell.titleLabel.text = LOC(@"User feeds");
        return cell;
    }
    
    SMSubtitleTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kSubtitleCellIdentifier forIndexPath:indexPath];
    if (indexPath.row == kLanguageRow) {
        cell.titleLabel.text = LOC(@"Language");
        cell.subtitleLabel.text = [self.selectedLanguage description];
    }
    else  if (indexPath.row == kCountryRow) {
        cell.titleLabel.text = LOC(@"Country");
        cell.subtitleLabel.text = self.selectedCountry;
    }
    cell.valueSubtitleLabel.text = nil;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.row == kEnableRow) {
        return;
    }
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    [self performSegueWithIdentifier: indexPath.row == kUserFeedsRow ? kToUserFeedsSegue : kToPickerSegue sender:cell];
}

#pragma mark - SMPickerViewController Delegate

- (void)pickItemAtIndex:(NSInteger)index forOption:(NSInteger)option
{
    if (option == kCountryRow) {
        self.selectedCountry = self.countries[index];
        [[NSUserDefaults standardUserDefaults] setObject:self.selectedCountry forKey:kLastUsedCountry];
    }
    else {
        self.selectedLanguage = self.languages[index];
        [[NSUserDefaults standardUserDefaults] setObject:self.selectedLanguage.locale forKey:kLastUsedLanguage];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self p_updateCountriesWithFirstStart:NO];
    [self p_updateTreeViewData];
}

@end
