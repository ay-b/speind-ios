//
//  SMVoice.m
//  Speind
//
//  Created by Sergey Butenko on 9/2/14.
//  Copyright (c) 2014 serejahh inc. All rights reserved.
//

#import "SMVoice.h"
#import "SMDefines.h"

@interface SMVoice ()

@property (nonatomic, readwrite, getter=isNativeVoice) BOOL nativeVoice;
@property (nonatomic, readwrite) NSString *demoText;

@end

@implementation SMVoice

- (instancetype)initWithLang:(NSString*)lang title:(NSString*)title name:(NSString*)name locale:(NSString*)locale demo:(NSString*)demo link:(NSString*)link
{
    self = [super init];
    if (self) {
        _lang = [lang copy];
        _title = [title copy];
        _name = [name copy];
        _locale = [locale copy];
        _demo = [demo copy];
        _link = [link copy];
    }
    return self;
}

+ (instancetype)voiceWithLang:(NSString*)lang title:(NSString*)title name:(NSString*)name locale:(NSString*)locale demo:(NSString*)demo link:(NSString*)link
{
    return [[self alloc] initWithLang:lang title:title name:name locale:locale demo:demo link:link];
}

+ (instancetype)nativeVoiceForLang:(NSString*)lang
{    
    NSString *title = [NSString stringWithFormat:LOC(@"Default voice title"), [lang lowercaseString]];
    title = [title stringByReplacingCharactersInRange:NSMakeRange(0,1) withString:[[title substringToIndex:1] uppercaseString]];
    
    SMVoice *voice = [[self alloc] initWithLang:lang title:title name:title locale:nil demo:@"" link:@""];
    
    NSString *locale;
    NSString *demoText;
    if ([lang isEqualToString:@"Русский"]) {
        locale = @"ru-RU";
        demoText = @"Когда вы в движении, Спикин Майнд — это лучший способ быть в курсе новостей и обновлений в социальных сетях. Слушайте новости, друзей и музыку! Расскажите всем об этом приложении!";
    }
    else if ([lang isEqualToString:@"English"]) {
        locale = @"en-US";
        demoText = @"Listening to Speaking Mind is the only right way to get news and social networks updates on the go. Listen, enjoy, be safe! Don't forget to spread the word about this great app!";
    }
    else if ([lang isEqualToString:@"Français"]) {
        locale = @"fr-CA";
        demoText = @"Quand vous êtes en mouvement , Speaking Mind est une meileure possibilité d'être au courant des actualités et des mises de vos networks socials. Écoutez des actualités, vos amis et la musique! Dites vos amis de cette app!";
    }
    else if ([lang isEqualToString:@"Español"]) {
        locale = @"es-ES";
        demoText = @"Escuchar Spiking Maind es la mejor manera de recibir noticias y actualizaciones de las redes sociales al momento. ?Escucha, disfruta y no te arriesgues! ?Y hablales a todos tus amigos de esta gran aplicacion!";
    }
    voice.locale = locale;
    voice.demoText = demoText;

    voice.nativeVoice = YES;
    return voice;
}

- (NSString*)storedUid
{
    if (self.isNativeVoice) {
         return [self.locale componentsSeparatedByString:@"-"][0];
    }
    return self.locale;
}

- (NSString*)storedValue
{
    if (self.isNativeVoice) {
        return self.locale;
    }
    return [[self uid] stringByAppendingString:@".bvcu"];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ - %@", _lang, _title];
}

- (NSString *)demo
{
    return [NSString stringWithFormat:@"%@%@", SMURLVoiceDemo, _demo];
}

- (NSString *)link
{
    return [NSString stringWithFormat:@"%@%@", SMURLVoice, _link];
}

- (NSString*)uid
{
    if (self.isNativeVoice) {
        return self.locale;
    }
    return [[_demo componentsSeparatedByString:@"."] firstObject];
}

- (NSString*)acapelaName
{
    return [[self uid] stringByAppendingString:@".bvcu"];
}

- (NSString*)productID
{
    NSString *voiceID = [[_link componentsSeparatedByString:@"."][0] stringByReplacingOccurrencesOfString:@"-" withString:@"_"];
    NSString *uid = [SMVoicesProductIDPrefix stringByAppendingString:voiceID];
    return uid;
}

- (NSUInteger)hash
{
    return [[self productID] hash];
}

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[self class]]) {
        SMVoice *voice = object;
        return [self.name isEqualToString:voice.name];
    }
    return NO;
}

@end
