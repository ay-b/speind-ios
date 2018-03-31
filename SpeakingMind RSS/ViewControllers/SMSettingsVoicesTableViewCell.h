//
//  SMSettingsVoicesTableViewCell.h
//  SpeakingMind RSS
//
//  Created by Sergey Butenko on 09.07.14.
//  Copyright (c) 2014 serejahh inc. All rights reserved.
//

#import "SMTableViewCell.h"

@class SMSettingsVoicesTableViewCell, SMVoice;

@protocol SMSettingsVoicesTableViewCellDelegate <NSObject>

- (void)playDemoForCell:(SMSettingsVoicesTableViewCell*)cell;
- (void)stopDemoForCell:(SMSettingsVoicesTableViewCell*)cell;
- (void)buyVoiceForCell:(SMSettingsVoicesTableViewCell*)cell;
- (void)setCurrentVoiceForCell:(SMSettingsVoicesTableViewCell*)cell;

@end

@interface SMSettingsVoicesTableViewCell : SMTableViewCell

@property id<SMSettingsVoicesTableViewCellDelegate> delegate;
@property (nonatomic, readonly) SMVoice *voice;

@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UIButton *statusButton;
@property (weak, nonatomic) IBOutlet UIProgressView *downloadinProgressView;
@property (weak, nonatomic) IBOutlet UILabel *progressLabel;

- (IBAction)playButtonPressed:(id)sender;
- (IBAction)statusButtonPressed:(id)sender;
- (void)play;
- (void)stop;

- (void)configureCellWithVoice:(SMVoice*)voice delegate:(id<SMSettingsVoicesTableViewCellDelegate>)delegate;
- (void)downloadingProgress:(double)progress;
- (void)inQueue;
- (void)availableToBuy;

@end
