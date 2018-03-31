//
//  AcapelaSpeech+Speind.h
//  SpeakingMind RSS
//
//  Created by Sergey Butenko on 9/8/14.
//  Copyright (c) 2014 serejahh inc. All rights reserved.
//

#import "AcapelaSpeech.h"
#import "SMLanguage.h"

@interface AcapelaSpeech (Speind)

/**
 *
 * @return Массив объектов SMLanguage с голосами, на которых можно читать, т.е. куплен хотя бы один голос для языка.
 *
 */
+ (NSArray*)availableLanguages;

/** Return available voices represented as SMVoice insted of NSDictionary in +(NSArray*)availableVoices.
 *
 * @return Array of SMVoice.
 *
 */
+ (NSArray*)availableSMVoices;

@end
