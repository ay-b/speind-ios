//
//  SMDemoSpeechSynthesizer.h
//  Speind
//
//  Created by Sergey Butenko on 7/2/15.
//  Copyright (c) 2015 Speaking Mind. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SMDemoSpeechSynthesizer;

@protocol SMDemoSpeechSynthesizerDelegate <NSObject>

- (void)demoSpeechSynthesizerdidFinishSpeaking:(SMDemoSpeechSynthesizer*)sender;

@end

@interface SMDemoSpeechSynthesizer : NSObject

@property (nonatomic, weak) id<SMDemoSpeechSynthesizerDelegate> delegate;

- (instancetype)initWithDelegate:(id<SMDemoSpeechSynthesizerDelegate>)delegate;
+ (instancetype)demoSynthesizerWithDelegate:(id<SMDemoSpeechSynthesizerDelegate>)delegate;

- (void)startSpeakingDemoForVoice:(SMVoice*)voice;
- (void)stopSpeakingDemo;

@end
