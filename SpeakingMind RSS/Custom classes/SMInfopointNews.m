//
//  SMNewsItem.m
//  Speind
//
//  Created by Sergey Butenko on 02.06.14.
//  Copyright (c) 2014 serejahh inc. All rights reserved.
//

#import "SMInfopointNews.h"
#import "NSString+Language.h"

@interface SMInfopointNews ()

@property (nonatomic) NSDictionary *phrases;

@end

@implementation SMInfopointNews

//@synthesize placeholder = _placeholder;

- (id)initWithTitle:(NSString*)title link:(NSString*)link summary:(NSString*)summary pubDate:(NSDate*)pubDate enclosure:(NSString*)enclosure
{
    self = [super init];
    if (self) {
        self.title = title;
        self.link = link;
        self.summary = summary;
        self.pubDate = pubDate;
        self.enclosure = enclosure;
    }
    
    return self;
}

- (id)initWithUid:(NSInteger)uid prioriry:(NSInteger)prioriry title:(NSString*)title link:(NSString*)link summary:(NSString*)summary fullArticle:(NSString*)fullArticle pubDate:(NSDate*)pubDate enclosure:(NSString*)enclosure
{
    self = [super init];
    if (self) {
        _uid = uid;
        self.priority = prioriry;
        self.title = title;
        self.link = link;
        self.summary = summary;
        self.fullArticle = fullArticle;
        self.pubDate = pubDate;
        self.enclosure = enclosure;
    }
    
    return self;
}

+ (instancetype)newsWithTitle:(NSString*)title link:(NSString*)link summary:(NSString*)summary pubDate:(NSDate*)pubDate enclosure:(NSString*)enclosure
{
    return [[self alloc] initWithTitle:title link:link summary:summary pubDate:pubDate enclosure:enclosure];
}

+ (instancetype)newsWithUid:(NSInteger)uid prioriry:(NSInteger)prioriry title:(NSString*)title link:(NSString*)link summary:(NSString*)summary fullArticle:(NSString*)fullArticle pubDate:(NSDate*)pubDate enclosure:(NSString*)enclosure
{
    return [[self alloc] initWithUid:uid prioriry:prioriry title:title link:link summary:summary fullArticle:fullArticle pubDate:pubDate enclosure:enclosure];
}

#pragma mark - Properties

- (NSDictionary *)phrases
{
    if (!_phrases) {
        _phrases = @{@"link" : @{
                             @"ru": @"ссылка на веб-сайт",
                             @"en": @"external website link",
                             @"fr": @"",
                             @"es": @""},
                     @"details" : @{
                             @"ru": @"Подробнее.",
                             @"en": @"Details",
                             @"fr": @"",
                             @"es": @""},
                     @"report_what" : @{
                             @"ru": @"сообщает, что",
                             @"en": @"wrote that",
                             @"fr": @"détails",
                             @"es": @"detalles"}
                     
                     };
    }
    return _phrases;
}

//- (NSString *)placeholder
//{
//    if (!_placeholder) {
//        _placeholder = [NSString stringWithFormat:@"placeholder_rss%i", rand()%3+1];
//    }
//    return _placeholder;
//}


#pragma mark - Overloading

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[self class]]) {
        SMInfopointNews *item = object;
        return [self.link isEqualToString:item.link];
    }
    return [super isEqual:object];
}

- (NSUInteger)hash
{
    return [self.link hash];
}

- (NSString*)vocalizingTextWithPreviuosInfopoint:(SMInfopoint*)infopoint fullArticle:(BOOL)fullArticle
{
    NSMutableString *phrase = [NSMutableString string];
    NSString *postSenderNow = self.postSenderVocalizing ? self.postSenderVocalizing : self.postSender;
    NSString *postSenderPrev = infopoint.postSenderVocalizing ? infopoint.postSenderVocalizing : infopoint.postSender;
    
    if (![postSenderPrev isEqualToString:postSenderNow]) {
        [phrase appendFormat:@"%@ ", postSenderNow];
        
        if ([[self.summary sm_langOfString] isEqualToString:@"ru"]) {
            [phrase appendFormat:@"%@ ", self.phrases[@"report_what"][@"ru"]];
        }
        else {
            [phrase appendFormat:@"%@ ", self.phrases[@"report_what"][@"en"]];
        }
    }
    
    if (self.title.length > 0) {
        [phrase appendFormat:@"%@. ", self.title];
        
        NSString *details = self.phrases[@"details"][[self.summary sm_langOfString]];
        if (details) {
            [phrase appendFormat:@"%@ ", details];
        }
    }
    
    if (self.fullArticle.length > 0 || self.summary.length > 0) {
        NSString *body = @"";
        if (fullArticle && self.fullArticle.length > 0) {
            body = [NSString stringWithFormat:@". %@", self.fullArticle];
        }
        else {
            body = [NSString stringWithFormat:@". %@", self.summary];
        }
        body = [self p_summaryWithReplacedLinks:body];
        [phrase appendString:body];
    }

    return phrase;
}

- (NSString*)p_summaryWithReplacedLinks:(NSString*)summary
{
    NSMutableString *text = [summary mutableCopy];
    NSString *langOfText = [text sm_langOfString];
    NSInteger beforeLength = text.length;
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

- (NSString*)displayingTextForFullArticle:(BOOL)fullArticle
{
    NSMutableString *body = [NSMutableString string];
    if (self.title.length > 0) {
        [body appendString:self.title];
    }

    if (fullArticle && self.fullArticle.length > 0) {
         [body appendFormat:@"\n\n%@", self.fullArticle];
    }
    else {
         [body appendFormat:@"\n\n%@", self.summary];
    }
    
    return body;
}

- (UIImage *)sourceIcon
{
    return [UIImage imageNamed:@"icon_feed_rss"];
}

@end
