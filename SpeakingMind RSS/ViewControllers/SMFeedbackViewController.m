//
//  SMFeedbackViewController.m
//  SpeakingMind RSS
//
//  Created by Sergey Butenko on 02.06.14.
//  Copyright (c) 2014 serejahh inc. All rights reserved.
//

@import MessageUI;
#import "SMFeedbackViewController.h"
#import "TFTaifuno.h"

static NSString*const kEmailSubject = @"Feedback about Speind";

@interface SMFeedbackViewController () <MFMailComposeViewControllerDelegate>

@property (nonatomic) BOOL needsToPop;

- (IBAction)writeUsButtonPressed;
- (IBAction)openChatButtonPressed;

/**
 * Opens view with composing an email.
 */
- (void)p_sendEmail;

@end

@implementation SMFeedbackViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (self.needsToPop) {
        [self.navigationController popViewControllerAnimated:NO];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.title = NSLocalizedString(@"Title - Feedback", nil);
}

- (IBAction)writeUsButtonPressed
{
    self.needsToPop = YES;
    [self p_sendEmail];
}

- (IBAction)openChatButtonPressed
{
    self.needsToPop = YES;
    [[TFTaifuno sharedInstance] startChatOnViewController:self withInfo:[[SMSettings sharedSettings] taifunoUserInfo]];
}

- (void)mailComposeController:(MFMailComposeViewController*)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError*)error
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark -

- (void)p_sendEmail
{
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
        picker.mailComposeDelegate = self;
        [picker setSubject:kEmailSubject];
        [picker setToRecipients:@[SMFeedbackMail]];
        [self presentViewController:picker animated:YES completion:nil];
    }
    else {
        NSString *email = [NSString stringWithFormat:@"mailto:%@?subject=%@", SMFeedbackMail, kEmailSubject];
        email = [email stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:email]];
    }
}

@end
