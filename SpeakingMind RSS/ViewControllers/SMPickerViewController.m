//
//  SMPickerViewController.m
//  Speind
//
//  Created by Sergey Butenko on 2/25/15.
//  Copyright (c) 2015 Speaking Mind. All rights reserved.
//

#import "SMPickerViewController.h"
#import "SMSimplePickerTableViewCell.h"
#import "SMDetailPickerTableViewCell.h"

static NSString* const kCellIdentifier = @"PickerCell";
static const int kDefaultSection = 0;

@interface SMPickerViewController () <UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation SMPickerViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.title = self.titleString;
    [self.tableView registerNib:self.isDetail ? [SMDetailPickerTableViewCell nib] : [SMSimplePickerTableViewCell nib] forCellReuseIdentifier:kCellIdentifier];
    [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:self.selectedIndex inSection:kDefaultSection] animated:NO scrollPosition:UITableViewScrollPositionNone];
}

- (void)viewWillDisappear:(BOOL)animated
{
    NSInteger index = self.tableView.indexPathForSelectedRow.row;
    if (index != self.selectedIndex) {
        [self.delegate pickItemAtIndex:index forOption:self.option];
    }
    [super viewWillDisappear:animated];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SMSimplePickerTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier forIndexPath:indexPath];
    NSString *cellTitle = [self.dataSource[indexPath.row] description];
    [cell configureWithString:cellTitle];
    return cell;
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
