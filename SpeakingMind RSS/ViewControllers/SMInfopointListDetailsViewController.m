//
//  SMInfopointListDetailsViewController.m
//  Speind
//
//  Created by Sergey Butenko on 4/7/15.
//  Copyright (c) 2015 Speaking Mind. All rights reserved.
//

#import "SMInfopointListDetailsViewController.h"
#import "SMInfopointListTableViewCell.h"

static NSString*const kCellIdentifier = @"ListCell";

static const NSInteger kEstimatedHeight = 400;
static const NSInteger kBorderWidth = 6;

@interface SMInfopointListDetailsViewController () <UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation SMInfopointListDetailsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.title = LOC(@"Title - Details");
    
    [self.tableView registerNib:[SMInfopointListTableViewCell nib] forCellReuseIdentifier:kCellIdentifier];
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = kEstimatedHeight;
    
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, kBorderWidth)];
    footerView.backgroundColor = SMGrayColor;
    self.tableView.tableFooterView = footerView;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SMInfopointListTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier forIndexPath:indexPath];
    [cell configureWithInfopoint:self.infopoint details:YES];
    return cell;
}

@end
