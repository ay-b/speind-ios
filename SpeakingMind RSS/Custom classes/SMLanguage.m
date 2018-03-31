//
//  SMLanguage.m
//  Speind
//
//  Created by Sergey Butenko on 9/8/14.
//  Copyright (c) 2014 serejahh inc. All rights reserved.
//

#import "SMLanguage.h"

@interface SMLanguage ()

@property (nonatomic, readwrite) NSString *shortLang; // English
@property (nonatomic, readwrite) NSString *fullLang; // English (United States)
@property (nonatomic, readwrite) NSString *locale; // en_US
@property (nonatomic, readwrite) NSString *shortLocale; // en

@end

@implementation SMLanguage

// TODO: memory optimization: save only locale; calculate short and full lang when it calls
// TODO: lazy instantiation

- (instancetype)initWithLocaleIdentifier:(NSString*)localeIdentifier
{
    self = [super init];
    if (self) {
        NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:localeIdentifier]; // currentLocale
        
        _locale = localeIdentifier;
        _shortLocale = [[_locale componentsSeparatedByString:@"_"] firstObject];
        _fullLang = [[locale displayNameForKey:NSLocaleIdentifier value:localeIdentifier] capitalizedString];
        _shortLang = [[_fullLang componentsSeparatedByString:@" ("] firstObject];
        if (_shortLang == nil) {
            _shortLang =  _locale;
        }
        
        if (!_fullLang) {
            return nil;
        }
    }
    return self;
}

+ (instancetype)langWithLocaleIdentifier:(NSString*)localeIdentifier
{
    return [[self alloc] initWithLocaleIdentifier:localeIdentifier];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@", _shortLang];
}

- (NSString *)debugDescription
{
    return [NSString stringWithFormat:@"<%@> %@ | %@ (%@) - %@", [self class], _shortLang, _shortLocale, _locale, _fullLang];
}

#pragma mark - Hashable

// maybe en_US and en_GB should be NOT equal
- (BOOL)isEqual:(id)other
{
    if (other == self) {
        return YES;
    }
    else {
        if ([other isKindOfClass:[SMLanguage class]]) {
            SMLanguage *lang = other;
            return [_shortLocale isEqualToString:lang.shortLocale];
        }
    }
    return NO;
}

- (NSUInteger)hash
{
    return [_shortLocale hash];
}

- (NSComparisonResult)compare:(SMLanguage *)lang {
    return [self.description compare:lang.description];
}

- (NSComparisonResult)localizedCaseInsensitiveCompare:(SMLanguage *)lang {
    return [self.description localizedCaseInsensitiveCompare:lang.description];
}


@end
