
//
//  SMChooseVoiceViewController.m
//  SpeakingMind RSS
//
//  Created by Sergey Butenko on 11/4/14.
//  Copyright (c) 2014 Speaking Mind. All rights reserved.
//

#import "SMChooseVoiceViewController.h"
#import "SMChooseVoiceTableViewCell.h"
#import "SMVoiceManager.h"
#import "SMVoice.h"
#import "SMDownloadingVoiceViewController.h"

#import <AFNetworking/AFNetworkReachabilityManager.h>

static NSString *const kCellIdentifier = @"ChooseVoiceCell";
static NSString *const kDownloadingSegueIdentifier = @"toDownloadingVoice";
static const NSTimeInterval kAppearanceDuration = 0.3;

@interface SMChooseVoiceViewController () <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *confirmButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomOffsetConstraint;
- (IBAction)confirmButtonPressed:(id)sender;

@property (nonatomic) NSArray *freeVoices;

@end

@implementation SMChooseVoiceViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.tableView registerNib:[SMChooseVoiceTableViewCell nib] forCellReuseIdentifier:kCellIdentifier];
    self.tableView.tableFooterView = [UIView new];
    
    self.freeVoices = [[SMVoiceManager sharedManager] freeVoices];
    SMVoice *choosenVoice = [self autoChoosenVoice];
    if (choosenVoice) {
        [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:[self.freeVoices indexOfObject:choosenVoice] inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
    }
    [self p_updateView];
}

- (SMVoice*)autoChoosenVoice
{
    NSString *lang = [[NSLocale currentLocale] localeIdentifier];
    for (SMVoice *voice in self.freeVoices) {
        if ([voice.locale isEqualToString:lang]) {
            return voice;
        }
    }
    return nil;
}

- (void)p_updateView
{
    NSArray *selectedCells = [self.tableView indexPathsForSelectedRows];
    BOOL enabled = selectedCells.count > 0;
    self.confirmButton.enabled = enabled;
    
    [UIView animateWithDuration:kAppearanceDuration animations:^{
        self.confirmButton.alpha = enabled ? 1 : 0;
    }];
}

- (IBAction)confirmButtonPressed:(id)sender
{
    [[SMSettings sharedSettings] firstVoiceChoosen];
    
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    SMVoice *voice = self.freeVoices[indexPath.row];
    [[SMSettings sharedSettings] selectFirstFeedForLang:voice.locale];
    
    [self performSegueWithIdentifier:@"toMain" sender:nil];
}

#pragma mark - UITableView delegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.freeVoices.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SMChooseVoiceTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier forIndexPath:indexPath];
    [cell configureWithVoice:self.freeVoices[indexPath.row]];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self p_updateView];
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [_tableView cellForRowAtIndexPath:indexPath];
    if(cell.selected) {
        [_tableView deselectRowAtIndexPath:indexPath animated:YES];
        [self p_updateView];
        return nil;
    }
    return indexPath;
}

- (UIView*)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    return [[UIView alloc] initWithFrame:CGRectZero];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.01f;
}

@end
