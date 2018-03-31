//
//  SMSplashScreenViewController.m
//  Speind
//
//  Created by Sergey Butenko on 5/7/15.
//  Copyright (c) 2015 Speaking Mind. All rights reserved.
//

#import "SMSplashScreenViewController.h"
#import "SMListsDownloader.h"
#import "SMDatabase.h"

@interface SMSplashScreenViewController ()

/**
 * Segue to main viewcontroller.
 */
- (void)p_skitToMainVC;

/**
 * Copies and parses default CSV files.
 */
- (void)p_parseDefaultFeeds;

/**
 * Tries to choose default feed - prefered for system language.
 */
- (void)p_selectFirstFeed;

@end

@implementation SMSplashScreenViewController

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if ([[SMSettings sharedSettings] isAlreadyStarted]) {
        [self p_skitToMainVC];
    }
    else {
        [self p_parseDefaultFeeds];
    }
}

- (void)p_skitToMainVC
{
    [self performSegueWithIdentifier:@"toMain" sender:nil];
}

- (void)p_parseDefaultFeeds
{
    [SMDatabase createFeeds];
    [SMDatabase createUsersFeeds];
    [[SMSettings sharedSettings] setDefaults];
    
    SMListsDownloader *listsDownloader = [[SMListsDownloader alloc] init];
    NSArray *filePaths = @[@"RSS-FeedsList", @"rssfeeds-en-gb", @"rssfeeds-en-us", @"rssfeeds-es-cl", @"rssfeeds-es-es", @"rssfeeds-es-us", @"rssfeeds-fr-fr-ca", @"rssfeeds-it&tech&venture", @"rssfeeds-ru-ru"];
    for (NSString *path in filePaths) {
        NSString *bundlePath = [[NSBundle mainBundle] pathForResource:path ofType:@"csv"];
        NSString *destinationPath = [DOCUMENTS_DIRECTORY stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.csv", path]];
        NSError *error;
        [[NSFileManager defaultManager] copyItemAtPath:bundlePath toPath:destinationPath error:&error];
        
        if (error) {
            DLog(@"File Manager error: <%@> for file %@", error.localizedDescription, path);
        }
        else if (![path isEqualToString:@"RSS-FeedsList"]){
            [listsDownloader parseFeedsFromPath:destinationPath inMainQueue:YES];
        }
    }
    [self p_selectFirstFeed];
    [[SMSettings sharedSettings] setAlreadyStarted];
    
    [self p_skitToMainVC];
}

- (void)p_selectFirstFeed
{
    NSString *myLocale = [[NSLocale preferredLanguages] firstObject];
    NSArray *supportedLocales = [[SMSettings sharedSettings] supportedLocales];
    if ([supportedLocales containsObject:myLocale]) {
        [[SMSettings sharedSettings] selectFirstFeedForLang:myLocale];
    }
    else {
        [[NSNotificationCenter defaultCenter] postNotificationName:SMUnsupportedLocaleNotification object:nil];
    }
}

@end
