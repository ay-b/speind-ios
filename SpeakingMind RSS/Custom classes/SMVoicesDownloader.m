//
//  SMVoicesDownloader.m
//  Speind
//
//  Created by Sergey Butenko on 3/5/15.
//  Copyright (c) 2015 Speaking Mind. All rights reserved.
//

#import "SMVoicesDownloader.h"
#import "SMVoice.h"
#import "SMVoiceManager.h"
#import "SMSettings.h"
#import "AcapelaSpeech+Speind.h"

#import <SSZipArchive/SSZipArchive.h>
#import <AFNetworking/AFNetworking.h>
#import <AFNetworking/AFNetworkReachabilityManager.h>

static NSString * const kResumeData = @"ResumeData";
static NSString * const kSessionConfiguration = @"VoiceDownloading";
static const double kProgressDelta = 0.01; // a percent

@interface SMVoicesDownloader () <SSZipArchiveDelegate>

@property (nonatomic, readwrite) SMVoice *nowDownloadingVoice;
@property (nonatomic) NSURLSessionConfiguration *configuration;
@property (nonatomic) AFURLSessionManager *manager;

@property (nonatomic, readwrite, getter=isDownloading) BOOL downloading;
@property (nonatomic, readwrite) double progress;
@property (nonatomic, readwrite) double prevProgress;

@property NSURLSessionDownloadTask *downloadTask;

@end

@implementation SMVoicesDownloader

+ (instancetype)downloader
{
    static SMVoicesDownloader *_sharedDownloader = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedDownloader = [[SMVoicesDownloader alloc] init];
    });
    
    return _sharedDownloader;
}

// check downloaded voices. Did all voices really purchased? without tricks
- (NSArray *)purchasedVoices
{
    NSArray *smVoices = [[SMVoiceManager sharedManager] voices];
    NSArray *purchases = [[SMSettings sharedSettings] purchases];
    
    NSMutableArray *currentVoices = [NSMutableArray array];
    for (SMVoice *voice in smVoices) {
        for (NSString* uid in purchases) {
            if ([voice.productID isEqualToString:uid]) {
                [currentVoices addObject:voice];
                break;
            }
        }
    }
    
    return currentVoices;
}

- (NSArray*)leftVoices
{
    NSMutableSet *purchasedSet = [NSMutableSet setWithArray:[self purchasedVoices]];
    NSSet *downloadedSet = [NSSet setWithArray:[AcapelaSpeech availableSMVoices]];
    [purchasedSet minusSet:downloadedSet];
    NSArray *left = [purchasedSet.allObjects sortedArrayUsingComparator:^NSComparisonResult(SMVoice* obj1, SMVoice* obj2) {
        return [obj1.title localizedCaseInsensitiveCompare:obj2.title];
    }];
    NSMutableArray *arr = [NSMutableArray arrayWithArray:left];
    [arr removeObject:self.nowDownloadingVoice];
    
    return [arr copy];
}

- (void)refreshVoices
{
    if (self.isDownloading || ![self p_isCorrectConnection]) {
        return;
    }

    NSArray *left = self.leftVoices;
    DLog(@"Left voices: %@", left);
    SMVoice *voice = [left firstObject];
    if (voice && !self.isDownloading) {
        [self downloadVoice:voice];
    }
}

- (BOOL)p_isCorrectConnection
{
    if ([[SMSettings sharedSettings] isDownloadVoiceOnlyViaWiFi]) {
        return [[AFNetworkReachabilityManager sharedManager] isReachableViaWiFi];
    }
    return [[AFNetworkReachabilityManager sharedManager] isReachable];
}

- (void)downloadVoice:(SMVoice*)voice
{
    self.nowDownloadingVoice = voice;
    self.progress = self.prevProgress = 0;
    
    NSURL *(^destinationBlock)(NSURL *targetPath, NSURLResponse *response) = ^(NSURL *targetPath, NSURLResponse *response) {
        NSURL *documentsDirectoryURL = [NSURL fileURLWithPath: DOCUMENTS_DIRECTORY];
        return [documentsDirectoryURL URLByAppendingPathComponent:[response suggestedFilename]];
    };
    
    NSURL *URL = [NSURL URLWithString:voice.link];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    NSProgress *progress = nil;
    void (^complitionBlock)(NSURLResponse *response, NSURL *filePath, NSError *error) = ^(NSURLResponse *response, NSURL *filePath, NSError *error) {
        [progress removeObserver:self forKeyPath:@"fractionCompleted"];
        if (error) {
            DLog(@"Voice downloading failed: %@", [error localizedDescription]);
            [SMVoicesDownloader p_removeFileAtPath:filePath.absoluteString];
            self.nowDownloadingVoice = nil;
            self.progress = self.prevProgress = 0;
            
            NSData *resumeData = [error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData];
            [self p_saveDataForResuming:resumeData];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([self.delegate respondsToSelector:@selector(voicesDownloaderFailedDownloading:error:)]) {
                    [self.delegate voicesDownloaderFailedDownloading:self error:error];
                }
            });
            return;
        }
        
        DLog(@"Voice downloaded");
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self.delegate respondsToSelector:@selector(voicesDownloaderDidDownload:)]) {
                [self.delegate voicesDownloaderDidDownload:self];
            }
        });
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [SSZipArchive unzipFileAtPath:filePath.path toDestination:DOCUMENTS_DIRECTORY delegate:self];
        });
    };
    
    NSData *resumeData = [[NSUserDefaults standardUserDefaults] objectForKey:kResumeData];
    if ([self p_isValidResumeData:resumeData]) {
        self.downloadTask = [self.manager downloadTaskWithResumeData:resumeData progress:&progress destination:destinationBlock completionHandler:complitionBlock];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kResumeData];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    else {
        self.downloadTask = [self.manager downloadTaskWithRequest:request progress:&progress destination:destinationBlock completionHandler:complitionBlock];
    }
    [self.downloadTask resume];
    [progress addObserver:self forKeyPath:@"fractionCompleted" options:NSKeyValueObservingOptionNew context:NULL];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(voicesDownloaderWillDownload:)]) {
            [self.delegate voicesDownloaderWillDownload:self];
        }
    });
}

- (BOOL)p_isValidResumeData:(NSData *)data
{
    if (!data || [data length] < 1) return NO;
    
    NSError *error;
    NSDictionary *resumeDictionary = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListImmutable format:NULL error:&error];
    if (!resumeDictionary || error) return NO;
    
    NSString *localFilePath = [resumeDictionary objectForKey:@"NSURLSessionResumeInfoLocalPath"];
    if ([localFilePath length] < 1) return NO;
    
    return [[NSFileManager defaultManager] fileExistsAtPath:localFilePath];
}

- (void)p_saveDataForResuming:(NSData*)resumeData
{
    [[NSUserDefaults standardUserDefaults] setObject:resumeData forKey:kResumeData];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)cancelByProducingResumeData
{
    [self.downloadTask cancelByProducingResumeData:^(NSData *resumeData) {
        [self p_saveDataForResuming:resumeData];
    }];
}

+ (void)removeTrashFromDocuments
{
    // remove zip achives
    NSArray *directoryContent = [[NSFileManager defaultManager] directoryContentsAtPath:DOCUMENTS_DIRECTORY];
    for (NSString *path in directoryContent) {
        if ([path hasSuffix:@".zip"]) {
            [self p_removeFileAtPath:[DOCUMENTS_DIRECTORY stringByAppendingPathComponent:path]];
        }
    }
}

#pragma mark - Lazy

- (NSURLSessionConfiguration *)configuration
{
    if (!_configuration) {
        NSString *uid = [NSString stringWithFormat:@"%@%i", kSessionConfiguration, arc4random()];
        
        if (SMiOS8) {
            _configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:uid];
        }
        else {
            _configuration = [NSURLSessionConfiguration backgroundSessionConfiguration:uid];
        }
    }
    return _configuration;
}

- (AFURLSessionManager *)manager
{
    if (!_manager) {
        _manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:self.configuration];
    }
    return _manager;
}

- (BOOL)isDownloading
{
    return self.nowDownloadingVoice != nil;
}

#pragma mark -

+ (void)p_removeFileAtPath:(NSString*)filePath
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:filePath]) {
        NSError *error;
        if (![fileManager removeItemAtPath:filePath error:&error]) {
            DLog(@"Error removing file: %@", [error localizedDescription]);
        };
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"fractionCompleted"]) {
        NSProgress *progress = (NSProgress *)object;
        self.progress = progress.fractionCompleted;
        
        if (self.progress - self.prevProgress > kProgressDelta) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([self.delegate respondsToSelector:@selector(voicesDownloaderDownload:progress:)]) {
                    [self.delegate voicesDownloaderDownload:self progress:self.progress];
                }
                self.prevProgress = self.progress;
            });
        }
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - SSZipArchive Delegate

- (void)zipArchiveWillUnzipArchiveAtPath:(NSString *)path zipInfo:(unz_global_info)zipInfo
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(voicesDownloaderWillUnzipArchive:)]) {
            [self.delegate voicesDownloaderWillUnzipArchive:self];
        }
    });
}

- (void)zipArchiveProgressEvent:(NSInteger)loaded total:(NSInteger)total
{
    double progress = total > 0 ? 1.0 * loaded/total : 0;
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(voicesDownloaderUnzipArchive:progress:)]) {
            [self.delegate voicesDownloaderUnzipArchive:self progress:progress];
        }
    });
}

- (void)zipArchiveDidUnzipArchiveAtPath:(NSString *)path zipInfo:(unz_global_info)zipInfo unzippedPath:(NSString *)unzippedPath
{
    DLog(@"Voice unpacked");
    
    NSString *lang = [SMLanguage langWithLocaleIdentifier:self.nowDownloadingVoice.locale].shortLocale;
    if (![[SMSettings sharedSettings] selectedVoiceForLanguage:lang]) {
        [[SMSettings sharedSettings] setSelectedVoice:self.nowDownloadingVoice];
    }
    [AcapelaSpeech refreshVoiceList];
    [SMVoicesDownloader p_removeFileAtPath:path];
    self.nowDownloadingVoice = nil;
    self.progress = self.prevProgress = 0;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(voicesDownloaderDidUnzipArchive:)]) {
            [self.delegate voicesDownloaderDidUnzipArchive:self];
        }
    });
    
    [self refreshVoices];
}

@end
