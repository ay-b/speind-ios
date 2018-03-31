//
//  SMUsersFeedsViewController.m
//  SpeakingMind RSS
//
//  Created by Sergey Butenko on 08.07.14.
//  Copyright (c) 2014 serejahh inc. All rights reserved.
//

#import "SMUsersFeedsViewController.h"
#import "SMAddFeedViewController.h"
#import "SMUsersFeedTableViewCell.h"
#import "SMTableViewCell.h"
#import "SMDatabase.h"
#import "SMFeedItem.h"

/**
 * Index of a "Cancel" button for deleting a custom feed.
 */
static const int kDeleteAlertButtonIndex = 1;

/**
 * Index of a "Edit" button in swipe cell.
 */
static const int kEditCellButtonIndex = 0;

/**
 * Index of a "Delete" button in swipe cell.
 */
static const int kDeleteCellButtonIndex = 1;

/**
 * Index of row for adding a new feed.
 */
static const int kAddFeedRow = 0;

/**
 * Size of an item in swipe cell.
 */
static const int kSwipeButtonSize = 53.0;

static NSString* const kCellIdentifier = @"UsersFeedCell";
static NSString* const kSimpleCellIdentifier = @"SimpleCell";

static NSString* const kAddingSegueIdentifier = @"toAddingFeed";

@interface SMUsersFeedsViewController () <SMUsersFeedTableViewCellDelegate, UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic) NSMutableArray *feeds;
@property (nonatomic) SMFeedItem *selectedFeed;
@property (nonatomic) NSIndexPath *deleteIndexPath;

@end

@implementation SMUsersFeedsViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.feeds = [NSMutableArray arrayWithArray:[SMDatabase usersFeeds]];
    [self.tableView reloadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.title = LOC(@"Title - My feeds");
    
    self.tableView.tableFooterView = [UIView new];
    [self.tableView registerNib:[SMUsersFeedTableViewCell nib] forCellReuseIdentifier:kCellIdentifier];
    [self.tableView registerNib:[SMTableViewCell nib] forCellReuseIdentifier:kSimpleCellIdentifier];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if (self.selectedFeed) {
        SMAddFeedViewController *vc = (SMAddFeedViewController *)segue.destinationViewController;
        vc.isEditing = YES;
        vc.feed = self.selectedFeed;
    }
}

- (NSArray*)rightButtons
{
    NSMutableArray *rightButtons = [NSMutableArray new];
    [rightButtons sw_addUtilityButtonWithColor:SMRedColor icon:[UIImage imageNamed:@"icon_feed_edit"]];
    [rightButtons sw_addUtilityButtonWithColor:SMRedColor icon:[UIImage imageNamed:@"icon_feed_delete"]];
    return [rightButtons copy];
}

#pragma mark - UITableView Delegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return @[@(kAddFeedRow)].count + self.feeds.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == kAddFeedRow) {
        SMTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kSimpleCellIdentifier forIndexPath:indexPath];
        cell.titleLabel.text = LOC(@"Add new feed");
        return cell;
    }
    
    SMUsersFeedTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier forIndexPath:indexPath];
    [cell setRightUtilityButtons:[self rightButtons] WithButtonWidth:kSwipeButtonSize];
    
    SMFeedItem *currentItem = self.feeds[indexPath.row-1];
    cell.titleLabel.text = currentItem.provider;
    cell.delegate = self;
    cell.selectFeedButton.selected = currentItem.isSelected;

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.row == kAddFeedRow) {
        self.selectedFeed = nil;
        [self performSegueWithIdentifier:kAddingSegueIdentifier sender:self];
    }
    else {
        SMUsersFeedTableViewCell *cell = (SMUsersFeedTableViewCell*)[tableView cellForRowAtIndexPath:indexPath];
        [cell selectFeedButtonPressed];
    }
}

- (UIView*)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    return [[UIView alloc] initWithFrame:CGRectZero];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.01f;
}

#pragma mark - Cell actions 

- (void)editCell:(SWTableViewCell*)cell
{
    NSInteger index = [[self.tableView indexPathForCell:cell] row];
    self.selectedFeed = self.feeds[index-1];
    [self performSegueWithIdentifier:kAddingSegueIdentifier sender:self];
}

- (void)deleteCell:(SWTableViewCell*)cell
{
    self.deleteIndexPath = [self.tableView indexPathForCell:cell];
    id feed = self.feeds[self.deleteIndexPath.row-1];
    
    NSString *title = [NSString stringWithFormat:@"%@ \"%@\"?", LOC(@"Confirm delete feed"), feed];
    UIAlertView *deleteFeedAlert = [[UIAlertView alloc] initWithTitle:title message:nil delegate:self cancelButtonTitle:LOC(@"Cancel") otherButtonTitles:LOC(@"OK"), nil];
    [deleteFeedAlert show];
}

#pragma mark - SMUsersFeedTableViewCell Delegate

- (void)select:(BOOL)selected cell:(SMUsersFeedTableViewCell*)cell
{
    NSInteger index = [[self.tableView indexPathForCell:cell] row];
    SMFeedItem *item = self.feeds[index-1];
    item.selected = selected;
    
    [SMDatabase updateUsersFeed:item];
}

- (BOOL)swipeableTableViewCellShouldHideUtilityButtonsOnSwipe:(SWTableViewCell *)cell
{
    return YES;
}

- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerRightUtilityButtonWithIndex:(NSInteger)index
{
    if (index == kEditCellButtonIndex) {
        [self editCell:cell];
    }
    else if (index == kDeleteCellButtonIndex) {
        [self deleteCell:cell];
    }
}

#pragma mark - UIAlertView Delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == kDeleteAlertButtonIndex) {
        NSUInteger index = self.deleteIndexPath.row-1;
        SMFeedItem *deletedFeed = self.feeds[index];
        [SMDatabase deleteUsersFeed:deletedFeed];
        
        [self.feeds removeObjectAtIndex:index];
        [self.tableView beginUpdates];
        [self.tableView deleteRowsAtIndexPaths:@[self.deleteIndexPath] withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView endUpdates];
    }
    else {
        self.deleteIndexPath = nil;
    }
}

@end
