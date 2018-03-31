//
//  SMVoiceManager.h
//  Speind
//
//  Created by Sergey Butenko on 9/2/14.
//  Copyright (c) 2014 serejahh inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SMVoice.h"

/**
 * Класс-обертка для получения голосов, доступных в Acapela Speech. 
 *
 * Разработчик андроид-версии (@@maple) использует статические данные для хранения голоса. Я решил не париться и захардкодил аналогично, преобразовав его код с помощью find-replace. Отдельно хранятся ссылки на демки и на архивы самих голосов.
 *
 */

@interface SMVoiceManager : NSObject

+ (instancetype)sharedManager;

/**
 * @return Массив NSString с языками голосов, которые доступны в Acapale Speech.
 */
- (NSArray*)availableLanguages;

/**
 *
 * @param language Язык, для которого нужно получить голоса, доступные в Acapela Speech.
 *
 * @remarks Лучше использовать язык, полученный из -(NSArray*)availableLanguages.
 *
 * @return Массив SMVoice с голосами для заданного языка, которые доступны в Acapale Speech.
 *
 */
- (NSArray*)voicesForLanguage:(NSString*)language;

/** Return free voices that we can download in first launch.
 *
 * @return Array of SMVoice.
 *
 */
- (NSArray*)freeVoices;

/**
 * Преобразование хардкода ниже в массив нормальных объектов SMVoice.
 */
@property (nonatomic) NSArray *voices;

@end

