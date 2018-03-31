//
//  SMChooseChannelsViewController.m
//  Speind
//
//  Created by Sergey Butenko on 11/5/14.
//  Copyright (c) 2014 Speaking Mind. All rights reserved.
//

#import "SMChooseChannelsViewController.h"
#import "SMChooseChannelsTableViewCell.h"

static NSString *const kCellIdentifier = @"ChooseChannelCell";
static const NSTimeInterval kAppearanceDuration = 0.3;

@interface SMChooseChannelsViewController () <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *confirmButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomOffsetConstraint;
- (IBAction)confirmButtonPressed:(id)sender;

@property NSArray *channels;

@end

@implementation SMChooseChannelsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.tableView registerNib:[SMChooseChannelsTableViewCell nib] forCellReuseIdentifier:kCellIdentifier];
    self.tableView.tableFooterView = [UIView new];
    self.channels = @[@"Политика", @"Спорт", @"Культура", @"Технологии", @"Дизайн"];
    [self p_updateView];
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
    [self performSegueWithIdentifier:@"toMain" sender:sender];
}

#pragma mark - UITableView delegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.channels.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SMChooseChannelsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier forIndexPath:indexPath];
    cell.titleLabel.text = self.channels[indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self p_updateView];
}
- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self p_updateView];
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
