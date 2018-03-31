//
//  SMTweetBuilder.m
//  Speind
//
//  Created by Sergey Butenko on 10/11/14.
//  Copyright (c) 2014 Speaking Mind. All rights reserved.
//

#import "SMTweetBuilder.h"
#import "SMDefines.h"
#import "SMInfopointTweet.h"
#import "NSString+Language.h"
#import "NSString+TimeToString.h"
#import "AcapelaSpeech+Speind.h"

static const NSInteger kMaxDaysCount = 3;

@interface SMTweetBuilder ()

/**
 * Translated pharses for some languages.
 */
@property (nonatomic) NSDictionary *phrases;

#pragma mark - Private API
#pragma mark Preparation

/**
 * Пропускаем твит, если не может прочитать его или он старый.
 */
- (BOOL)p_skipTweet:(NSDictionary*)tweet;

/**
 * Можем ли прочитать текст твита с помощью голосов, которые куплены. Например, если куплен только русский, то все твиты не на русском игнорируются.
 */
- (BOOL)p_canSpeakTweet:(NSDictionary*)tweet;

/**
 * Проверят, был ли опубликован твит меньше, чем @bb kMaxDaysCount дней тому назад.
 */
- (BOOL)p_isOldTweet:(NSDictionary*)tweet;

/**
 * @return Количество дней между датами.
 */
- (NSInteger)p_daysBetweenDate:(NSDate*)fromDateTime andDate:(NSDate*)toDateTime;

/**
 * Собирает все данные в инфоточку.
 */
- (SMInfopointTweet*)p_infopointForTweet:(NSDictionary*)tweet;

#pragma mark Processing

/**
 * Текст, который отображается в качестве провайдера - между текстом и картинкой инфоточки.
 */
- (NSString*)p_titleForTweet:(NSDictionary*)tweet;

/**
 * @return Текст, который отображается в ленте под фотографией.
 */
- (NSString*)p_textForTweet:(NSDictionary*)tweet;

/**
 * @return Ссылка на изображение, которое отображается слева от провайдера.
 */
- (NSString*)p_senderIconForTweet:(NSDictionary*)tweet;

/**
 * По умолчанию берется аватар автора твита. Если к твиту были добавлены картинки, то берем первую.
 *
 * @return Ссылка на картинку для инфоточки.
 *
 */
- (NSString*)p_previewImageForTweet:(NSDictionary*)tweet;

/**
 *
 * Возвращает первую найденную ссылку из текста твита (не картинку t.co).
 *
 * @return Ссылка на картинку или nil, если ссылки не было.
 */
- (NSString*)p_linkForTweet:(NSDictionary*)tweet;

/**
 * @return Дата публикования твита.
 */
- (NSDate*)p_dateForTweet:(NSDictionary*)tweet;

#pragma mark Vocalizing

/**
 * Собирает все данные во фразу, которая будет произнесена с помощью TTS.
 */
- (NSString*)p_vocalizingTextForTweet:(NSDictionary*)tweet;

/**
 * Удаляем всякие штуки, которые мешают нормально произносить текст.
 */
- (NSString*)p_prepareText:(NSString*)rawText;

@end

@implementation SMTweetBuilder

- (NSDictionary *)phrases
{
    if (!_phrases) {
        _phrases = @{@"retweeted" : @{
                             @"ru" : @"сделал ретвит пользователя",
                             @"en" : @"retweeted user",
                             @"fr" : @"",
                             @"es" : @""},
                     
                     @"write" : @{
                             @"ru" : @"пишет:",
                             @"en" : @"wrote:",
                             @"fr" : @"",
                             @"es" : @""},
                     @"link" : @{
                             @"ru" : @"ссылка на веб-сайт",
                             @"en" : @"external website link",
                             @"fr" : @"",
                             @"es" : @""},
                     @"quote" : @{
                             @"ru" : @"Цитата",
                             @"en" : @"Citate",
                             @"fr" : @"",
                             @"es" : @""},
                     @"reply" : @{
                             @"ru" : @"Ответ",
                             @"en" : @"Reply",
                             @"fr" : @"",
                             @"es" : @""},
                     @"from" : @{
                             @"ru" : @"от",
                             @"en" : @"from",
                             @"fr" : @"",
                             @"es" : @""}};
    }
    return _phrases;
}

#pragma mark - Public API

+ (instancetype)sharedBuilder
{
    static SMTweetBuilder *builder;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        builder = [SMTweetBuilder new];
    });
    return builder;
}

- (NSArray*)infopointsForTweets:(NSArray*)tweets
{
    NSMutableArray *correctTweets = [NSMutableArray array];
    for (NSDictionary *tweet in tweets) {
        if (![self p_skipTweet:tweet]) {
            [correctTweets addObject:[self p_infopointForTweet:tweet]];
        }
    }
    return [correctTweets copy];
}

#pragma mark - Preparation

- (BOOL)p_skipTweet:(NSDictionary*)tweet
{
    return [self p_isOldTweet:tweet] || ![self p_canSpeakTweet:tweet];
}

- (BOOL)p_canSpeakTweet:(NSDictionary*)tweet
{
    BOOL can = NO;
    NSString *text = tweet[@"text"];
    NSString *langOfText = [text sm_langOfString];
    for (NSString* locale in [[SMSettings sharedSettings] supportedLocales]) {
        if ([langOfText isEqualToString:locale]) {
            can = YES;
            break;
        }
    }

    return can;
}

- (BOOL)p_isOldTweet:(NSDictionary*)tweet
{
    NSDate *date = [self p_dateForTweet:tweet];
    NSInteger days = [self p_daysBetweenDate:date andDate:[NSDate date]];
    
    return days > kMaxDaysCount;
}

- (NSInteger)p_daysBetweenDate:(NSDate*)fromDateTime andDate:(NSDate*)toDateTime
{
    NSDate *fromDate;
    NSDate *toDate;
    NSCalendar *calendar = [NSCalendar currentCalendar];
    [calendar rangeOfUnit:NSDayCalendarUnit startDate:&fromDate interval:NULL forDate:fromDateTime];
    [calendar rangeOfUnit:NSDayCalendarUnit startDate:&toDate interval:NULL forDate:toDateTime];
    NSDateComponents *difference = [calendar components:NSDayCalendarUnit  fromDate:fromDate toDate:toDate options:0];
    
    return [difference day];
}

- (SMInfopointTweet*)p_infopointForTweet:(NSDictionary*)tweet
{
    SMInfopointTweet *infopoint = [SMInfopointTweet new];
    
    infopoint.pubDate = [self p_dateForTweet:tweet];
    infopoint.textVocalizing = [self p_vocalizingTextForTweet:tweet]; // vocalizing
    infopoint.summary = [self p_textForTweet:tweet];
    infopoint.title = [self p_titleForTweet:tweet]; // @"" 'coz title uses for making vocalizing text of news
    infopoint.senderIcon = [self p_senderIconForTweet:tweet];
    infopoint.postSender = [self p_titleForTweet:tweet];
    infopoint.priority = SMDefaultInfopointPriority;
    infopoint.enclosure = [self p_previewImageForTweet:tweet];
    infopoint.link = [self p_linkForTweet:tweet];
    infopoint.lang = [tweet[@"text"] sm_langOfString];
    infopoint.postSenderVocalizing = [self p_postSenderVocalizingForTweet:tweet];
    
    return infopoint;
}

#pragma mark Processing

- (NSString*)p_titleForTweet:(NSDictionary*)tweet
{
    NSMutableString *title = [NSMutableString string];
    
    [title appendFormat:@"@%@", tweet[@"user"][@"screen_name"]];
    if (tweet[@"retweeted_status"]) {
        [title appendFormat:@" RT @%@", tweet[@"retweeted_status"][@"user"][@"screen_name"]];
    }
    else if (![tweet[@"in_reply_to_screen_name"] isEqual:[NSNull null]]) {
        [title appendFormat:@" RPL @%@", tweet[@"in_reply_to_screen_name"]];
    }
    
    return [title copy];
}

- (NSString*)p_textForTweet:(NSDictionary*)tweet
{
    NSString *text = tweet[@"text"];
    if (tweet[@"retweeted_status"]) {
        text = tweet[@"retweeted_status"][@"text"];
    }
    
    // remove a image-link from the text
    NSString *img = [self p_previewImageForTweet:tweet];
    NSArray *media = tweet[@"entities"][@"media"];
    for (NSDictionary *element in media) {
        if ([element[@"media_url"] isEqualToString:img]) {
            text = [text stringByReplacingOccurrencesOfString:element[@"url"] withString:@""];
            break;
        }
    }
    
    return text;
}

- (NSString*)p_senderIconForTweet:(NSDictionary*)tweet
{
    return tweet[@"user"][@"profile_image_url"];
}

- (NSString*)p_previewImageForTweet:(NSDictionary*)tweet
{
    NSString *image = [tweet[@"user"][@"profile_image_url"] stringByReplacingOccurrencesOfString:@"_normal" withString:@""];
    if (tweet[@"retweeted_status"]) {
        image = [tweet[@"retweeted_status"][@"user"][@"profile_image_url"] stringByReplacingOccurrencesOfString:@"_normal" withString:@""];
    }
    
    NSArray *media = tweet[@"entities"][@"media"];
    for (NSDictionary *element in media) {
        if ([element[@"type"]isEqualToString:@"photo"]) {
            image = element[@"media_url"];
            break;
        }
    }
    
    return image;
}

- (NSString*)p_linkForTweet:(NSDictionary*)tweet
{
    NSString *link = nil;
    
    NSArray *media = tweet[@"entities"][@"urls"];
    for (NSDictionary *element in media) {
        if (![element[@"type"] isEqualToString:@"photo"]) {
            link = element[@"url"];
            break;
        }
    }
    
    return link;
}

- (NSDate*)p_dateForTweet:(NSDictionary*)tweet
{
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
    [dateFormat setDateFormat:@"EEE MMM dd HH:mm:ss Z yyyy"];
    return [dateFormat dateFromString:tweet[@"created_at"]];
}

#pragma mark Vocalizing

- (NSString*)p_vocalizingTextForTweet:(NSDictionary*)tweet
{
    NSString *text = tweet[@"text"];
    if (tweet[@"retweeted_status"]) { // some links can be cropped with "..." witn ["text"] when it retweeted
        text = tweet[@"retweeted_status"][@"text"];
    }
    
    // remove a image-link from the text
    NSString *img = [self p_previewImageForTweet:tweet];
    NSArray *media = tweet[@"entities"][@"media"];
    for (NSDictionary *element in media) {
        if ([element[@"media_url"] isEqualToString:img]) {
            text = [text stringByReplacingOccurrencesOfString:element[@"url"] withString:@""];
            break;
        }
    }

    // preparation the text for vocalizing
    text = [self p_prepareText:text];
    
    NSString *langOfText = [text sm_langOfString];
    NSString *user = tweet[@"user"][@"name"];
    NSString *langOfUserName = [user sm_langOfString];
    if (![langOfText isEqualToString:langOfUserName]) {
        user = tweet[@"user"][@"screen_name"];
    }
    
    
    NSString *action = self.phrases[@"write"][langOfText];
    if (tweet[@"retweeted_status"]) {
        NSString *retweetedName = tweet[@"retweeted_status"][@"user"][@"screen_name"];
        if (![langOfText isEqualToString:[retweetedName sm_langOfString]]) {
            retweetedName = tweet[@"retweeted_status"][@"user"][@"name"];
        }
        
        action = [NSString stringWithFormat: @"%@ %@", self.phrases[@"retweeted"][langOfText], retweetedName];
    }
    else if (![tweet[@"in_reply_to_screen_name"] isEqual:[NSNull null]]) {
        NSString *repliedUser = tweet[@"in_reply_to_screen_name"];
        if ([text hasPrefix:repliedUser]) {
            text = [text stringByReplacingOccurrencesOfString:repliedUser withString:@""];
        }
        
        action = [NSString stringWithFormat: @"%@ %@: %@ %@", self.phrases[@"reply"][langOfText], tweet[@"in_reply_to_screen_name"], text, user];
        return action;
    }
    
    NSString *result = [NSString stringWithFormat:@"%@ %@. %@", user, action, text];
    return result;
}

- (NSString*)p_postSenderVocalizingForTweet:(NSDictionary*)tweet
{
    NSString *text = tweet[@"text"];
    if (tweet[@"retweeted_status"]) { // some links can be cropped with "..." witn ["text"] when it retweeted
        text = tweet[@"retweeted_status"][@"text"];
    }
    
    // remove a image-link from the text
    NSString *img = [self p_previewImageForTweet:tweet];
    NSArray *media = tweet[@"entities"][@"media"];
    for (NSDictionary *element in media) {
        if ([element[@"media_url"] isEqualToString:img]) {
            text = [text stringByReplacingOccurrencesOfString:element[@"url"] withString:@""];
            break;
        }
    }
    
    // preparation the text for vocalizing
    text = [self p_prepareText:text];
    
    NSString *langOfText = [text sm_langOfString];
    NSString *user = tweet[@"user"][@"name"];
    NSString *langOfUserName = [user sm_langOfString];
    if (![langOfText isEqualToString:langOfUserName]) {
        user = tweet[@"user"][@"screen_name"];
    }
    
    
    NSString *action = self.phrases[@"write"][langOfText];
    if (tweet[@"retweeted_status"]) {
        NSString *retweetedName = tweet[@"retweeted_status"][@"user"][@"screen_name"];
        if (![langOfText isEqualToString:[retweetedName sm_langOfString]]) {
            retweetedName = tweet[@"retweeted_status"][@"user"][@"name"];
        }
        
        action = [NSString stringWithFormat: @"%@ %@", self.phrases[@"retweeted"][langOfText], retweetedName];
    }
    else if (![tweet[@"in_reply_to_screen_name"] isEqual:[NSNull null]]) {
        NSString *repliedUser = tweet[@"in_reply_to_screen_name"];
        if ([text hasPrefix:repliedUser]) {
            text = [text stringByReplacingOccurrencesOfString:repliedUser withString:@""];
        }
        
        action = [NSString stringWithFormat: @"%@ %@ %@ %@ %@", self.phrases[@"reply"][langOfText], tweet[@"in_reply_to_screen_name"], text, self.phrases[@"from"][langOfText] ,user];
        return action;
    }
    
    NSString *result = [NSString stringWithFormat:@"%@ %@. ", user, action];
    return result;
}

- (NSString*)p_prepareText:(NSString*)rawText
{
    if (!rawText) { return @""; }
    NSMutableString *text = [NSMutableString stringWithString:rawText];
    NSString *langOfText = [text sm_langOfString];
    
    [text replaceOccurrencesOfString:@"." withString:@". " options:NSCaseInsensitiveSearch range:NSMakeRange(0, text.length)];
    [text replaceOccurrencesOfString:@"“" withString:[NSString stringWithFormat:@"%@ ", self.phrases[@"quote"][langOfText]] options:NSCaseInsensitiveSearch range:NSMakeRange(0, text.length)];
    [text replaceOccurrencesOfString:@"«" withString:@" «" options:NSCaseInsensitiveSearch range:NSMakeRange(0, text.length)];
    [text replaceOccurrencesOfString:@"»" withString:@"» " options:NSCaseInsensitiveSearch range:NSMakeRange(0, text.length)];
    [text replaceOccurrencesOfString:@"  " withString:@" " options:NSCaseInsensitiveSearch range:NSMakeRange(0, text.length)];
    [text replaceOccurrencesOfString:@"http://t. co/" withString:@"http://t.co/" options:NSCaseInsensitiveSearch range:NSMakeRange(0, text.length)];
    [text replaceOccurrencesOfString:@"https://t. co/" withString:@"https://t.co/" options:NSCaseInsensitiveSearch range:NSMakeRange(0, text.length)];
    [text replaceOccurrencesOfString:@"@" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, text.length)];
    
    //8. Убираем все хэштеги (слова начинающиеся с #)
    NSInteger beforeLength = text.length;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"#\\S+" options:NSRegularExpressionCaseInsensitive error:nil];
    NSArray *hashtagsMatches = [regex matchesInString:text options:0 range:NSMakeRange(0, [text length])];
    for (NSTextCheckingResult *match in hashtagsMatches) {
        if (match.range.location != NSNotFound && match.range.length > 0) {
            NSRange range = match.range;
            range.location -= beforeLength - text.length;
            [text replaceCharactersInRange:range withString:@""];
        }
    }
    
    // 9. Все ссылки заменяем на "[link]"
    beforeLength = text.length;
    NSDataDetector* detector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:nil];
    NSArray *linksMatches = [detector matchesInString:text options:0 range:NSMakeRange(0, [text length])];
    for (NSTextCheckingResult *match in linksMatches) {
        if (match.range.location != NSNotFound && match.range.length > 0) {
            NSRange range = match.range;
            range.location -= beforeLength - text.length;
            [text replaceCharactersInRange:range withString:[NSString stringWithFormat:@" %@", self.phrases[@"link"][langOfText]]];
        }
    }
    
    return [text copy];
}

@end
