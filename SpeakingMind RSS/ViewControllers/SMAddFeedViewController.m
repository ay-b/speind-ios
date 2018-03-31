//
//  SMAddFeedViewController.m
//  SpeakingMind RSS
//
//  Created by Sergey Butenko on 08.07.14.
//  Copyright (c) 2014 serejahh inc. All rights reserved.
//

#import "SMAddFeedViewController.h"
#import "SMDatabase.h"
#import "SMDefines.h"
#import "SMFeedItem.h"
#import "SMTableViewCell.h"
#import "SMTextFieldTableViewCell.h"
#import "SMInfopointsFetcherUtilities.h"
#import "SMPickerViewController.h"
#import "SMLanguage.h"

#import <AFNetworkReachabilityManager.h>

/**
 * Index of a "Cancel" button for deleting a custom feed.
 */
static const int kDeleteAlertButtonIndex = 1;

static const int kEmptyUid = -1;

static const int kMainSection         = 0;
static const int kVideoInstructionRow = 0;
static const int kNameRow             = 1;
static const int kURLRow              = 2;
static const int kLanguageRow         = 3;
static const int kDeleteFeedRow       = 4;

static const int kAddingCountRows     = 4;
static const int kEditingCountRows    = 5;

@interface SMAddFeedViewController () <UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource, SMPickerViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *confirmButton;
- (IBAction)confirmButtonPressed:(id)sender;

@property (nonatomic) NSArray *languages;
@property (nonatomic) SMLanguage *selectedLanguage;
@property (nonatomic, getter=isCorrectFeed) BOOL correctFeed;

@end

@implementation SMAddFeedViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.languages = [[SMSettings sharedSettings] supportedLanguages];
    
    [self.tableView registerNib:[SMTableViewCell nib] forCellReuseIdentifier:@"SimpleCell"];
    [self.tableView registerNib:[SMTextFieldTableViewCell nib] forCellReuseIdentifier:@"TextFieldCell"];
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = SMTableViewCellHeight;
    
    if (self.isEditing == YES) {
        self.navigationItem.title = LOC(@"Title - Edit user feed");
        self.correctFeed = YES;
        [self showConfirmButton:YES];
        self.selectedLanguage = [SMLanguage langWithLocaleIdentifier:self.feed.lang];
    }
    else {
        self.navigationItem.title = LOC(@"Title - Add user feed");
        self.selectedLanguage = [self.languages firstObject];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"toPicker"]) {
        SMPickerViewController *vc = segue.destinationViewController;
        vc.dataSource = self.languages;
        vc.selectedIndex = [self.languages indexOfObject:self.selectedLanguage];
        vc.delegate = self;
        vc.option = kLanguageRow;
        vc.titleString = LOC(@"Language");
    }
}

#pragma mark - Checking

- (void)checkFeed
{
    if ([self nameTextField].text.length == 0) {
        [self showMessage:LOC(@"No name of the feed") isCorrect:NO];
        self.correctFeed = NO;
        return;
    }

    SMAddFeedState state = [self checkFeedURL:[self urlTextField].text];
    NSString *stateString = LOC(@"Checking...");
    if (state == SMAddFeedStateCorrect) {
        [SMInfopointsFetcherUtilities checkFeed:[self urlTextField].text resultHandler:^(BOOL isCorrect) {
//            if (self.isCorrectFeed && isCorrect) {
                self.correctFeed = isCorrect;
                [self showMessage:isCorrect ? LOC(@"OK") : LOC(@"Bad link") isCorrect:isCorrect];
                [self showConfirmButton:self.isCorrectFeed];
//            }
        }];
    }
    else if (state == SMAddFeedStateNotReachable){
        stateString = LOC(@"No internet connection");
    }
    else if (state == SMAddFeedStateIncorrectURL){
        stateString = LOC(@"Bad link");
    }
    else if (state == SMAddFeedStateNoData) {
        stateString = LOC(@"Bad link");
    }
    
    [self showMessage:stateString isCorrect:NO];
}

- (SMAddFeedState)checkFeedURL:(NSString*)candidate
{
    NSString *urlRegEx = @"(http|https)://((\\w)*|([0-9]*)|([-|_])*)+([\\.|/]((\\w)*|([0-9]*)|([-|_])*))+";
    NSPredicate *urlTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", urlRegEx];
    if (![urlTest evaluateWithObject:[candidate lowercaseString]]) {
        return SMAddFeedStateIncorrectURL;
    }
    
    if (![[AFNetworkReachabilityManager sharedManager] isReachable]) {
        return SMAddFeedStateNotReachable;
    }
    
    return SMAddFeedStateCorrect;
}

- (void)saveFeed
{
    NSString *provider = [self nameTextField].text;
    NSString *url = [self urlTextField].text;
    NSString *lang = [self.selectedLanguage.locale copy];
    
    if (self.isEditing) {
        SMFeedItem *updatedFeed = [SMFeedItem userFeedWithUid:self.feed.uid provider:provider url:url lang:lang];
        updatedFeed.selected = self.feed.isSelected;
        [SMDatabase updateUsersFeed:updatedFeed];
    }
    else {
        SMFeedItem *newFeed = [SMFeedItem userFeedWithUid:kEmptyUid provider:provider url:url lang:lang];
        newFeed.selected = YES;
        [SMDatabase insertUsersFeed:newFeed];
    }
}

- (void)deleteFeed
{
    NSString *title = [NSString stringWithFormat:@"%@ \"%@\"?", LOC(@"Confirm delete feed"), self.feed];
    UIAlertView *deleteFeedAlert = [[UIAlertView alloc] initWithTitle:title message:nil delegate:self cancelButtonTitle:LOC(@"Cancel") otherButtonTitles:LOC(@"OK"), nil];
    [deleteFeedAlert show];
}

#pragma mark - Helpers

- (IBAction)confirmButtonPressed:(id)sender
{
    if (self.isCorrectFeed) {
        [self saveFeed];
        [self.navigationController popViewControllerAnimated:YES];
    }
    else {
        [self.view endEditing:YES];
        [self checkFeed];
    }
}

- (void)showConfirmButton:(BOOL)show
{
    if (show) {
        [self showMessage:LOC(@"OK") isCorrect:YES];
    }
    else {
        [self showMessage:LOC(@"Check feed") isCorrect:NO];
    }
}

- (UITextField*)nameTextField {
    SMTextFieldTableViewCell *nameCell = (SMTextFieldTableViewCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:kNameRow inSection:kMainSection]];
    return nameCell.textField;
}

- (UITextField*)urlTextField {
    
    SMTextFieldTableViewCell *urlCell = (SMTextFieldTableViewCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:kURLRow inSection:kMainSection]];
    return urlCell.textField;
}

- (void)showMessage:(NSString*)msg isCorrect:(BOOL)correct
{
    [self.confirmButton setBackgroundColor: correct ? SMBlueColor : SMRedColor];
    if (correct) {
        [self.confirmButton setTitle:@"" forState:UIControlStateNormal];
        [self.confirmButton setImage:[UIImage imageNamed:@"icon_check"] forState:UIControlStateNormal];
    }
    else {
        [self.confirmButton setTitle:msg forState:UIControlStateNormal];
        [self.confirmButton setImage:nil forState:UIControlStateNormal];
    }
}

#pragma mark - UITextField Delegate

- (BOOL)textFieldShouldReturn:(UITextField*)textField
{
    NSInteger nextTag = textField.tag + 1;
    UIResponder* nextResponder = [self.view.superview viewWithTag:nextTag];
    
    if (nextResponder) {
        [nextResponder becomeFirstResponder];
    }
    else {
        [textField resignFirstResponder];
    }
    
    return NO;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string;
{
    if ([textField isEqual:self.urlTextField]) {
        self.correctFeed = NO;
        [self showConfirmButton:NO];
    }
    return YES;
}

#pragma mark - UITableViewDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.isEditing ? kEditingCountRows : kAddingCountRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row > kVideoInstructionRow && indexPath.row < kLanguageRow) {
        SMTextFieldTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TextFieldCell" forIndexPath:indexPath];
        cell.textField.delegate = self;
        cell.textField.tag = indexPath.row;
        
        NSString *title = @"";
        if (indexPath.row == kNameRow) {
            title = LOC(@"Name");
            cell.textField.text = self.feed.provider;
            cell.textField.returnKeyType = UIReturnKeyNext;
        }
        else if (indexPath.row == kURLRow) {
            title = LOC(@"URL");
            cell.textField.text = self.feed.url;
            cell.textField.returnKeyType = UIReturnKeyDone;
            cell.textField.keyboardType = UIKeyboardTypeURL;
        }
        cell.titleLabel.text = title;
        cell.textField.placeholder = [NSString stringWithFormat:LOC(@"Enter %@"), [title lowercaseString]];
        return cell;
    }

    SMTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SimpleCell" forIndexPath:indexPath];
    
    if (indexPath.row == kVideoInstructionRow) {
        cell.titleLabel.text = LOC(@"Video instruction");
        cell.style = SMTableViewCellStyleVideo;
    }
    else if (indexPath.row == kLanguageRow) {
        cell.titleLabel.text = [self.selectedLanguage description];
    }
    else if (indexPath.row == kDeleteFeedRow) {;
        cell.titleLabel.text = LOC(@"Delete feed");
        cell.style = SMTableViewCellStyleCancel;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.row == kVideoInstructionRow) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:SMURLVideoInstruction]];
    }
    else if (indexPath.row < kLanguageRow) {
        SMTextFieldTableViewCell *cell = (SMTextFieldTableViewCell*)[tableView cellForRowAtIndexPath:indexPath];
        [cell.textField becomeFirstResponder];
    }
    else if (indexPath.row == kLanguageRow) {
        [self.view endEditing:YES];
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        [self performSegueWithIdentifier:@"toPicker" sender:cell];
    }
    else if (indexPath.row == kDeleteFeedRow) {
        [self deleteFeed];
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

#pragma mark - SMPickerViewControllerDelegate <NSObject>

- (void)pickItemAtIndex:(NSInteger)index forOption:(NSInteger)option
{
    self.selectedLanguage = self.languages[index];
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:option inSection:kMainSection]] withRowAnimation:UITableViewRowAnimationFade];
}

#pragma mark - UIAlertView Delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == kDeleteAlertButtonIndex) {
        [SMDatabase deleteUsersFeed:self.feed];
        [self.navigationController popViewControllerAnimated:YES];
    }
}

@end
