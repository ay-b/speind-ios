//
//  SMVoice.h
//  Speind
//
//  Created by Sergey Butenko on 9/2/14.
//  Copyright (c) 2014 serejahh inc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    SMVoiceNew, // available for buying
    SMVoiceDownloaded, // bought and downloaded
    SMVoiceCurrent // setted for reading for come language
} SMVoiceState;

@interface SMVoice : NSObject

@property NSString *lang;
@property NSString *title; // Kenny [USEnglish]
@property NSString *name; // Kenny
@property NSString *locale; // en
@property (nonatomic) NSString *demo; // link to demo file
@property (nonatomic) NSString *link; // link to archive
@property SMVoiceState state;
@property (nonatomic, readonly, getter=isNativeVoice) BOOL nativeVoice;
@property (nonatomic, readonly) NSString *demoText;

+ (instancetype)nativeVoiceForLang:(NSString*)lang;

- (instancetype)initWithLang:(NSString*)lang title:(NSString*)title name:(NSString*)name locale:(NSString*)locale demo:(NSString*)demo link:(NSString*)link;
+ (instancetype)voiceWithLang:(NSString*)lang title:(NSString*)title name:(NSString*)name locale:(NSString*)locale demo:(NSString*)demo link:(NSString*)link;

- (NSString*)storedUid;
- (NSString*)storedValue;

- (NSString*)uid;
- (NSString*)acapelaName;
- (NSString*)productID;

@end
