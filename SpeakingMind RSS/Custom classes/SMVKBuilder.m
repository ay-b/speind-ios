//
//  SMVKBuilder.m
//  SpeakingMind RSS
//
//  Created by Sergey Butenko on 10/22/14.
//  Copyright (c) 2014 Speaking Mind. All rights reserved.
//

#import "SMVKBuilder.h"
#import "SMInfopointVK.h"
#import "SMDefines.h"
#import "NSString+Language.h"
#import "AcapelaSpeech+Speind.h"

#import <VK-ios-sdk/VKApi.h>

#define kWoman @(1)
static const NSInteger kMaxDaysCount = 3;

@interface SMVKBuilder ()

@property NSDictionary *data;
@property (nonatomic) NSDictionary *phrases;

@end

@implementation SMVKBuilder

#pragma mark - Public API

+ (instancetype)sharedBuilder
{
    static SMVKBuilder *builder;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        builder = [SMVKBuilder new];
    });
    return builder;
}

- (NSArray *)infopointsForPosts:(NSDictionary *)answer
{
    self.data = answer;
    
    NSArray *items = answer[@"items"];
    NSMutableArray *infopoints = [NSMutableArray array];
    for (NSDictionary *item in items) {
        if (![self p_skipItem:item]) {
            [infopoints addObject:[self p_infopointForItem:item]];
        }
    }
    
    return [infopoints copy];
}

#pragma mark - Private API

#pragma mark Preparation

- (BOOL)p_skipItem:(NSDictionary*)item
{
    return [self p_isOldItem:item] || ![self p_canSpeakItem:item];
}

- (BOOL)p_canSpeakItem:(NSDictionary*)item
{
    BOOL can = NO;
    NSString *text = item[@"text"];
    NSString *langOfText = [text sm_langOfString];
    for (NSString* locale in [[SMSettings sharedSettings] supportedLocales]) {
        if ([langOfText isEqualToString:locale]) {
            can = YES;
            break;
        }
    }
    return can;
}

- (BOOL)p_isOldItem:(NSDictionary*)item
{
    NSDate *date = [self p_dateForItem:item];
    NSInteger days = [self p_daysBetweenDate:date andDate:[NSDate date]];
    return days > kMaxDaysCount;
}

- (SMInfopointVK*)p_infopointForItem:(NSDictionary*)item
{
    SMInfopointVK *infopoint = [SMInfopointVK new];
    
    infopoint.pubDate = [self p_dateForItem:item];
    infopoint.textVocalizing = [self p_sentenceForItem:item];
    infopoint.summary = [self p_textForItem:item];
    infopoint.title = [self p_titleForItem:item];
    infopoint.senderIcon = [self p_senderIconForItem:item];
    infopoint.postSender = [self p_titleForItem:item];
    infopoint.priority = SMDefaultInfopointPriority;
    infopoint.enclosure = [self p_previewImageForItem:item];
    infopoint.link = [self p_linkForItem:item];
    
    return infopoint;
}

#pragma mark Processing

- (NSDate*)p_dateForItem:(NSDictionary*)item
{
    NSTimeInterval interval = [item[@"date"] doubleValue];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:interval];
    return date;
}

- (NSString*)p_previewImageForItem:(NSDictionary*)item
{
    NSArray *attachments = item[@"attachments"];
    for (NSDictionary *attachment in attachments) {
        if ([attachment[@"type"] isEqualToString:@"photo"]) {
            return attachment[@"photo"][@"photo_604"];
        }
    }
    
    return @"";
}

- (NSString*)p_linkForItem:(NSDictionary*)item
{
    NSArray *attachments = item[@"attachments"];
    for (NSDictionary *attachment in attachments) {
        if ([attachment[@"type"] isEqualToString:@"link"]) {
            return attachment[@"link"][@"url"];
        }
    }
    
    NSMutableString *text = [item[@"text"] mutableCopy];
    if (!text) {
        return @"";
    }
    NSDataDetector* detector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:nil];
    NSArray *linksMatches = [detector matchesInString:text options:0 range:NSMakeRange(0, [text length])];
    for (NSTextCheckingResult *match in linksMatches) {
        if (match.range.location != NSNotFound && match.range.length > 0) {
            NSRange range = match.range;
            return [text substringWithRange:range];
        }
    }

    return @"";
}

- (NSString*)p_textForItem:(NSDictionary*)item
{
    return [self p_prepareTextForItem:item];
}

- (NSString*)p_titleForItem:(NSDictionary*)item
{
    NSInteger sourceId = [item[@"source_id"] integerValue];
    if (sourceId > 0) {
        VKUser *sourceUser = [self p_infoForProfileID:sourceId];
        return [NSString stringWithFormat:@"%@ %@", sourceUser.first_name, sourceUser.last_name];
    }
    else {
        VKGroup *sourceGroup = [self p_infoForGroudID:sourceId];
        return [NSString stringWithFormat:@"%@", sourceGroup.name];
    }
    return @"";
}

- (NSString*)p_senderIconForItem:(NSDictionary*)item
{
    NSInteger sourceId = [item[@"source_id"] integerValue];
    if (sourceId > 0) {
        VKUser *sourceUser = [self p_infoForProfileID:sourceId];
        return sourceUser.photo_100;
    }
    else {
        VKGroup *sourceGroup = [self p_infoForGroudID:sourceId];
        return sourceGroup.photo_100;
    }
    return @"";
}

- (VKGroup*)p_infoForGroudID:(NSInteger)groupID
{
    groupID = ABS(groupID);
    NSArray *groups = self.data[@"groups"];
    for (NSDictionary *group in groups) {
        VKGroup *vkgroup = [[VKGroup alloc] initWithDictionary:group];
        if ([vkgroup.id isEqualToNumber:@(groupID)]) {
            return vkgroup;
        }
    }
    
    return nil;
}

- (VKUser*)p_infoForProfileID:(NSInteger)userID
{
    NSArray *users = self.data[@"profiles"];
    for (NSDictionary *user in users) {
        VKUser *vkuser = [[VKUser alloc] initWithDictionary:user];
        if ([vkuser.id isEqualToNumber:@(userID)]) {
            return vkuser;
        }
    }
    
    return nil;
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

#pragma mark Vocalizing

- (NSString*)p_sentenceForItem:(NSDictionary*)item
{
    NSInteger sourceId = [item[@"source_id"] integerValue];
    NSMutableString *str = [NSMutableString string];
    NSString *text = [self p_prepareTextForItem:item];
    
    if ([item[@"type"] isEqualToString:@"post"] && item[@"copy_history"]) { // repost
        NSInteger ownerId = [item[@"copy_history"][0][@"owner_id"] integerValue];
        
        if (sourceId > 0) {
            VKUser *sourceUser = [self p_infoForProfileID:sourceId];
            
            if ([sourceUser.sex isEqualToNumber:kWoman]) {
                if (ownerId > 0) {
                    VKUser *ownerUser = [self p_infoForProfileID:ownerId];
                    [str appendFormat:@"%@ %@ %@ %@ %@ %@", sourceUser.first_name, sourceUser.last_name, self.phrases[@"w_quotes"][@"ru"], self.phrases[@"of_user"][@"ru"], ownerUser.first_name, ownerUser.last_name];
                    //<имя_автора_репоста> |w_quotes| |of_user| <имя_автора_оригинального_поста>
                }
                else {
                    VKGroup *ownerGroup = [self p_infoForGroudID:ownerId];
                    [str appendFormat:@"%@ %@ %@ %@ %@", sourceUser.first_name, sourceUser.last_name, self.phrases[@"w_quotes"][@"ru"], self.phrases[@"of_group"][@"ru"], ownerGroup.name];
                    // <имя_автора_репоста> |w_quotes| |of_group| <имя_автора_оригинального_поста>
                }
            }
            else {
                if (ownerId > 0) {
                    VKUser *ownerUser = [self p_infoForProfileID:ownerId];
                    [str appendFormat:@"%@ %@ %@ %@ %@ %@", sourceUser.first_name, sourceUser.last_name, self.phrases[@"quotes"][@"ru"], self.phrases[@"of_user"][@"ru"], ownerUser.first_name, ownerUser.last_name];
                    //<имя_автора_репоста> |quotes| |of_user| <имя_автора_оригинального_поста>
                }
                else {
                    VKGroup *ownerGroup = [self p_infoForGroudID:ownerId];
                    [str appendFormat:@"%@ %@ %@ %@ %@", sourceUser.first_name, sourceUser.last_name, self.phrases[@"quotes"][@"ru"], self.phrases[@"of_group"][@"ru"], ownerGroup.name];
                    //<имя_автора_репоста> |quotes| |of_group| <имя_автора_оригинального_поста>
                }
            }
        }
        else {
            VKGroup *sourceGroup = [self p_infoForGroudID:sourceId];
            if (ownerId > 0) {
                VKUser *ownerUser = [self p_infoForProfileID:ownerId];
                [str appendFormat:@"%@ %@ %@ %@ %@", self.phrases[@"in_group"][@"ru"], sourceGroup.name, self.phrases[@"of_user1"][@"ru"], ownerUser.first_name, ownerUser.last_name];
                //|in_group| <имя_автора_репоста> |of_user1| <имя_автора_оригинального_поста>
            }
            else {
                VKGroup *ownerGroup = [self p_infoForGroudID:ownerId];
                [str appendFormat:@"%@ %@ %@ %@", self.phrases[@"in_group"][@"ru"], sourceGroup.name, self.phrases[@"of_group1"][@"ru"], ownerGroup.name];
                // |in_group| <имя_автора_репоста> |of_group1| <имя_автора_оригинального_поста>
            }
        }
        
        if (text.length > 0) {
            [str appendFormat:@" %@ %@", self.phrases[@"with_label"][@"ru"], text];
            //[] [|with_label| <текст поста>]
        }
        
        NSString *originalText = item[@"copy_history"][0][@"text"];
        if (originalText.length > 0) {
            [str appendFormat:@" %@ %@", self.phrases[@"original_post_text"][@"ru"], originalText];
            // [|original_post_text| <текст оригинального поста>]
        }
    }
    else if ([item[@"type"] isEqualToString:@"post"]) { // post
        if (sourceId > 0) {
            VKUser *user = [self p_infoForProfileID:sourceId];
            [str appendFormat:@"%@ %@", user.first_name, user.last_name];
            
            if ([user.sex isEqualToNumber:kWoman]) {
                [str appendFormat:@" %@", self.phrases[@"w_write"][@"ru"]];
            }
            else {
                [str appendFormat:@" %@", self.phrases[@"write"][@"ru"]];
            }
        }
        else {
            VKGroup *group = [self p_infoForGroudID:sourceId];
            [str appendFormat:@"%@ %@", self.phrases[@"new_post_in_group"][@"ru"], group.name];
        }
        
        if ([text length] > 0) {
            [str appendFormat:@". %@ ", text];
        }
    }
    else if ([item[@"type"] isEqualToString:@"photo"]) { // photo
        if (sourceId > 0) {
            VKUser *user = [self p_infoForProfileID:sourceId];
            [str appendFormat:@"%@ %@ ", user.first_name, user.last_name];
            
            if ([user.sex isEqualToNumber:kWoman]) { // woman
                [str appendFormat:@"%@ ", self.phrases[@"w_posted_photo"][@"ru"]];
            }
            else {
                [str appendFormat:@"%@ ", self.phrases[@"posted_photo"][@"ru"]];
            }
        }
        else {
            VKGroup *group = [self p_infoForGroudID:sourceId];
            [str appendFormat:@" %@ %@ ", self.phrases[@"new_photo_group"][@"ru"], group.name];
        }
    }
    
    return [str copy];
}

- (NSString*)p_prepareTextForItem:(NSDictionary*)item
{
    NSMutableString *text = [item[@"text"] mutableCopy];
    if (!text) {
        return @"";
    }
    NSInteger beforeLength;
    
    // change navite vk mentions [id|name] -> name
    beforeLength = text.length;
    NSRegularExpression *mentionRegex = [NSRegularExpression regularExpressionWithPattern:@"\\[.*?\\|(.*?)\\]" options:NSRegularExpressionCaseInsensitive error:nil];
    NSArray *mentionsMatches = [mentionRegex matchesInString:text options:0 range:NSMakeRange(0, [text length])];
    for (NSTextCheckingResult *match in mentionsMatches) {
        if (match.range.location != NSNotFound && match.range.length > 0) {
            NSRange range = match.range;
            range.location -= beforeLength - text.length;
            NSArray *components = [text componentsSeparatedByString:@"|"];
            NSString *name = [components lastObject];
            name = [name stringByReplacingOccurrencesOfString:@"]" withString:@""];
            name = [name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            
            [text replaceCharactersInRange:range withString:name];
        }
    }
    
    // remove hashtags
    beforeLength = text.length;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"#\\S+" options:NSRegularExpressionCaseInsensitive error:nil];
    NSArray *hashtagsMatches = [regex matchesInString:text options:0 range:NSMakeRange(0, [text length])];
    for (NSTextCheckingResult *match in hashtagsMatches) {
        if (match.range.location != NSNotFound && match.range.length > 0) {
            NSRange range = match.range;
            range.location -= beforeLength - text.length;
            [text replaceCharactersInRange:range withString:@""];
        }
    }
    
    // replace links
    NSString *langOfText = [text sm_langOfString];
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

#pragma mark - Properties

- (NSDictionary *)phrases
{
    if (!_phrases) {
        _phrases = @{@"w_quotes" : @{
                             @"ru" : @"сделала репост",
                             @"en" : @"reposted",
                             @"fr" : @"",
                             @"es" : @""},
                     @"quotes" : @{
                             @"ru" : @"сделал репост",
                             @"en" : @"reposted",
                             @"fr" : @"",
                             @"es" : @""},
                     @"of_user" : @{
                             @"ru" : @"пользователя",
                             @"en" : @"user",
                             @"fr" : @"",
                             @"es" : @""},
                     @"of_group" : @{
                             @"ru" : @"группы",
                             @"en" : @"a post from a group",
                             @"fr" : @"",
                             @"es" : @""},
                     @"with_label" : @{
                             @"ru" : @"с пометкой",
                             @"en" : @"with a comment",
                             @"fr" : @"",
                             @"es" : @""},
                     @"original_post_text" : @{
                             @"ru" : @"Текст оригинального поста",
                             @"en" : @"The original post is",
                             @"fr" : @"",
                             @"es" : @""},
                     @"in_group" : @{
                             @"ru" : @"В группе",
                             @"en" : @"New repost in a",
                             @"fr" : @"",
                             @"es" : @""},
                     @"of_user1" : @{
                             @"ru" : @"репост пользователя",
                             @"en" : @"of the user",
                             @"fr" : @"",
                             @"es" : @""},
                     @"of_group1" : @{
                             @"ru" : @"репост группы",
                             @"en" : @"of the group",
                             @"fr" : @"",
                             @"es" : @""},
                     @"w_write" : @{
                             @"ru" : @"добавила новый пост",
                             @"en" : @"made a post",
                             @"fr" : @""},
                     @"write" : @{
                             @"ru" : @"добавил новый пост",
                             @"en" : @"made a post",
                             @"fr" : @"",
                             @"es" : @""},
                     @"new_post_in_group" : @{
                             @"ru" : @"Новый пост в группе",
                             @"en" : @"New post in a group",
                             @"fr" : @"",
                             @"es" : @""},
                     @"w_posted_photo" : @{
                             @"ru" : @"добавила фотографию",
                             @"en" : @"has posted a photo",
                             @"fr" : @"",
                             @"es" : @""},
                     @"posted_photo" : @{
                             @"ru" : @"добавил фотографию",
                             @"en" : @"has posted a photo",
                             @"fr" : @""},
                     @"new_photo_group" : @{
                             @"ru" : @"Новая фотография в группе",
                             @"en" : @"There is a new photo at the group",
                             @"fr" : @"",
                             @"es" : @""},
                     @"link" : @{
                             @"ru": @"ссылка на веб-сайт",
                             @"en": @"external website link",
                             @"fr": @"",
                             @"es" : @""}
                     };
    }
    return _phrases;
}

@end
