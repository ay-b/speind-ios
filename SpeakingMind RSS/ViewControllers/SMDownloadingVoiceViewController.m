//
//  SMDownloadingVoiceViewController.m
//  SpeakingMind RSS
//
//  Created by Sergey Butenko on 11/4/14.
//  Copyright (c) 2014 Speaking Mind. All rights reserved.
//

#import "SMDownloadingVoiceViewController.h"
#import "SMVoiceDownloader.h"
#import "SMVoice.h"
#import "SMDefines.h"
#import "SMVoiceManager.h"

#import "SMSettings.h"

static const NSTimeInterval kProgressTimeInterval = 1.0/3.0;

@interface SMDownloadingVoiceViewController () <SMVoiceDownloaderDelegate>

@property (weak, nonatomic) IBOutlet UIProgressView *downloadingProgressView;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;

@property (strong, nonatomic) SMVoiceDownloader *voiceDownloader;

@property (weak) NSTimer *extractingTimer;
- (void)p_updateExtractingLabel;

@end

@implementation SMDownloadingVoiceViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
  
    self.voiceDownloader = [SMVoiceDownloader downloaderWithDelegate:self];
    [self.voiceDownloader downloadVoice:self.downloadingVoice];
}

- (void)p_updateExtractingLabel
{
    static int dots = 1;
    NSMutableString *label = [NSMutableString stringWithString:LOC(@"Extracting")];
    for (int i = 1; i <= dots%3+1; i++) {
        [label appendString:@"."];
    }
    self.statusLabel.text = label;
    dots++;
}

- (void)p_setProgress:(double)progress
{
    if (progress < 0) progress = 0;
    if (progress > 1) progress = 1;

    UIFont *boldFont = [UIFont fontWithName:@"HelveticaNeue-Bold" size:15.0];
    NSDictionary *progressAttributes = [NSDictionary dictionaryWithObject:boldFont forKey:NSFontAttributeName];
    NSString *progressString = [NSString stringWithFormat:@" %.1lf%%", progress * 100];
    NSAttributedString *progressAttributedString = [[NSAttributedString alloc] initWithString:progressString attributes:progressAttributes];
    
    NSMutableAttributedString *status = [[NSMutableAttributedString alloc] initWithString:LOC(@"Downloading")];
    [status appendAttributedString:progressAttributedString];
    self.statusLabel.attributedText = status;
}

#pragma mark - SMVoiceDownloader

- (void)voiceDownloaderWillDownload:(SMVoiceDownloader*)downloader
{
    [self p_setProgress:0];
}

- (void)voiceDownloaderDownload:(SMVoiceDownloader*)downloader progress:(double)progress
{
    [self p_setProgress:progress];
    self.downloadingProgressView.progress = progress;
}

- (void)voiceDownloaderDidDownload:(SMVoiceDownloader*)downloader {}

- (void)voiceDownloaderFailedDownloading:(SMVoiceDownloader*)downloader error:(NSError*)error
{
    if (error && ![[SMSettings sharedSettings] isFirstVoiceDownloaded]) {
        NSString *msg = error.localizedDescription;
        if ([error.domain isEqualToString:SMVoiceDownloaderErrorDomain] && error.code == SMVoiceDownloaderNotReachable) {
            msg = LOC(@"Internet lost");
        }
        else if ([error.domain isEqualToString:SMVoiceDownloaderErrorDomain] && error.code == SMVoiceDownloaderSlowConnection) {
            msg = LOC(@"Slow internet");
        }
        [[[UIAlertView alloc] initWithTitle:LOC(@"Error") message:msg delegate:nil cancelButtonTitle:nil otherButtonTitles:LOC(@"OK"), nil] show];
    }
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)voiceDownloaderWillUnzipArchive:(SMVoiceDownloader*)downloader
{
    [self p_setProgress:1];
    self.extractingTimer = [NSTimer scheduledTimerWithTimeInterval:kProgressTimeInterval target:self selector:@selector(p_updateExtractingLabel) userInfo:nil repeats:YES];
}

- (void)voiceDownloaderUnzipArchive:(SMVoiceDownloader*)downloader progress:(double)progress {}

- (void)voiceDownloaderDidUnzipArchive:(SMVoiceDownloader*)downloader
{
    [[SMSettings sharedSettings] selectFirstFeedForLang:self.downloadingVoice.locale];
    
    [self.extractingTimer invalidate];
    self.extractingTimer = nil;
    [[SMSettings sharedSettings] firstVoiceDownloaded];
    [[SMSettings sharedSettings] setSelectedVoice:self.downloadingVoice];
    
    [self performSegueWithIdentifier:@"toMain" sender:self];
}

@end
