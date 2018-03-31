//
//  SMSettingsVoicesTableViewCell.m
//  SpeakingMind RSS
//
//  Created by Sergey Butenko on 09.07.14.
//  Copyright (c) 2014 serejahh inc. All rights reserved.
//

#import "SMSettingsVoicesTableViewCell.h"
#import "SMVoice.h"
#import "NSAttributedString+Speind.h"

@interface SMSettingsVoicesTableViewCell ()
{
    BOOL isPlaying;
}

@property (nonatomic, readwrite) SMVoice *voice;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *width;

@end

@implementation SMSettingsVoicesTableViewCell

- (IBAction)playButtonPressed:(id)sender
{
    if (isPlaying) {
        [self stop];
        [self.delegate stopDemoForCell:self];
    }
    else {
        [self play];
        [self.delegate playDemoForCell:self];
    }
}

- (void)configureCellWithVoice:(SMVoice*)voice delegate:(id<SMSettingsVoicesTableViewCellDelegate>)delegate
{
    self.delegate = delegate;
    self.titleLabel.text = voice.title;
    self.voice = voice;

    UIImage *icon;
    switch (self.voice.state) {
        case SMVoiceNew:
            icon = [UIImage imageNamed:@"icon_buy"];
            break;
        case SMVoiceDownloaded:
            icon = [UIImage imageNamed:@"voice_available"];
            break;
        case SMVoiceCurrent:
            icon = [UIImage imageNamed:@"voice_current"];
            break;
    }
    [self.statusButton setImage:icon forState:UIControlStateNormal];
}

- (void)play
{
    isPlaying = YES;
    _playButton.selected = isPlaying;
}

- (void)stop
{
    isPlaying = NO;
    _playButton.selected = isPlaying;
}

- (IBAction)statusButtonPressed:(id)sender
{
    switch (self.voice.state) {
        case SMVoiceNew:
             [self.delegate buyVoiceForCell:self];
            break;
        case SMVoiceDownloaded:
            [self.delegate setCurrentVoiceForCell:self];
            break;
        case SMVoiceCurrent:
            break;
    }
}

- (void)downloadingProgress:(double)progress
{
    self.statusButton.hidden = YES;
    self.downloadinProgressView.hidden = NO;
    self.downloadinProgressView.progress = progress;
    self.progressLabel.textColor = [UIColor blackColor];
    self.progressLabel.attributedText = [NSAttributedString sm_progressStringWithProgress:progress];

    UIFont *font = [self.progressLabel.attributedText attribute:NSFontAttributeName atIndex:self.progressLabel.attributedText.string.length-1 effectiveRange:nil];
    CGSize stringBoundingBox = [self.progressLabel.text sizeWithFont:font];
    _width.constant = stringBoundingBox.width;
    [self.titleLabel layoutIfNeeded];
}

- (void)inQueue
{
    self.statusButton.hidden = YES;
    self.downloadinProgressView.hidden = YES;
    self.progressLabel.textColor = SMDarkGrayColor;
    self.progressLabel.text = LOC(@"In queue");
    
    CGSize stringBoundingBox = [self.progressLabel.text sizeWithFont:self.progressLabel.font];
    _width.constant = stringBoundingBox.width;
    [self.titleLabel layoutIfNeeded];
}

- (void)availableToBuy
{
    self.statusButton.hidden = NO;
    self.downloadinProgressView.hidden = YES;
    self.progressLabel.text = @"";
    
    _width.constant = 0;
    [self.titleLabel layoutIfNeeded];
}

@end
