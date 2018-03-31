//
//  AcapelaSpeech+Speind.m
//  SpeakingMind RSS
//
//  Created by Sergey Butenko on 9/8/14.
//  Copyright (c) 2014 serejahh inc. All rights reserved.
//

#import "AcapelaSpeech+Speind.h"
#import "SMVoiceManager.h"
#import "SMVoice.h"

@implementation AcapelaSpeech (Speind)

+ (NSArray*)availableLanguages
{
    NSArray *voices = [AcapelaSpeech availableVoices];
    NSMutableOrderedSet *availableLanguages = [NSMutableOrderedSet orderedSet];
    
    for (NSString *voice in voices) {
        NSDictionary *attributes = [AcapelaSpeech attributesForVoice:voice];
        NSString *voiceLocale = attributes[AcapelaVoiceLocaleIdentifier];

        SMLanguage *voiceLang = [SMLanguage langWithLocaleIdentifier:voiceLocale];
        [availableLanguages addObject:voiceLang];
    }

    return [availableLanguages.array sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
}

+ (NSArray*)availableSMVoices
{
    NSArray *allVoices = [[SMVoiceManager sharedManager] voices];
    
    NSArray *downloadedVoices = [AcapelaSpeech availableVoices];
    NSMutableArray *smVoices = [NSMutableArray array];
    for (NSString *voiceName in downloadedVoices) {
        NSDictionary *attributes = [AcapelaSpeech attributesForVoice:voiceName];
        NSString *name = attributes[AcapelaVoiceName];
        
        for (SMVoice *v in allVoices) {
            if ([v.name isEqualToString:name]) {
                [smVoices addObject:v];
                break;
            }
        }
    }
    
    return smVoices;
}

@end
