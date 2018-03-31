//
//  SMChooseVoiceTableViewCell.h
//  SpeakingMind RSS
//
//  Created by Sergey Butenko on 11/4/14.
//  Copyright (c) 2014 Speaking Mind. All rights reserved.
//

#import "SMTableViewCell.h"

@class SMVoice;

@interface SMChooseVoiceTableViewCell : SMTableViewCell

- (void)configureWithVoice:(SMVoice*)voice;

@end
