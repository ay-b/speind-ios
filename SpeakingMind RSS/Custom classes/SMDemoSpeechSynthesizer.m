//
//  SMDemoSpeechSynthesizer.m
//  Speind
//
//  Created by Sergey Butenko on 7/2/15.
//  Copyright (c) 2015 Speaking Mind. All rights reserved.
//

#import "SMDemoSpeechSynthesizer.h"
#import "SMVoice.h"
#import <AVFoundation/AVFoundation.h>
#import <STKAudioPlayer.h>

@interface SMDemoSpeechSynthesizer () <AVSpeechSynthesizerDelegate, STKAudioPlayerDelegate>

@property (nonatomic) STKAudioPlayer* voicePlayer;
@property (nonatomic) AVSpeechSynthesizer *iosTTS;
@property (nonatomic) NSInteger spokenLenght;

@end

@implementation SMDemoSpeechSynthesizer

- (instancetype)initWithDelegate:(id<SMDemoSpeechSynthesizerDelegate>)delegate
{
    self = [self init];
    if (self) {
        _delegate = delegate;
    }
    return self;
}

+ (instancetype)demoSynthesizerWithDelegate:(id<SMDemoSpeechSynthesizerDelegate>)delegate
{
    return [[self alloc] initWithDelegate:delegate];
}

- (void)startSpeakingDemoForVoice:(SMVoice*)voice
{
    [self stopSpeakingDemo];
    
    NSString *text = voice.demoText;
    NSString *voiceLang = voice.locale;
    
    if (voice.isNativeVoice) {
        AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:text];
        [utterance setRate:SMSpeechRate];
        utterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:voiceLang];
        [self.iosTTS speakUtterance:utterance];
    }
    else {
        [self.voicePlayer play:voice.demo];
    }
}

- (void)stopSpeakingDemo
{
    [self.iosTTS stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
}

#pragma mark - AVFoundation

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didFinishSpeechUtterance:(AVSpeechUtterance *)utterance
{
    if (utterance.speechString.length == self.spokenLenght) {
        [self.delegate demoSpeechSynthesizerdidFinishSpeaking:self];
    }
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer willSpeakRangeOfSpeechString:(NSRange)characterRange utterance:(AVSpeechUtterance *)utterance
{
    self.spokenLenght = characterRange.location + characterRange.length;
}

- (AVSpeechSynthesizer *)iosTTS
{
    if (!_iosTTS) {
        _iosTTS = [[AVSpeechSynthesizer alloc] init];
        _iosTTS.delegate = self;
    }
    return _iosTTS;
}

#pragma mark - STKAudioPlayer Delegate

- (STKAudioPlayer *)voicePlayer
{
    if (!_voicePlayer) {
        _voicePlayer = [[STKAudioPlayer alloc] init];
        _voicePlayer.delegate = self;
    }
    return _voicePlayer;
}

- (void)audioPlayer:(STKAudioPlayer*)audioPlayer didFinishPlayingQueueItemId:(NSObject*)queueItemId withReason:(STKAudioPlayerStopReason)stopReason andProgress:(double)progress andDuration:(double)duration
{
    if (stopReason == STKAudioPlayerStopReasonEof) {
        [self.delegate demoSpeechSynthesizerdidFinishSpeaking:self];
    }
}

- (void)audioPlayer:(STKAudioPlayer*)audioPlayer didStartPlayingQueueItemId:(NSObject*)queueItemId {}
- (void)audioPlayer:(STKAudioPlayer*)audioPlayer didFinishBufferingSourceWithQueueItemId:(NSObject*)queueItemId {}
- (void)audioPlayer:(STKAudioPlayer*)audioPlayer stateChanged:(STKAudioPlayerState)state previousState:(STKAudioPlayerState)previousState {}
- (void)audioPlayer:(STKAudioPlayer*)audioPlayer unexpectedError:(STKAudioPlayerErrorCode)errorCode {}

@end
