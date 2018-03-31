//
//  SMMainViewController.m
//  SpeakingMind RSS
//
//  Created by Sergey Butenko on 02.06.14.
//  Copyright (c) 2014 serejahh inc. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "SMMainViewController.h"
#import "SMNewsPreviewView.h"
#import "SMDatabase.h"
#import "SMInfopointsStorage.h"
#import "SMInfopoint.h"
#import "SMVoiceManager.h"
#import "SMInfopointsDownloader.h"
#import "SMInfopointsFetcherUtilities.h"
#import "SMInfopointNews.h"
#import "SMVoicesDownloader.h"
#import "SMInfopointListTableViewCell.h"
#import "SMInfopointListDetailsViewController.h"
#import "SMSpeechSynthesizer.h"
#import "SMFeedItem.h"
#import "NSString+TimeToString.h"
#import "NSString+Language.h"

#import "TFTaifuno.h"
#import "SwipeView.h"
#import "GVMusicPlayerController.h"
#import <AFNetworking/AFNetworking.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import <RMStore/RMStore.h>
#import <Block-KVO/MTKObserving.h>
#import <MMDrawerController/UIViewController+MMDrawerController.h>

static const NSTimeInterval kScrollInterval = 0.5;
static const NSTimeInterval kChangeLeftButtonInterval = 5;
static const NSTimeInterval kPlaybackInterval = 0.5;

NSString*const kSettingsSegue = @"toRSSSettingsFromMain";

typedef NS_ENUM(NSUInteger, SMPlayingState) {
    SMPlayingStateStop,
    SMPlayingStateReadingNews,
    SMPlayingStatePlayingMusic
};

static NSString*const kCellIdentifier = @"ListCell";

@interface SMMainViewController () <SwipeViewDataSource, SwipeViewDelegate, GVMusicPlayerControllerDelegate, SMInfopointsDownloaderDelegate, UITableViewDataSource, UITableViewDelegate, SMSpeechSynthesizerDelegate>
{
    BOOL showedDescription;
    BOOL leftButtonChanged;
    BOOL canSpeakSameInfopoint;
    BOOL isListening;
    
    NSTimer *leftButtonTimer;
    NSTimer *updateNewsTimer;
    NSTimer *playbackTimer;
    
    NSTimeInterval spentTimeForPlaying;
    NSDate *lastChangedStateDate;
    
    SMInfopoint *previousInfopoint;
}
@property (nonatomic) SMInfopointsDownloader *infopointsDownloader;

@property (nonatomic) NSMutableArray *infopoints;
@property (nonatomic) SMPlayingState playingState;
@property (nonatomic) SMReadArticleType readingState;

@property (nonatomic) NSNumber *playerIndex;
@property (nonatomic) NSNumber *lastIndex;
@property (nonatomic) NSOperationQueue *downloadFullArticleQueue;

@property (nonatomic) SMSpeechSynthesizer *speechSynthesize;

#pragma mark - UI

@property (weak, nonatomic) IBOutlet UITableView *tableView;

#pragma mark Top View

@property (weak, nonatomic) IBOutlet UIVisualEffectView *leftSourcesContainer;
@property (weak, nonatomic) IBOutlet UIImageView *downloadingIndicator;
@property (weak, nonatomic) IBOutlet UILabel *leftSourcesLabel;
@property (weak, nonatomic) IBOutlet SwipeView *newsSwipeView;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;

#pragma mark Infopoint View

@property (weak, nonatomic) IBOutlet UIView *newsView; // contains all below
@property (weak, nonatomic) IBOutlet UIImageView *providerIconImageView;
@property (weak, nonatomic) IBOutlet UIImageView *sourceIconImageView;
@property (weak, nonatomic) IBOutlet UILabel *feedInfoLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UITextView *descriptionTextView;

#pragma mark Player

@property (weak, nonatomic) IBOutlet UIView *playerView; // contains all below
@property (weak, nonatomic) IBOutlet UILabel *artistLabel;
@property (weak, nonatomic) IBOutlet UILabel *songLabel;
@property (weak, nonatomic) IBOutlet UILabel *albumLabel;
@property (weak, nonatomic) IBOutlet UILabel *playbackLabel;
@property (weak, nonatomic) IBOutlet UILabel *durationLabel;

#pragma mark Bottom Buttons

- (IBAction)leftButtonPressed:(UIButton*)sender;
- (IBAction)playButtonPressed:(UIButton*)sender;
- (IBAction)rightButtonPressed:(UIButton*)sender;

@property (weak, nonatomic) IBOutlet UIButton *leftButton;
@property (weak, nonatomic) IBOutlet UIButton *playPauseButton;
@property (weak, nonatomic) IBOutlet UIButton *rightButton;

@end

@implementation SMMainViewController

@synthesize playingState = _playingState;

#pragma mark - View lifecycle

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.newsSwipeView setNeedsDisplay];
    [self.newsSwipeView reloadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.downloadFullArticleQueue = [[NSOperationQueue alloc] init];
    [self.downloadFullArticleQueue setMaxConcurrentOperationCount:1];
    [self restoreSession];
    [self checkFullArticles];
    [self prepareTableView];
    [self preparePlayer];
    [self prepareView];
    [self updateView];
    [self registerNofitications];
    spentTimeForPlaying = 0;
    
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        if ([[AFNetworkReachabilityManager sharedManager] isReachable]) {
            [self setupStore];
            [self updateInfopointsTimer];
            [[SMVoicesDownloader downloader] refreshVoices];
        }
    }];
    
    if (self.mm_drawerController.navigationController.viewControllers.count > 1 && [[AFNetworkReachabilityManager sharedManager] isReachable]) {
        [self setupStore];
        [self updateInfopointsTimer];
        [[SMVoicesDownloader downloader] refreshVoices];
    }
    
    [self observeProperty:@keypath(self.lastIndex) withBlock:^(__weak id self, NSNumber* old, NSNumber* new) {
        [[SMInfopointsStorage sharedInstance] setCurrentIndex:new];
    }];
    
    [self observeProperty:@keypath(self.playerIndex) withBlock:^(__weak id self, NSNumber* old, NSNumber* new) {
        [[SMInfopointsStorage sharedInstance] setPlayerIndex:new];
    }];
    
    NSDictionary *info = [[NSUserDefaults standardUserDefaults] objectForKey:SMTaifunoUserInfo];
    if (info) {
         [[TFTaifuno sharedInstance] startChatOnViewController:self withInfo:[[SMSettings sharedSettings] taifunoUserInfo]];
    }
}

- (void)setupStore
{
    DLog(@"Store setupped");
    
    // set voices
    NSMutableArray *uids = [NSMutableArray array];
    for (SMVoice *voice in [SMVoiceManager sharedManager].voices) {
        [uids addObject:voice.productID];
    }
    
    // set plugins
    NSArray *plugins = [SMPlugin availablePlugins];
    for (SMPlugin *plugin in plugins) {
        [uids addObject:plugin.productID];
    }
    
    NSSet *products = [NSSet setWithArray:uids];
    [[RMStore defaultStore] requestProducts:products success:^(NSArray *products, NSArray *invalidProductIdentifiers) {
        [[SMSettings sharedSettings] setInavailableProducts:invalidProductIdentifiers];
    } failure:nil];
}

- (void)didReceiveMemoryWarning
{
    [[SDImageCache sharedImageCache] clearMemory];
    [super didReceiveMemoryWarning];
}

#pragma mark - Infopoints updating

- (void)updateInfopointsTimer
{
    DLog(@"News timer updated");
    [updateNewsTimer invalidate];
    
    NSTimeInterval updateInterval = [[SMSettings sharedSettings] selectedUpdatingIntervalValue];
    updateNewsTimer = [NSTimer scheduledTimerWithTimeInterval:updateInterval target:self.infopointsDownloader selector:@selector(requestInfopoints) userInfo:nil repeats:YES];
    [updateNewsTimer fire];
    [self updateLeftSourceView];
}

#pragma mark - Properties

- (void)setPlayingState:(SMPlayingState)playingState
{
    SMPlayingState previousState = _playingState;
    _playingState = playingState;
    previousInfopoint = nil;
    
    switch (_playingState) {
        case SMPlayingStateReadingNews: // start TTS, stop music, change play button
            [self.playPauseButton setImage:[UIImage imageNamed:@"button_pause"] forState:UIControlStateNormal];
            
            lastChangedStateDate = [NSDate date];
            [self startSpeaking];
            if (previousState != _playingState) {
                [[GVMusicPlayerController sharedInstance] stop];
            }
            break;
        case SMPlayingStatePlayingMusic: // stop TTS, play music, change play button, start timer
            [self.playPauseButton setImage:[UIImage imageNamed:@"button_pause"] forState:UIControlStateNormal];
            
            lastChangedStateDate = [NSDate date];
            [self.speechSynthesize stopSpeaking];
            if (previousState != _playingState) {
                [[GVMusicPlayerController sharedInstance] play];
                if ([[GVMusicPlayerController sharedInstance] currentPlaybackTime] < kChangeLeftButtonInterval) {
                    [self beginRepeatButton];
                }
            }
            break;
        case SMPlayingStateStop: // stop TTS, stop music, change UI to default
            [self.playPauseButton setImage:[UIImage imageNamed:@"button_play"] forState:UIControlStateNormal];
            
            lastChangedStateDate = nil;
            spentTimeForPlaying = 0;
            
            // because stopSpeaking sometimes takes a half second for stopping
            self.playPauseButton.enabled = NO;
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                [self.speechSynthesize pauseSpeaking];
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.playPauseButton.enabled = YES;
                });
            });
            
            [[GVMusicPlayerController sharedInstance] pause];
            break;
    }
    
    NSString *state;
    if ([self playingState] == SMPlayingStatePlayingMusic) {
        state = @"playing";
    }
    else if ([self playingState] == SMPlayingStateReadingNews) {
        state = @"reading";
    }
    else if ([self playingState] == SMPlayingStateStop) {
        state = @"stop";
    }
    DLog(@"STATE: %@ - %@", [self isPlayerNow] ? @"Player" : @"News", state);
}

- (BOOL)isPlayerNow
{
    return self.newsSwipeView.currentItemIndex == self.playerIndex.intValue;
}

#pragma mark Lazy instantiation

- (NSMutableArray *)infopoints
{
    if (!_infopoints) {
        _infopoints = [NSMutableArray array];
    }
    return _infopoints;
}

- (SMInfopointsDownloader *)infopointsDownloader
{
    if (!_infopointsDownloader) {
        _infopointsDownloader = [SMInfopointsDownloader downloaderWithDelegate:self];
    }
    return _infopointsDownloader;
}

- (SMSpeechSynthesizer *)speechSynthesize
{
    if (!_speechSynthesize) {
        _speechSynthesize = [SMSpeechSynthesizer synthesizerWithDelegate:self];
    }
    return _speechSynthesize;
}

#pragma mark - Preparations

- (void)restoreSession
{
    self.infopoints = [[SMInfopointsStorage sharedInstance] data];
    NSArray *oldNews = [self p_oldNews:self.infopoints];
    [self.infopoints removeObjectsInArray:oldNews];
    [[SMInfopointsStorage sharedInstance] saveData];
    [self.newsSwipeView reloadData];
    
    NSInteger index = [[SMInfopointsStorage sharedInstance] currentIndex].intValue - oldNews.count;
    if (index < 0) index = 0;
    self.playerIndex = @([[SMInfopointsStorage sharedInstance] playerIndex].intValue - oldNews.count);
    if (self.playerIndex.intValue < 0 ) {
        self.playerIndex = @(self.infopoints.count);
    }
    DLog(@"Scroll to: %@; player = %@", @(index), self.playerIndex);
    [self.newsSwipeView scrollToItemAtIndex:index duration:0];
}

- (void)checkFullArticles
{
    for (SMInfopoint* infopoint in self.infopoints) {
        if (!infopoint.fullArticle) {
            [self downloadFullArticleForInfopoint:infopoint];
        }
    }
}

- (NSMutableArray*)p_oldNews:(NSArray*)candidates
{
    NSMutableArray *newestNews = [NSMutableArray array];
    
    NSInteger oldestPubDateInterval = [[SMSettings sharedSettings] selectedSaveHistoryValue] * SMOneDay;
    for (SMInfopoint *item in candidates) {
        NSTimeInterval pubDateInterval = [[NSDate date] timeIntervalSinceDate:item.pubDate];
        if (oldestPubDateInterval < pubDateInterval) {
            [newestNews addObject:item];
        }
    }
    
    return newestNews;
}

- (void)prepareTableView
{
    [self.tableView registerNib:[SMInfopointListTableViewCell nib] forCellReuseIdentifier:kCellIdentifier];
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 6)];
    footerView.backgroundColor = SMGrayColor;
    self.tableView.tableFooterView = footerView;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    [self.tableView reloadData];
    self.tableView.scrollsToTop = NO;
}

- (void)preparePlayer
{
    [[GVMusicPlayerController sharedInstance] addDelegate:self];
    
    MPMediaQuery *query = [MPMediaQuery songsQuery];
    NSMutableArray *shortItems = [NSMutableArray array];
    for (MPMediaItem *song in query.items) {
        if (!song.isCloudItem) {
            [shortItems addObject:song];
        }
    }
    if (shortItems.count > 0) {
        MPMediaItemCollection *collection = [MPMediaItemCollection collectionWithItems:shortItems];
        [[GVMusicPlayerController sharedInstance] setQueueWithItemCollection:collection];
    }
    
    [GVMusicPlayerController sharedInstance].shuffleMode = MPMusicShuffleModeSongs;
    [GVMusicPlayerController sharedInstance].repeatMode = MPMusicRepeatModeAll;
    playbackTimer = [NSTimer scheduledTimerWithTimeInterval:kPlaybackInterval target:self selector:@selector(playbackTimeUpdated) userInfo:nil repeats:YES];
    [playbackTimer fire];
}

- (void)registerNofitications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startWithUnsupportedLocale:) name:SMUnsupportedLocaleNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(remoteControlReceivedWithEvent:) name:SMRemoteControlNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioRouteChangeListenerCallback:) name:AVAudioSessionRouteChangeNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(readingStyleChanged) name:SMReadNewsNotification object:nil];
    [self readingStyleChanged];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateInfopointsTimer) name:SMUpdatingIntervalNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateFeedSources) name:SMFeedSourcesChangedNofitication object:nil];
}

- (void)configureNavigationBar
{
    UIImage *sidebarButtonImage = [UIImage imageNamed:@"button_sidebar"];
    CGRect sidebarButtonRect = CGRectMake(0,0, sidebarButtonImage.size.width, sidebarButtonImage.size.height);
    UIButton *sidebarBarButton = [[UIButton alloc] initWithFrame:sidebarButtonRect];
    [sidebarBarButton setBackgroundImage:sidebarButtonImage forState:UIControlStateNormal];
    [sidebarBarButton addTarget:self action:@selector(sidebarButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *sidebarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:sidebarBarButton];
    self.navigationItem.leftBarButtonItem = sidebarButtonItem;
    
    isListening = YES;
    [self updateReadingMode];
}

- (void)updateReadingMode
{
    UIImage *listButtonImage = [UIImage imageNamed:isListening ? @"button_list" : @"button_listen"];
    CGRect listButtonRect = CGRectMake(0,0, listButtonImage.size.width, listButtonImage.size.height);
    UIButton *listBarButton = [[UIButton alloc] initWithFrame:listButtonRect];
    [listBarButton setBackgroundImage:listButtonImage forState:UIControlStateNormal];
    [listBarButton addTarget:self action:@selector(listButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *listButtonItem = [[UIBarButtonItem alloc] initWithCustomView:listBarButton];
    self.navigationItem.rightBarButtonItem = listButtonItem;
}

- (void)updateFeedSources
{
    NSMutableArray *infopointsToDelete = [NSMutableArray array];
    NSArray *feeds = [SMDatabase selectedFeeds];
    for (NSInteger i = self.newsSwipeView.currentItemIndex+1 ; i < self.infopoints.count; i++)  {
        SMInfopoint *infopoint = self.infopoints[i];
        BOOL infopointForSelectedFeed = NO;
        for (SMFeedItem *feed in feeds) {
            if ([infopoint.postSender containsString:feed.provider]) {
                infopointForSelectedFeed = YES;
                break;
            }
        }
        if (!infopointForSelectedFeed) {
            [infopointsToDelete addObject:infopoint];
        }
    }
    
    @synchronized(self.infopoints) {
        [self.infopoints removeObjectsInArray:infopointsToDelete];
        [self.tableView reloadData];
        [self.newsSwipeView reloadData];
    }
    
    [self updateInfopointsTimer];
}

- (void)prepareView
{
    self.navigationItem.title = LOC(@"Title - Main");
    [self.navigationItem setHidesBackButton:YES];
    
    self.descriptionTextView.textContainerInset = UIEdgeInsetsZero;
    
    [self addGestureHandles];
    [self configureNavigationBar];
    
    self.newsSwipeView.alignment = SwipeViewAlignmentCenter;
    self.newsSwipeView.pagingEnabled = YES;
    self.newsSwipeView.itemsPerPage = 1;
    self.newsSwipeView.truncateFinalPage = YES;
}

- (void)updateView
{
    DLog(@"update view");
    if (isListening) {
        self.lastIndex = @(self.newsSwipeView.currentItemIndex);
    }
    
    if ([self isPlayerNow]) {
        if ([[GVMusicPlayerController sharedInstance] nowPlayingItem]) {
            self.playerView.hidden = NO;
        }
        self.newsView.hidden = YES;
        
        MPMediaItem *nowPlaying = [[GVMusicPlayerController sharedInstance] nowPlayingItem];
        
        if (nowPlaying) {
            NSMutableDictionary *mediaInfo = [NSMutableDictionary dictionary];
            if (nowPlaying.title) {
                mediaInfo[MPMediaItemPropertyTitle] = nowPlaying.title;
            }
            if (nowPlaying.artist) {
                mediaInfo[MPMediaItemPropertyArtist] = nowPlaying.artist;
            }
            if (nowPlaying.artwork) {
                mediaInfo[MPMediaItemPropertyArtwork] = nowPlaying.artwork;
            }
            else {
                mediaInfo[MPMediaItemPropertyArtwork] = [[MPMediaItemArtwork alloc] initWithImage:[UIImage imageNamed:@"placeholder"]];
            }
            
            mediaInfo[MPMediaItemPropertyPlaybackDuration] = [nowPlaying valueForProperty:MPMediaItemPropertyPlaybackDuration];
            [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:mediaInfo];
        }
        return;
    }
    else {
        self.playerView.hidden = YES;
        self.newsView.hidden = NO;
    }
    
    NSInteger index = self.newsSwipeView.currentItemIndex;
    if (self.newsSwipeView.currentItemIndex >= self.infopoints.count) {
        index--;
    }
    
    //    if (self.infopoints.count)
    
    SMInfopoint *item = self.infopoints[index];
    self.dateLabel.text = [NSString stringFromDate:item.pubDate];
    [self.descriptionTextView setContentOffset:CGPointZero animated:NO];
    self.feedInfoLabel.text = item.postSender ? item.postSender : @"";
    [self.providerIconImageView sd_setImageWithURL:[NSURL URLWithString:item.senderIcon] placeholderImage:[UIImage imageNamed:@"provider_default"]];
    self.sourceIconImageView.image = item.sourceIcon;
    
    // item on the locked screen
    UIImage *placeholder = [UIImage imageNamed:item.placeholder];
    UIImage *cachedImage = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:item.enclosure];
    if (cachedImage) {
        placeholder = cachedImage;
    }
    MPMediaItemArtwork *albumArt = [[MPMediaItemArtwork alloc] initWithImage:placeholder];
    
    NSDictionary *mediaInfo = @{MPMediaItemPropertyTitle : item.title ? item.title : @"",
                                MPMediaItemPropertyArtist : item.postSender ? item.postSender : @"",
                                MPMediaItemPropertyArtwork : albumArt
                                };
    [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:mediaInfo];
    
    if ([item isKindOfClass:[SMInfopointNews class]]) {
        if (item.fullArticle && [[SMSettings sharedSettings] isReadFullArticle]) {
            showedDescription = YES;
        }
        else {
            showedDescription = NO;
            if ([[SMSettings sharedSettings] isReadFullArticle]) {
                [self showDetailDescription];
            }
        }
    }
    
    self.descriptionTextView.text = [item displayingTextForFullArticle:showedDescription];
    
    if (![self isPlayerNow] && [self playingState] == SMPlayingStatePlayingMusic) {
        self.playingState = SMPlayingStateReadingNews;
    }
    else if ([self isPlayerNow] && [self playingState] == SMPlayingStateReadingNews) {
        self.playingState = SMPlayingStatePlayingMusic;
    }
    else if (![self isPlayerNow] && [self playingState] == SMPlayingStateReadingNews) {
        [self continueReading];
    }
}

#pragma mark - System

// If the user pulls out he headphone jack, stop playing.
- (void)audioRouteChangeListenerCallback:(NSNotification*)notification
{
    NSDictionary *interuptionDict = notification.userInfo;
    AVAudioSessionRouteChangeReason routeChangeReason = [[interuptionDict valueForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
    
    if (routeChangeReason == AVAudioSessionRouteChangeReasonOldDeviceUnavailable) {
        self.playingState = SMPlayingStateStop;
    }
}

- (void)readingStyleChanged
{
    self.readingState = [[SMSettings sharedSettings] selectedReadArticleValue];
    DLog(@"Reading style changed: %lu", self.readingState);
}

- (void)startWithUnsupportedLocale:(NSNotification*)sender
{
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"" message:LOC(@"Unsupported locale instruction") preferredStyle:UIAlertControllerStyleAlert];
    [alertVC addAction:[UIAlertAction actionWithTitle:LOC(@"Go settings") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self.mm_drawerController performSegueWithIdentifier:kSettingsSegue sender:self];
    }]];
    [alertVC addAction:[UIAlertAction actionWithTitle:LOC(@"Ok, I got it") style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:alertVC animated:YES completion:nil];
}

#pragma mark - Gesture Handlers

- (void)addGestureHandles
{
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
    [self.rightButton addGestureRecognizer:longPress];
    
    UISwipeGestureRecognizer* swipeUpGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeUpFrom:)];
    swipeUpGestureRecognizer.direction = UISwipeGestureRecognizerDirectionUp;
    [self.newsSwipeView addGestureRecognizer:swipeUpGestureRecognizer];
    
    UISwipeGestureRecognizer* swipeDownGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeDownFrom:)];
    swipeDownGestureRecognizer.direction = UISwipeGestureRecognizerDirectionDown;
    [self.newsSwipeView addGestureRecognizer:swipeDownGestureRecognizer];
}

- (void)handleSwipeUpFrom:(UIGestureRecognizer*)gesture
{
    [[[UIAlertView alloc] initWithTitle:@"Swipe" message:@"Up" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
}

- (void)handleSwipeDownFrom:(UIGestureRecognizer*)gesture
{
    [[[UIAlertView alloc] initWithTitle:@"Swipe" message:@"Down" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
}

- (void)longPress:(UILongPressGestureRecognizer*)gesture
{
    if (![self isPlayerNow] && gesture.state == UIGestureRecognizerStateBegan) {
        [self.newsSwipeView scrollToItemAtIndex:self.newsSwipeView.numberOfItems-1 duration:kScrollInterval];
    }
}

#pragma mark - UI Interaction

- (void)setRepeatLeftButton
{
    leftButtonChanged = YES;
    [self.leftButton setImage:[UIImage imageNamed:@"button_repeat"] forState:UIControlStateNormal];
}

- (void)setDefaultLeftButton
{
    leftButtonChanged = NO;
    [self.leftButton setImage:[UIImage imageNamed:@"button_left"] forState:UIControlStateNormal];
    [leftButtonTimer invalidate];
}

- (void)beginRepeatButton
{
    [self setDefaultLeftButton];
    leftButtonTimer = [NSTimer scheduledTimerWithTimeInterval:kChangeLeftButtonInterval target:self selector:@selector(setRepeatLeftButton) userInfo:nil repeats:NO];
}

- (IBAction)leftButtonPressed:(UIButton*)sender
{
    BOOL leftButtonWasChanged = leftButtonChanged;
    [self setDefaultLeftButton];
    
    if (leftButtonWasChanged) {
        canSpeakSameInfopoint = YES;
        [self beginRepeatButton];
        [[GVMusicPlayerController sharedInstance] repeat];
        if ([self playingState] == SMPlayingStatePlayingMusic) { // for player
            
//            [[GVMusicPlayerController sharedInstance] play];
        }
        else if ([self playingState] == SMPlayingStateReadingNews) { // for news
            [self.speechSynthesize stopSpeaking];
            [self startSpeaking];
        }
    }
    else {
        [self gotoLeftFromPlayer:[self isPlayerNow]];
    }
}

- (IBAction)rightButtonPressed:(UIButton*)sender
{
    [self.speechSynthesize stopSpeaking];
    [self gotoRightFromPlayer:[self isPlayerNow]];
}

- (IBAction)playButtonPressed:(UIButton*)sender
{
    if ([self playingState] == SMPlayingStateStop) {
        self.playingState = [self isPlayerNow] ? SMPlayingStatePlayingMusic : SMPlayingStateReadingNews;
    }
    else {
        self.playingState = SMPlayingStateStop;
    }
}

- (void)showDetailDescription
{
    if (showedDescription) {
        return;
    }
    
    SMInfopoint *item = self.infopoints[self.newsSwipeView.currentItemIndex];
    if (item.fullArticle) {
        showedDescription = YES;
        canSpeakSameInfopoint = YES;
        self.descriptionTextView.text = [item displayingTextForFullArticle:showedDescription];
        [self continueReading];
        return;
    }
    
    [SMInfopointsFetcherUtilities downloadFullArticleForNews:item success:^(NSString *article) {
        SMInfopoint *currentItem = self.infopoints[self.newsSwipeView.currentItemIndex];
        if ([currentItem isEqual:item]) {
            showedDescription = YES;
            self.descriptionTextView.text = [item displayingTextForFullArticle:showedDescription];
            canSpeakSameInfopoint = YES;
            [self continueReading];
            
            [[SMInfopointsStorage sharedInstance] saveData];
        }
    } failure:^(NSError *error) {
        showedDescription = NO;
    }];
}

static BOOL continueFromReading = YES;
- (void)listButtonPressed
{
    isListening = !isListening;
    
    [self updateReadingMode];
    [UIView animateWithDuration:0.3 animations:^{
        self.tableView.alpha = isListening ? 0 : 1;
    }];
    
    if (!isListening) {
        NSInteger index = self.lastIndex.intValue;
        if ([self isPlayerNow]) {
            index--;
        }
        if (index < self.infopoints.count) {
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
        }
        
        continueFromReading = ![self isPlayerNow];
        if (![self isPlayerNow]) {
            [self gotoMusicFromLeft:NO];
        }
    }
    else {
        if ([self playingState] == SMPlayingStatePlayingMusic) {
            self.playerIndex = @(self.lastIndex.intValue);
        }
        
        [self.newsSwipeView scrollToItemAtIndex:self.lastIndex.intValue duration:0];
        [self.newsSwipeView reloadData];
        [self updateView];
    }
}

- (void)sidebarButtonPressed
{
    [self.mm_drawerController openDrawerSide:MMDrawerSideLeft animated:YES completion:nil];
}

#pragma mark - TTS Delegate

- (void)startSpeaking
{
    NSLog(@"speak");
    [[GVMusicPlayerController sharedInstance] stop];
    
    NSInteger index = self.newsSwipeView.currentItemIndex;
    if ([self isPlayerNow]) {
        index--;
    }
    
    SMInfopoint *currentItem = self.infopoints[index];
    if ([currentItem isEqual:previousInfopoint] && !canSpeakSameInfopoint) {
        return;
    }
    
    [self beginRepeatButton];
    
    [self.speechSynthesize startSpeakingInfopoint:currentItem previousInfopoint:previousInfopoint fullArticle:showedDescription];
    previousInfopoint = currentItem;
    canSpeakSameInfopoint = NO;
}

- (void)continueReading
{
    if ([self playingState] == SMPlayingStateReadingNews) {
        [self startSpeaking];
    }
}

#pragma mark - SwipeView Delegate

- (NSInteger)numberOfItemsInSwipeView:(SwipeView *)swipeView
{
    return self.infopoints.count + 1;
}

- (SMNewsPreviewView *)swipeView:(SwipeView *)swipeView viewForItemAtIndex:(NSInteger)index reusingView:(SMNewsPreviewView *)view
{
    //if (!view) {
    view = [[[NSBundle mainBundle] loadNibNamed:@"SMNewsPreviewView" owner:self options:nil] firstObject];
    //}
    CGRect frame = view.frame;
    frame.size.height = frame.size.width = [UIScreen mainScreen].bounds.size.width;
    view.frame = frame;
    view.clipsToBounds = YES;
    
    // for player
    if (index == self.playerIndex.intValue) {
        MPMediaItemArtwork *artwork = [[[GVMusicPlayerController sharedInstance] nowPlayingItem] valueForProperty:MPMediaItemPropertyArtwork];
        view.previewImageView.image = [artwork imageWithSize:view.previewImageView.frame.size];
        if (!view.previewImageView.image) {
            view.previewImageView.image = [UIImage imageNamed:@"placeholder"];
        }
        return view;
    }
    showedDescription = NO;
    
#warning fix
    // если плеер не последний - надо смещать индекс
    int offset = index > self.playerIndex.intValue ? -1 : 0;
    if (index+offset >= self.infopoints.count) {
        index--;
    }
    if (index < 0) {
        index = 0;
    }
    SMInfopoint *item = self.infopoints[index + offset];
    
    UIImage *placeholder = [UIImage imageNamed:item.placeholder];
    view.previewImageView.image = placeholder;
    
    UIImage *cachedImage = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:item.enclosure];
    if (cachedImage) {
        view.previewImageView.image = cachedImage;
    }
    else if ([self shouldLoadImage]) {
        [view.previewImageView sd_setImageWithURL:[NSURL URLWithString:item.enclosure] placeholderImage:placeholder options:SDWebImageContinueInBackground completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            [[SDImageCache sharedImageCache] storeImage:image forKey:item.enclosure];
        }];
    }
    
    return view;
}

- (BOOL)shouldLoadImage
{
    if ([[SMSettings sharedSettings] isLoadImagesOnlyViaWiFi]) {
        return [[AFNetworkReachabilityManager sharedManager] isReachableViaWiFi];
    }
    
    return YES;
}

// end swiping on view
- (void)swipeViewDidEndDecelerating:(SwipeView *)swipeView
{
    NSLog(@"1");
    if (swipeView.currentItemIndex == _lastIndex.intValue) return;
    [self swipeViewCurrentItemIndexDidChange];
}

// tap on a infopoint
- (void)swipeView:(SwipeView *)swipeView didSelectItemAtIndex:(NSInteger)index
{
    NSLog(@"2");
    
    if (![self isPlayerNow] && _lastIndex.intValue == swipeView.currentItemIndex) {
        [self showDetailDescription];
    }
}

// when the app in bg, it calls when view is appearing
// tap on left/right part of news or on bottom buttons
- (void)swipeViewDidEndScrollingAnimation:(SwipeView *)swipeView
{
    NSLog(@"3");
    if ([[UIApplication sharedApplication] applicationState] != UIApplicationStateBackground) {
        [self swipeViewCurrentItemIndexDidChange];
    }
}

// scrolled to left/right part on news, but not end gesture
- (void)swipeViewCurrentItemIndexDidChange:(SwipeView *)swipeView
{
    NSLog(@"4");
    if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground) {
        [self swipeViewCurrentItemIndexDidChange];
    }
}

#pragma mark - Custom actions

// common action for swiping
- (void)swipeViewCurrentItemIndexDidChange
{
    NSLog(@"5");
    
    [self.speechSynthesize infopointHasSkipped];
    self.progressView.progress = 0;
    [self setDefaultLeftButton];
    
    // hide player
    int index = (int)(self.newsSwipeView.currentItemIndex - self.playerIndex.intValue);
    if (abs(index) == 1 && self.playerIndex.intValue != self.infopoints.count) { // 'cuz can swipe more than 1 news
        
        self.playerIndex = @(self.infopoints.count);
        if (index < 0) {
            [self.newsSwipeView scrollToItemAtIndex:self.newsSwipeView.currentItemIndex duration:0];
        }
        else {
            [self.newsSwipeView scrollToItemAtIndex:self.newsSwipeView.currentItemIndex - 1 duration:0];
        }
        [self.newsSwipeView reloadData];
    }
    
    if ([self isPlayerNow] && [self playingState] == SMPlayingStateReadingNews) {
        self.playingState = SMPlayingStatePlayingMusic;
    }
    else if (![self isPlayerNow] && [self playingState] == SMPlayingStatePlayingMusic) {
        //self.playingState = SMPlayingStateReadingNews;
    }
    
    [self updateView];
}

- (void)nextNews
{
    [self.newsSwipeView scrollToItemAtIndex:self.newsSwipeView.currentItemIndex+1 duration:kScrollInterval];
}

- (void)previousNews
{
    [self.newsSwipeView scrollToItemAtIndex:self.newsSwipeView.currentItemIndex-1 duration:kScrollInterval];
}

- (void)gotoLeftFromPlayer:(BOOL)isPlayer
{
    if (!isListening) {
        [self previousSong];
        return;
    }
    
    if (isPlayer) {
        if (self.readingState == SMReadArticleAll) {
            [self gotoNewsFromLeft:YES];
        }
        else if (self.readingState == SMReadArticleOne) {
            [self gotoNewsFromLeft:YES];
        }
        else { // X minutes
            [self previousSong];
        }
    }
    else {
        if (self.readingState == SMReadArticleAll) {
            [self previousNews];
        }
        else if (self.readingState == SMReadArticleOne) {
            if ([GVMusicPlayerController sharedInstance].queue.count == 0) {
                [self previousNews];
            }
            else {
                [self gotoMusicFromLeft:YES];
                [self previousSong];
            }
        }
        else { // X minutes
            [self previousNews];
        }
    }
}

- (void)gotoRightFromPlayer:(BOOL)isPlayer
{
    if (!isListening) {
        [self nextSong];
        return;
    }
    
    if (isPlayer) {
        if (self.readingState == SMReadArticleAll) {
            if (self.newsSwipeView.currentItemIndex != self.newsSwipeView.numberOfItems) { // если появились новости - читаем их
                [self gotoNewsFromLeft:NO];
            }
            else { // иначе дальше слушаем музыку
                [self nextSong];
            }
        }
        else if (self.readingState == SMReadArticleOne) {
            [self gotoNewsFromLeft:NO];
        }
        else { // X minutes
            if (lastChangedStateDate) {
                spentTimeForPlaying += [[NSDate date] timeIntervalSinceDate:lastChangedStateDate];
            }
            else {
                spentTimeForPlaying = 0;
            }
            NSTimeInterval threshold = [[SMSettings sharedSettings] timeForReadArticleValue:self.readingState];
            DLog(@"Threshold player: %lf/%ff (%@)", spentTimeForPlaying, threshold, lastChangedStateDate);
            
            lastChangedStateDate = [NSDate date];
            if (spentTimeForPlaying > threshold) {
                spentTimeForPlaying = 0;
                DLog(@"next state - news");
                [self gotoNewsFromLeft:NO];
            }
            else {
                DLog(@"next song");
                [self nextSong];
            }
        }
    }
    else {
        if (self.readingState == SMReadArticleAll) {
            if (self.newsSwipeView.currentItemIndex != self.newsSwipeView.numberOfItems) { // если еще есть новости - читаем дальше
                [self nextNews];
            }
            else { // нет новостей - слушаем музыку
                if ([GVMusicPlayerController sharedInstance].queue.count == 0) {
                    [self nextNews];
                }
                else {
                    [self gotoMusicFromLeft:NO];
                    [self nextSong];
                }
            }
        }
        else if (self.readingState == SMReadArticleOne) {
            if ([GVMusicPlayerController sharedInstance].queue.count == 0) {
                [self nextNews];
            }
            else {
                [self gotoMusicFromLeft:NO];
                [self nextSong];
            }
        }
        else { // X minutes
            if (lastChangedStateDate) {
                spentTimeForPlaying += [[NSDate date] timeIntervalSinceDate:lastChangedStateDate];
            }
            else {
                spentTimeForPlaying = 0;
            }
            NSTimeInterval threshold = [[SMSettings sharedSettings] timeForReadArticleValue:self.readingState];
            DLog(@"Threshold news: %lf/%ff (%@)", spentTimeForPlaying, threshold, lastChangedStateDate);
            
            lastChangedStateDate = [NSDate date];
            if (spentTimeForPlaying > threshold) {
                spentTimeForPlaying = 0;
                DLog(@"next state - music");
                
                if ([GVMusicPlayerController sharedInstance].queue.count == 0) {
                    [self nextNews];
                }
                else {
                    [self gotoMusicFromLeft:NO];
                    [self nextSong];
                }
            }
            else {
                DLog(@"next news");
                [self nextNews];
            }
        }
    }
}

- (void)nextSong
{
    [[GVMusicPlayerController sharedInstance] skipToNextItem];
    
    if (self.playingState != SMPlayingStateStop) { // read news -> continue playing music too
        [[GVMusicPlayerController sharedInstance] play];
    }
    
    previousInfopoint = nil;
    if (self.playingState == SMPlayingStatePlayingMusic) {
        [self beginRepeatButton];
    }
}

- (void)previousSong
{
    [[GVMusicPlayerController sharedInstance] skipToPreviousItem];
    
    if (self.playingState != SMPlayingStateStop) { // continue playing
        [[GVMusicPlayerController sharedInstance] play];
    }
    
    previousInfopoint = nil;
    if (self.playingState == SMPlayingStatePlayingMusic) {
        [self beginRepeatButton];
    }
}

- (void)gotoNewsFromLeft:(BOOL)isLeft
{
    if (self.newsSwipeView.currentItemIndex == 0 && isLeft) {
        [self previousSong];
    }
    else if (self.newsSwipeView.currentItemIndex == self.infopoints.count && !isLeft) {
        [self nextSong];
    }
    else {
        if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground) {
            if (isLeft) {
                [self previousNews];
            }
            else {
                [self nextNews];
            }
        }
        
        int offset = 0;
        if (isLeft) {
            offset = -1;
        }
        
        self.playerIndex = @(self.infopoints.count);
        
        [[GVMusicPlayerController sharedInstance] stop];
        if (self.playingState != SMPlayingStateStop) {
            [self startSpeaking];
        }
        [self updateView];
        [self.newsSwipeView scrollToItemAtIndex:self.newsSwipeView.currentItemIndex + offset duration:0];
        [self.newsSwipeView reloadData];
    }
    [self.newsSwipeView reloadData];
}

- (void)gotoMusicFromLeft:(BOOL)isLeft
{
    if (isLeft) {
        self.playerIndex = @(self.lastIndex.intValue - 1);
        
        if (self.playerIndex.intValue < 0) {
            self.playerIndex = @0;
        }
    }
    else {
        self.playerIndex = @(self.lastIndex.intValue + 1);
    }
    
    if (self.playingState != SMPlayingStateStop) {
        [[GVMusicPlayerController sharedInstance] play];
    }
    [self.newsSwipeView scrollToItemAtIndex:self.playerIndex.intValue duration:0];
    [self.newsSwipeView reloadData];
}

#pragma mark - SMInfopointsDownloaderDelegate

- (void)updateLeftSourceView
{
    NSString *leftSources = [self.infopointsDownloader leftSourcesString];
    BOOL isDownloading = leftSources.length > 0;
    if (isDownloading > 0) {
        self.leftSourcesLabel.text = leftSources;
        
        if ([self.downloadingIndicator.layer animationKeys].count == 0) {
            [self runSpinAnimationOnView:self.downloadingIndicator duration:4 rotations:1 repeat:10000];
        }
    }
    else {
        [self.downloadingIndicator.layer removeAllAnimations];
    }
    
    [UIView animateWithDuration:kScrollInterval animations:^{
        self.leftSourcesContainer.alpha = isDownloading > 0 ? 1 : 0;
    }];
}

- (void)runSpinAnimationOnView:(UIView*)view duration:(CGFloat)duration rotations:(CGFloat)rotations repeat:(float)repeat;
{
    CABasicAnimation* rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.toValue = [NSNumber numberWithFloat: M_PI * 2.0 /* full rotation*/ * rotations * duration ];
    rotationAnimation.duration = duration;
    rotationAnimation.cumulative = YES;
    rotationAnimation.repeatCount = repeat;
    
    [view.layer addAnimation:rotationAnimation forKey:@"rotationAnimation"];
}

- (void)infopointsDownloader:(SMInfopointsDownloader*)downloader didDownloadInfopoints:(NSArray*)infopoints
{
    DLog(@"News received: %lu", (unsigned long)infopoints.count);
    
    // nothing to display — show something instead of a blank screen or player
    if (self.infopoints.count == 0) {
        [self updateView];
    }
    [self updateLeftSourceView];
    
    NSInteger beforeCount = self.infopoints.count;
    
    [self appendInfopoints:infopoints];
    [self.newsSwipeView reloadData];
    //    [self.tableView reloadData];
    
    NSInteger nowCount = self.infopoints.count;
    NSMutableArray *indexPaths = [NSMutableArray array];
    for (NSInteger row = beforeCount; row < nowCount; row++) {
        [indexPaths addObject:[NSIndexPath indexPathForRow:row inSection:0]];
    }
    [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationFade];
    [self.infopointsDownloader processedInfopoints];
}

- (void)infopointsDownloader:(SMInfopointsDownloader*)downloader failedWithError:(NSError*)error;
{
    //    [[[UIAlertView alloc] initWithTitle:LOC(@"Error") message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
}

- (void)appendInfopoints:(NSArray*)items
{
    BOOL needsToScroll = NO;
    if (items.count > 0 && self.infopoints.count == 0 && [self isPlayerNow] && self.playingState != SMPlayingStatePlayingMusic) {
        needsToScroll = YES;
    }
    
    NSArray *reversed = items.reverseObjectEnumerator.allObjects;
    for (SMInfopoint *item in reversed) {
        [self addToInfopoints:item];
    }
    [[SMInfopointsStorage sharedInstance] saveData];
    
    if (![self isPlayerNow] && self.infopoints.count != self.playerIndex.intValue) {
        self.playerIndex = @(self.infopoints.count);
    }
    
    if (needsToScroll) {
        [self gotoRightFromPlayer:YES];
    }
}

- (void)addToInfopoints:(SMInfopoint*)infopoint
{
    if ([self.infopoints containsObject:infopoint]) {
        return;
    }
    
    NSInteger oldestPubDateInterval = [[SMSettings sharedSettings] selectedSaveHistoryValue] * SMOneDay;
    NSTimeInterval pubDateInterval = [[NSDate date] timeIntervalSinceDate:infopoint.pubDate];
    if (pubDateInterval > oldestPubDateInterval) { // old infopoint
        return;
    }
    
    int offset = [self isPlayerNow] ? -1 : 0; // if player - get previous infopoint
    NSInteger startIndex = self.newsSwipeView.currentItemIndex + 1 + offset;
    NSInteger newInfopointIndex = self.infopoints.count;
    
    
    if (self.infopoints.count > self.newsSwipeView.currentItemIndex + offset) {
        SMInfopoint *currentInfopoint = self.infopoints[self.newsSwipeView.currentItemIndex + offset];
        if ([currentInfopoint.pubDate compare:infopoint.pubDate] == NSOrderedDescending) {
            return;
        }
    }
    
    for (NSInteger i = startIndex; i < self.infopoints.count; i++) {
        SMInfopoint *currentInfopoint = self.infopoints[i];
        if (currentInfopoint.priority > infopoint.priority || (currentInfopoint.priority == infopoint.priority && [infopoint.pubDate compare:currentInfopoint.pubDate] == NSOrderedAscending)) {
            newInfopointIndex = i;
            break;
        }
    }
    
    [self.infopoints insertObject:infopoint atIndex:newInfopointIndex];
    [self downloadFullArticleForInfopoint:infopoint];
}

- (void)downloadFullArticleForInfopoint:(SMInfopoint*)infopoint
{
    [self.downloadFullArticleQueue addOperationWithBlock:^{
        [SMInfopointsFetcherUtilities downloadFullArticleForNews:infopoint success:^(NSString *article) {
            [[SMInfopointsStorage sharedInstance] saveData];
        } failure:nil];
    }];
}

#pragma mark - Catch remote control events, forward to the music player

- (void)remoteControlReceivedWithEvent:(id)sender
{
    UIEvent *receivedEvent;
    if ([sender isKindOfClass:[UIEvent class]]) {
        receivedEvent = sender;
    }
    else if ([sender isKindOfClass:[NSNotification class]]) {
        receivedEvent = ((NSNotification*)sender).object;
    }
    else {
        return;
    }
    
    if (receivedEvent.type == UIEventTypeRemoteControl) {
        if (receivedEvent.subtype == UIEventSubtypeRemoteControlPlay || receivedEvent.subtype == UIEventSubtypeRemoteControlPause || receivedEvent.subtype == UIEventSubtypeRemoteControlTogglePlayPause) {
            [self playButtonPressed:self.playPauseButton];
        }
        else if (receivedEvent.subtype == UIEventSubtypeRemoteControlNextTrack) {
            [self rightButtonPressed:self.rightButton];
        }
        else if (receivedEvent.subtype == UIEventSubtypeRemoteControlPreviousTrack) {
            [self leftButtonPressed:self.leftButton];
        }
    }
}

- (void)playbackTimeUpdated
{
    if ([self playingState] == SMPlayingStateReadingNews) {
        return;
    }

    self.playbackLabel.text = [NSString stringFromTime:[GVMusicPlayerController sharedInstance].currentPlaybackTime];
    
    if ([[GVMusicPlayerController sharedInstance] playbackState] == MPMusicPlaybackStatePlaying) {
        NSTimeInterval trackLength = [[[[GVMusicPlayerController sharedInstance] nowPlayingItem] valueForProperty:MPMediaItemPropertyPlaybackDuration] doubleValue];
        double progress = [GVMusicPlayerController sharedInstance].currentPlaybackTime / trackLength;
        self.progressView.progress = progress;
    }
}

#pragma mark - AVMusicPlayerController Delegate

- (void)musicPlayer:(GVMusicPlayerController *)musicPlayer playbackStateChanged:(MPMusicPlaybackState)playbackState previousPlaybackState:(MPMusicPlaybackState)previousPlaybackState {}

- (void)musicPlayer:(GVMusicPlayerController *)musicPlayer trackDidChange:(MPMediaItem *)nowPlayingItem previousTrack:(MPMediaItem *)previousTrack
{
    if (!nowPlayingItem) {
        return;
    }
    
    // Time labels
    NSTimeInterval trackLength = [[nowPlayingItem valueForProperty:MPMediaItemPropertyPlaybackDuration] doubleValue];
    self.durationLabel.text = [NSString stringFromTime:trackLength];
    self.progressView.progress = 0;
    
    // Labels
    self.songLabel.text = [nowPlayingItem valueForProperty:MPMediaItemPropertyTitle];
    self.artistLabel.text = [nowPlayingItem valueForProperty:MPMediaItemPropertyArtist];
    self.albumLabel.text = [nowPlayingItem valueForProperty:MPMediaItemPropertyAlbumTitle];
    
    // Artwork
    if ([self isPlayerNow]) {
        SMNewsPreviewView *currentView = (SMNewsPreviewView*)[self.newsSwipeView itemViewAtIndex:self.newsSwipeView.currentItemIndex]; // additional index in swipe view for player
        MPMediaItemArtwork *artwork = [nowPlayingItem valueForProperty:MPMediaItemPropertyArtwork];
        currentView.previewImageView.image = [artwork imageWithSize:currentView.previewImageView.frame.size];
        if (!currentView.previewImageView.image) {
            currentView.previewImageView.image = [UIImage imageNamed:@"placeholder"];
        }
    }
}

- (void)musicPlayer:(GVMusicPlayerController *)musicPlayer endOfQueueReached:(MPMediaItem *)lastTrack {}

- (void)musicPlayer:(GVMusicPlayerController *)musicPlayer endOfSongReached:(MPMediaItem *)lastTrack
{
    [self gotoRightFromPlayer:YES];
}

- (void)musicPlayerHasInterrupted:(GVMusicPlayerController *)musicPlayer
{
    self.playingState = SMPlayingStateStop;
}

#pragma mark - UITableViewDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.infopoints.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SMInfopointListTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier forIndexPath:indexPath];
    SMInfopoint *infopoint = self.infopoints[indexPath.row];
    [cell configureWithInfopoint:infopoint details:NO];
    return cell;
}

static BOOL scrolled = NO;
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!scrolled && [indexPath row] == ((NSIndexPath*)[[tableView indexPathsForVisibleRows] lastObject]).row) {
        NSLog(@"Scroll to: %@", self.lastIndex);
        [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(scrollToLastRow:) userInfo:[self.lastIndex copy] repeats:NO];
    }
    else {
        if (!scrolled) {
            return;
        }
        
        NSInteger index = 0;
        NSArray *paths = [tableView indexPathsForVisibleRows];
        if (paths.count > 2) {
            index = paths.count/2;
        }
        NSIndexPath *path = paths[index];
        if (path) {
            self.lastIndex = @(path.row);
            NSLog(@"Save index will: %@", self.lastIndex);
        }
    }
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath*)indexPath
{
    NSInteger index = 0;
    NSArray *paths = [tableView indexPathsForVisibleRows];
    if (paths.count > 2) {
        index = paths.count/2;
    }
    if (index > paths.count) {
        return;
    }
    
    NSIndexPath *path = paths[index];
    if (path) {
        continueFromReading = YES;
        self.lastIndex = @(path.row);
        NSLog(@"Save index did end: %@", self.lastIndex);
    }
}

- (void)scrollToLastRow:(NSTimer*)timer
{
    int index = [timer.userInfo intValue];
    if ([self isPlayerNow]) {
        index--;
    }
    if (index < 0) {
        index = 0;
    }
    
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    scrolled = YES;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    SMInfopointListDetailsViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"InfopointDetailsVC"];    SMInfopoint *infopoint = self.infopoints[indexPath.row];
    vc.infopoint = infopoint;
    [self.mm_drawerController.navigationController pushViewController:vc animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SMInfopoint *infopoint = self.infopoints[indexPath.row];
    NSString *text = [infopoint displayingTextForFullArticle:NO];
    NSDictionary *attributes = @{NSFontAttributeName : [UIFont fontWithName:@"HelveticaNeue-Light" size:15]};
    CGFloat cellContentMargins = 20;
    CGFloat contentWidth = self.view.bounds.size.width - cellContentMargins*2; // left and right
    CGRect rect = [text boundingRectWithSize:CGSizeMake(contentWidth, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:attributes context:nil];
    
    CGFloat imageHeight = contentWidth/2;
    if (!infopoint.enclosure) {
        imageHeight = 0;
    }
    CGFloat providerHeight = 40;
    
    return 6 + imageHeight + 9 + providerHeight + 12 + rect.size.height + 8      +20;
}

#pragma mark - SPEECH

- (void)speechSynthesizer:(SMSpeechSynthesizer *)sender didFinishSpeaking:(BOOL)finishedSpeaking
{
    if (finishedSpeaking) {
        [self setDefaultLeftButton];
        self.progressView.progress = 1;
        [self gotoRightFromPlayer:NO];
    }
    else {
        self.progressView.progress = 0;
    }
}

- (void)speechSynthesizer:(SMSpeechSynthesizer *)sender speakingProgress:(double)progress
{
    self.progressView.progress = progress;
}

@end
