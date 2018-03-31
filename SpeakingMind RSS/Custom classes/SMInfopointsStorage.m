//
//  SMInfopointsStorage.m
//  Speind
//
//  Created by Sergey Butenko on 12/3/14.
//  Copyright (c) 2014 Speaking Mind. All rights reserved.
//

#import "SMInfopointsStorage.h"
#import "SMDefines.h"

static NSString *const kDataKey = @"SavedData";
static NSString *const kCurrentIndexKey = @"SavedCurrentIndex";
static NSString *const kPlayerIndexKey = @"SavedPlayerIndex";

@interface SMInfopointsStorage ()

- (void)p_saveCurrentIndex;
- (void)p_savePlayerIndex;

@end

@implementation SMInfopointsStorage

+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    static SMInfopointsStorage * sSharedInstance;
    
    dispatch_once(&onceToken, ^{
        sSharedInstance = [[SMInfopointsStorage alloc] init];
    });
    return sSharedInstance;
}

- (id)init
{
    self = [super init];
    if (self != nil) {
        NSURL *dataFileURL = [[self p_applicationDocumentsDirectory] URLByAppendingPathComponent:kDataKey];
        if ([[NSFileManager defaultManager] fileExistsAtPath:[dataFileURL path]]) {
            _data = [[NSKeyedUnarchiver unarchiveObjectWithFile:[dataFileURL path]] mutableCopy];
        }
        else {
            _data = [[NSMutableArray alloc] init];
        }
        
        NSURL *currentIndexFileURL = [[self p_applicationDocumentsDirectory] URLByAppendingPathComponent:kCurrentIndexKey];
        if ([[NSFileManager defaultManager] fileExistsAtPath:[currentIndexFileURL path]]) {
            _currentIndex =[NSKeyedUnarchiver unarchiveObjectWithFile:[currentIndexFileURL path]];
        }
        else {
            _currentIndex = @(0);
        }
        
        NSURL *playerIndexFileURL = [[self p_applicationDocumentsDirectory] URLByAppendingPathComponent:kPlayerIndexKey];
        if ([[NSFileManager defaultManager] fileExistsAtPath:[playerIndexFileURL path]]) {
            _playerIndex =[NSKeyedUnarchiver unarchiveObjectWithFile:[playerIndexFileURL path]];
        }
        else {
            _playerIndex = @(0);
        }
    }
    return self;
}

- (void)saveData
{
    NSURL *dataFileURL = [[self p_applicationDocumentsDirectory] URLByAppendingPathComponent:kDataKey];
    [NSKeyedArchiver archiveRootObject:[self.data copy] toFile:[dataFileURL path]];
}

- (void)setCurrentIndex:(NSNumber *)currentIndex
{
    _currentIndex = currentIndex;
    [self p_saveCurrentIndex];
}

- (void)p_saveCurrentIndex
{
    NSURL *dataFileURL = [[self p_applicationDocumentsDirectory] URLByAppendingPathComponent:kCurrentIndexKey];
    [NSKeyedArchiver archiveRootObject:self.currentIndex toFile:[dataFileURL path]];
}

- (void)setPlayerIndex:(NSNumber *)playerIndex
{
    _playerIndex = playerIndex;
    [self p_savePlayerIndex];
}

- (void)p_savePlayerIndex
{
    NSURL *dataFileURL = [[self p_applicationDocumentsDirectory] URLByAppendingPathComponent:kPlayerIndexKey];
    [NSKeyedArchiver archiveRootObject:[self.playerIndex copy] toFile:[dataFileURL path]]; // copy to avoid 'was mutated while being enumerated'
}

- (NSURL *)p_applicationDocumentsDirectory
{
    return [NSURL fileURLWithPath: DOCUMENTS_DIRECTORY];
}

@end
