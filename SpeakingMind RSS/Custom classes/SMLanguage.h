//
//  SMLanguage.h
//  Speind
//
//  Created by Sergey Butenko on 9/8/14.
//  Copyright (c) 2014 serejahh inc. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * Contains most used voice's language properties: locale, language, full language (lang + country).
 */
@interface SMLanguage : NSObject

@property (nonatomic, readonly) NSString *shortLang;
@property (nonatomic, readonly) NSString *fullLang;
@property (nonatomic, readonly) NSString *locale;
@property (nonatomic, readonly) NSString *shortLocale;

/**
 *
 * @param localeIdentifier Identifier of language (e.g. en_US, en_GB, fr_CA, fr_FR, ru_RU).
 *
 * @return Language described as is: in English for en_US, in Русский for ru_RU.
 *
 * @warning For incorrect localeIdentifier returns nil.
 *
 */
+ (instancetype)langWithLocaleIdentifier:(NSString*)localeIdentifier;

@end
