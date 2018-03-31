//
//  SMInfopoint.m
//  Speind
//
//  Created by Sergey Butenko on 9/30/14.
//  Copyright (c) 2014 Speaking Mind. All rights reserved.
//

#import "SMInfopoint.h"

static NSString *kPriorityKey = @"PriorityKey";
static NSString *kLangKey = @"LangKey";

static NSString *kTitleKey = @"TitleKey";
static NSString *kLinkKey = @"LinkKey";
static NSString *kSummaryKey = @"SummaryKey";
static NSString *kFullArticleKey = @"FullArticleKey";
static NSString *kPubDateKey = @"PubDateKey";
static NSString *kEnclosureKey = @"EnclosureKey";

static NSString *kPlaceholderKey = @"PlaceholderKey";
static NSString *kPostSenderKey = @"PostSenderKey";
static NSString *kSenderIconKey = @"SenderIconKey";
static NSString *kTextVocalizingKey = @"TextVocalizingKey";
static NSString *kPostSenderVocalizing = @"PostSenderVocalizing";

@interface SMInfopoint ()

@property (nonatomic, readwrite) NSString *placeholder;

@end

@implementation SMInfopoint

@synthesize placeholder = _placeholder;

#pragma mark - Coding

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeInteger:_priority forKey:kPriorityKey];
    [aCoder encodeObject:_lang forKey:kLangKey];
    [aCoder encodeObject:_title forKey:kTitleKey];
    [aCoder encodeObject:_link forKey:kLinkKey];
    [aCoder encodeObject:_summary forKey:kSummaryKey];
    [aCoder encodeObject:_fullArticle forKey:kFullArticleKey];
    [aCoder encodeObject:_pubDate forKey:kPubDateKey];
    [aCoder encodeObject:_enclosure forKey:kEnclosureKey];
    [aCoder encodeObject:_placeholder forKey:kPlaceholderKey];
    [aCoder encodeObject:_postSender forKey:kPostSenderKey];
    [aCoder encodeObject:_senderIcon forKey:kSenderIconKey];
    [aCoder encodeObject:_textVocalizing forKey:kTextVocalizingKey];
    [aCoder encodeObject:_postSenderVocalizing forKey:kPostSenderVocalizing];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self){
        _priority = [aDecoder decodeIntegerForKey:kPriorityKey];
        _title = [aDecoder decodeObjectForKey:kTitleKey];
        _link = [aDecoder decodeObjectForKey:kLinkKey];
        _summary = [aDecoder decodeObjectForKey:kSummaryKey];
        _fullArticle = [aDecoder decodeObjectForKey:kFullArticleKey];
        _pubDate = [aDecoder decodeObjectForKey:kPubDateKey];
        _enclosure = [aDecoder decodeObjectForKey:kEnclosureKey];
        _postSender = [aDecoder decodeObjectForKey:kPostSenderKey];
        _senderIcon = [aDecoder decodeObjectForKey:kSenderIconKey];
        _textVocalizing = [aDecoder decodeObjectForKey:kTextVocalizingKey];
        _postSenderVocalizing = [aDecoder decodeObjectForKey:kPostSenderVocalizing];
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@: %@", [self class], self.title];
}

- (NSString*)vocalizingTextWithPreviuosInfopoint:(SMInfopoint*)infopoint fullArticle:(BOOL)fullArticle
{
    return @"";
}

- (NSString*)displayingTextForFullArticle:(BOOL)fullArticle
{
    if (fullArticle && self.fullArticle.length > 0) {
        return self.fullArticle;
    }
    else {
        return self.summary;
    }
}

- (NSString *)placeholder
{
    if (!_placeholder) {
        _placeholder = @"placeholder";
    }
    return _placeholder;
}


@end
