//
//  SMSpeechSynthesizer.h
//  Speind
//
//  Created by Sergey Butenko on 4/8/15.
//  Copyright (c) 2015 Speaking Mind. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SMSpeechSynthesizer, SMInfopoint;

@protocol SMSpeechSynthesizerDelegate <NSObject>

- (void)speechSynthesizer:(SMSpeechSynthesizer*)sender didFinishSpeaking:(BOOL)finishedSpeaking;
- (void)speechSynthesizer:(SMSpeechSynthesizer*)sender speakingProgress:(double)progress;

@end

@interface SMSpeechSynthesizer : NSObject

@property (nonatomic, weak) id<SMSpeechSynthesizerDelegate> delegate;

- (instancetype)initWithDelegate:(id<SMSpeechSynthesizerDelegate>)delegate;
+ (instancetype)synthesizerWithDelegate:(id<SMSpeechSynthesizerDelegate>)delegate;

- (void)startSpeakingInfopoint:(SMInfopoint*)infopoint previousInfopoint:(SMInfopoint*)previousInfopoint fullArticle:(BOOL)fullArticle;
- (void)stopSpeaking;
- (void)pauseSpeaking;
- (void)infopointHasSkipped;

@end
