//
//  SMSpeechSynthesizer.m
//  Speind
//
//  Created by Sergey Butenko on 4/8/15.
//  Copyright (c) 2015 Speaking Mind. All rights reserved.
//

#import "SMSpeechSynthesizer.h"
#import "SMInfopoint.h"
#import "SMLanguage.h"
#import "SMVoice.h"
#import "AcapelaLicense+Speind.h"
#import "NSString+Language.h"
#import <AVFoundation/AVFoundation.h>

#import "AcapelaSetup.h"

@interface SMSpeechSynthesizer () <AVSpeechSynthesizerDelegate>

@property (nonatomic, weak) SMInfopoint *previousInfopoint;
@property (nonatomic) NSInteger spokenLenght;
@property (nonatomic, getter=isPaused) BOOL pause;

#pragma mark - Speech

@property (nonatomic) AVSpeechSynthesizer *iosTTS;
@property (nonatomic) AcapelaSpeech *acapelaTTS;
@property (nonatomic) AcapelaLicense *acapelaLicense;
@property (nonatomic) AcapelaSetup *acapelaSetupData;

@end

@implementation SMSpeechSynthesizer

- (instancetype)initWithDelegate:(id<SMSpeechSynthesizerDelegate>)delegate
{
    self = [self init];
    if (self) {
        _delegate = delegate;
    }
    return self;
}

+ (instancetype)synthesizerWithDelegate:(id<SMSpeechSynthesizerDelegate>)delegate;
{
    return [[self alloc] initWithDelegate:delegate];
}

- (void)startSpeakingInfopoint:(SMInfopoint*)infopoint previousInfopoint:(SMInfopoint*)previousInfopoint fullArticle:(BOOL)fullArticle
{
    NSString *text = [[infopoint vocalizingTextWithPreviuosInfopoint:previousInfopoint fullArticle:fullArticle] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *lang = infopoint.lang;
    if (!lang) {
        lang = [text sm_langOfString];
    }

    double speechRateMultiplier = [[SMSettings sharedSettings] selectedSpeechRate];
    NSString *voice = [[SMSettings sharedSettings] selectedVoiceForLanguage:lang];
    BOOL isNativeTTS = [[SMSettings sharedSettings] isNativeTTSForLanguage:lang];
    
    BOOL shouldContinueReading = self.isPaused && [self.previousInfopoint isEqual:infopoint] && !fullArticle;
    if (shouldContinueReading) {
        [self p_continueSpeakingWithNativeTTS:isNativeTTS];
        return;
    }
    else {
        [self stopSpeaking];
        self.previousInfopoint = infopoint;
    }
        
    if (isNativeTTS) {
        AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:text];
        [utterance setRate:SMSpeechRate * speechRateMultiplier];
        utterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:voice];
        [self.iosTTS speakUtterance:utterance];
    }
    else {
        [self.acapelaTTS setVoice:voice];
        [self.acapelaTTS startSpeakingString:text];
        [self.acapelaTTS setRate:speechRateMultiplier];
    }
}

- (void)stopSpeaking
{
    [self.acapelaTTS stopSpeaking];
    [self.iosTTS pauseSpeakingAtBoundary:AVSpeechBoundaryImmediate];
    [self.iosTTS stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
    [self.delegate speechSynthesizer:self didFinishSpeaking:NO];
}

- (void)pauseSpeaking
{
    self.pause = YES;
    [self.acapelaTTS pauseSpeakingAtBoundary:AcapelaSpeechImmediateBoundary];
    [self.iosTTS pauseSpeakingAtBoundary:AVSpeechBoundaryImmediate];
}

- (void)infopointHasSkipped
{
    self.pause = NO;
}

- (void)p_continueSpeakingWithNativeTTS:(BOOL)isNativeTTS
{
    if (isNativeTTS) {
        [self.iosTTS continueSpeaking];
    }
    else {
        [self.acapelaTTS continueSpeaking];
    }
    self.pause = NO;
}

#pragma mark - Delegates
#pragma mark Acapela

- (void)speechSynthesizer:(AcapelaSpeech *)sender didFinishSpeaking:(BOOL)finishedSpeaking
{
    [self.delegate speechSynthesizer:self didFinishSpeaking:finishedSpeaking];
}

- (void)speechSynthesizer:(AcapelaSpeech *)sender willSpeakWord:(NSRange)characterRange ofString:(NSString *)string
{
    double progress = (double)characterRange.location / string.length;
    [self.delegate speechSynthesizer:self speakingProgress:progress];
}

#pragma mark AVFoundation

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didFinishSpeechUtterance:(AVSpeechUtterance *)utterance
{
    if (utterance.speechString.length > self.spokenLenght) {
        [self.delegate speechSynthesizer:self didFinishSpeaking:NO];
    }
    else {
        [self.delegate speechSynthesizer:self didFinishSpeaking:YES];
    }
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didCancelSpeechUtterance:(AVSpeechUtterance *)utterance
{
    [self.delegate speechSynthesizer:self didFinishSpeaking:NO];
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer willSpeakRangeOfSpeechString:(NSRange)characterRange utterance:(AVSpeechUtterance *)utterance
{
    double progress = (double)characterRange.location / utterance.speechString.length;
    self.spokenLenght = characterRange.location + characterRange.length;
    [self.delegate speechSynthesizer:self speakingProgress:progress];
}

#pragma mark - Lazy

- (AcapelaSpeech *)acapelaTTS
{
    if (!_acapelaTTS) {
        self.acapelaLicense = [AcapelaLicense speindLicense];
        self.acapelaSetupData = [[AcapelaSetup alloc] initialize];
        if (!self.acapelaSetupData.CurrentVoice) {
            return nil;
        }
        
        _acapelaTTS = [[AcapelaSpeech alloc] initWithVoice:self.acapelaSetupData.CurrentVoice license:self.acapelaLicense];
        [_acapelaTTS setDelegate:self];
    }
    return _acapelaTTS;
}

- (AVSpeechSynthesizer *)iosTTS
{
    if (!_iosTTS) {
        _iosTTS = [[AVSpeechSynthesizer alloc] init];
        _iosTTS.delegate = self;
    }
    return _iosTTS;
}

@end
