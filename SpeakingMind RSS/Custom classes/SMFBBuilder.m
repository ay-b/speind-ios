//
//  SMFBBuilder.m
//  Speind
//
//  Created by Sergey Butenko on 3/7/15.
//  Copyright (c) 2015 Speaking Mind. All rights reserved.
//

#import "SMFBBuilder.h"
#import "NSString+Language.h"
#import "AcapelaSpeech+Speind.h"
#import "SMInfopointFB.h"

#import <Facebook-iOS-SDK/FacebookSDK/FBOpenGraphObject.h>
#import <Facebook-iOS-SDK/FacebookSDK/FBOpenGraphAction.h>
#import <Facebook-iOS-SDK/FacebookSDK/FBGraphUser.h>

static const NSInteger kMaxDaysCount = 3;

@interface SMFBBuilder ()

@property (nonatomic, strong) NSDictionary *phrases;
@property FBGraphObject<FBOpenGraphAction> *currentItem;

@end

@implementation SMFBBuilder

+ (instancetype)sharedBuilder
{
    static SMFBBuilder *builder;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        builder = [SMFBBuilder new];
    });
    return builder;
}

/**
 * Converts FBGraphObject data to infopoint.
 *
 * @return Array of SMInfopointFB objects.
 *
 */
- (NSArray*)infopointsForPosts:(NSDictionary<FBGraphObject>*)graph
{
    FBGraphObject *posts = graph[@"data"];
    NSMutableArray *infopoints = [NSMutableArray array];
    
    for (FBGraphObject<FBOpenGraphAction> *post in posts) {
        self.currentItem = post;
        
        if ([self p_skipItem:post]) {
            continue;
        }
        SMInfopoint *item = [self p_infopointForItem:post];
        if ([self p_canSpeakItemWithLang:item.lang]) {
            [infopoints addObject:item];
        }
    }
    return infopoints;
}

#pragma mark - Private API

#pragma mark Preparation

- (BOOL)p_skipItem:(NSDictionary<FBOpenGraphAction>*)item
{
//    return NO;
//    return [self p_isOldItem:item] || ![self p_canSpeakItem:item] || ![self p_isAcceptableStatusItem:item];
    return [self p_isOldItem:item] || ![self p_isAcceptableStatusItem:item];
}

- (BOOL)p_canSpeakItem:(NSDictionary<FBOpenGraphAction>*)item
{
    BOOL can = NO;
    NSString *text = [self p_textForItem:item];
    NSString *langOfText = [text sm_langOfString];
    for (SMLanguage* lang in [AcapelaSpeech availableLanguages]) {
        if ([lang.shortLocale isEqualToString:langOfText]) {
            can = YES;
            break;
        }
    }
    return can;
}

- (BOOL)p_canSpeakItemWithLang:(NSString*)langOfText
{
    BOOL can = NO;
    for (SMLanguage* lang in [AcapelaSpeech availableLanguages]) {
        if ([lang.shortLocale isEqualToString:langOfText]) {
            can = YES;
            break;
        }
    }
    NSLog(@"<%@> cannot", langOfText);
    
    return can;
}


- (BOOL)p_isOldItem:(NSDictionary<FBOpenGraphAction>*)item
{
    NSDate *date = [self p_dateForItem:item];
    NSInteger days = [self p_daysBetweenDate:date andDate:[NSDate date]];
    NSLog(@"Days: %@", @(days));
    return days > kMaxDaysCount;
}

- (BOOL)p_isAcceptableStatusItem:(NSDictionary<FBOpenGraphAction>*)item
{
    NSLog(@"Type: %@", item[@"status_type"]);
    
    NSArray *statuses = @[@"mobile_status_update", @"added_photos", @"added_video", @"shared_story", @"app_created_story", @"published_story"];
    return [statuses containsObject:item[@"status_type"]];
}

- (NSDate*)p_dateForItem:(NSDictionary<FBOpenGraphAction>*)item
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
    NSDate *dateUTC =  [dateFormatter dateFromString:item[@"created_time"]];

    NSTimeInterval timeZoneSeconds = [[NSTimeZone localTimeZone] secondsFromGMT];
    NSDate *date = [dateUTC dateByAddingTimeInterval:timeZoneSeconds];
    
    return date;
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

- (SMInfopointFB*)p_infopointForItem:(NSDictionary<FBOpenGraphAction>*)item
{
    SMInfopointFB *infopoint = [SMInfopointFB new];
    
    infopoint.pubDate = [self p_dateForItem:item];
//    infopoint.textVocalizing = [self p_textVocalizingForItem:item];
//    infopoint.summary = [self p_textForItem:item];
//    infopoint.title = [self p_titleForItem:item];
//    infopoint.postSender = [self p_postSenderForItem:item];
    infopoint.senderIcon = [self p_senderIconForItem:item];
    infopoint.priority = SMDefaultInfopointPriority;
    infopoint.enclosure = [self p_previewImageForItem:item];
    infopoint.link = [self p_linkForItem:item];
    
    NSString *lang;
    NSString *type = item[@"status_type"];
    if ([type isEqualToString:@"mobile_status_update"]) {
        NSString *message = item[@"message"];
        lang = [message sm_langOfString];
        NSString *user = item[@"from"][@"id"];
        if ([lang isEqualToString:item[@"from"][@"name"]]) {
            user =  item[@"from"][@"name"];
        }

        // DISPLAYING
        NSString *sender = item[@"story"];
        if (!sender) {
            sender = item[@"from"][@"name"];
        }
        infopoint.postSender = sender;
        infopoint.title = @"";
        infopoint.summary = message;
        
        // VOCALIZING
        NSMutableString *phrase = [NSMutableString string];
        [phrase appendFormat:@"%@ %@. %@: %@", self.phrases[@"new_status"][lang], [self p_usernameForItem:item], self.phrases[@"status_text"][lang], [self p_textForItem:item]];
        infopoint.textVocalizing = phrase;
    }
    else if ([type isEqualToString:@"added_photos"]) {
        NSString *message = item[@"message"];
        lang = [message sm_langOfString];
        NSString *user = item[@"from"][@"id"];
        if ([lang isEqualToString:item[@"from"][@"name"]]) {
            user =  item[@"from"][@"name"];
        }
        
        // DISPLAYING
        NSString *sender = item[@"story"];
        if (!sender) {
            sender = item[@"from"][@"name"];
        }
        infopoint.postSender = sender;
        infopoint.title = @"";
        infopoint.summary = message;
        
        
        // VOCALIZING
        NSMutableString *phrase = [NSMutableString string];
        [phrase appendFormat:@"%@ %@. ", self.phrases[@"new_photo_from"][lang], [self p_usernameForItem:item]];
        NSString *comment = [self p_textForItem:item];
        if (comment) {
            [phrase appendFormat:@"%@: %@", self.phrases[@"with_comment"][lang], comment];
        }
        infopoint.textVocalizing = phrase;
    }
    else if ([type isEqualToString:@"added_video"]) {
        NSString *message = item[@"message"];
        lang = [message sm_langOfString];
        NSString *user = item[@"from"][@"id"];
        if ([lang isEqualToString:item[@"from"][@"name"]]) {
            user =  item[@"from"][@"name"];
        }
        
        // DISPLAYING
        NSString *sender = item[@"story"];
        if (!sender) {
            sender = item[@"from"][@"name"];
        }
        infopoint.postSender = sender;
        infopoint.title = @"";
        infopoint.summary = message;
        
        
        // VOCALIZING
        NSMutableString *phrase = [NSMutableString string];
        [phrase appendFormat:@"%@ %@. ", self.phrases[@"new_video_from"][lang], [self p_usernameForItem:item]];
        
        NSString *comment = [self p_textForItem:item];
        if (comment) {
            [phrase appendFormat:@"%@: %@", self.phrases[@"with_comment"][lang], comment];
        }
        infopoint.textVocalizing = phrase;
    }
    else if ([type isEqualToString:@"shared_story"]) {
        NSString *type = item[@"type"];
        if ([type isEqualToString:@"link"]) {
            NSString *message = item[@"message"];
            NSString *title = item[@"name"];
            NSString *details = item[@"description"];
            NSString *sourceName = item[@"application"][@"name"];
            lang = [[NSString stringWithFormat:@"%@ %@ %@", item[@"message"], item[@"name"], details] sm_langOfString];
            NSString *user = item[@"from"][@"id"];
            if ([lang isEqualToString:item[@"from"][@"name"]]) {
                user =  item[@"from"][@"name"];
            }
            
            // DISPLAYING
            NSString *sender;
            if (item[@"story"]) {
                sender = item[@"from"][@"name"];
            }
            else {
                sender = [NSString stringWithFormat:@"%@ %@ %@", user, self.phrases[@"via"][lang], sourceName];
            }
            infopoint.postSender = sender;
            infopoint.title = item[@"message"];
            
            NSString *summary = item[@"caption"];
            if (!summary) {
                summary = [NSString stringWithFormat:@"%@ %@", item[@"name"], item[@"description"]];
            }
            infopoint.summary = summary;
            
            // VOCALIZING
            NSMutableString *vocalizing = [NSMutableString stringWithFormat:@"%@ %@. ", self.phrases[@"link_from"][lang], user];
            if (message) {
                [vocalizing appendFormat:@"%@: %@ ", self.phrases[@"with_comment"][lang], message];
            }
            if (title) {
                [vocalizing appendFormat:@"%@: %@ ", self.phrases[@"title"][lang], title];
            }
            if (details) {
                [vocalizing appendFormat:@"%@: %@ ", self.phrases[@"details"][lang], details];
            }
            infopoint.textVocalizing = [vocalizing copy];
        }
        else if ([type isEqualToString:@"photo"]) {
            NSString *message = item[@"message"];
            NSString *title = item[@"caption"];
            if (!title) {
                title = item[@"name"];
            }
            NSString *details = item[@"description"];
            NSString *sourceName = item[@"application"][@"name"];
            lang = [[NSString stringWithFormat:@"%@ %@ %@", message, title, details] sm_langOfString];
            NSString *user = item[@"from"][@"id"];
            if ([lang isEqualToString:item[@"from"][@"name"]]) {
                user =  item[@"from"][@"name"];
            }
            
            // DISPLAYING
            NSString *sender;
            if (item[@"story"]) {
                sender = item[@"from"][@"name"];
            }
            else {
                sender = [NSString stringWithFormat:@"%@ %@ %@", user, self.phrases[@"via"][lang], sourceName];
            }
            infopoint.postSender = sender;
            infopoint.title = item[@"message"];
            
            NSString *summary = item[@"caption"];
            if (!summary) {
                summary = [NSString stringWithFormat:@"%@ %@", item[@"name"], item[@"description"]];
            }
            infopoint.summary = summary;
            
            // VOCALIZING
            NSMutableString *vocalizing = [NSMutableString stringWithFormat:@"%@ %@. ", self.phrases[@"photo_from"][lang], user];
            if (message) {
                [vocalizing appendFormat:@"%@: %@ ", self.phrases[@"with_comment"][lang], message];
            }
            if (title) {
                [vocalizing appendFormat:@"%@: %@ ", self.phrases[@"title"][lang], title];
            }
            if (details) {
                [vocalizing appendFormat:@"%@: %@ ", self.phrases[@"details"][lang], details];
            }
            infopoint.textVocalizing = [vocalizing copy];
        }
        else if ([type isEqualToString:@"video"]) {
            NSString *message = item[@"message"];
            NSString *title = item[@"caption"];
            if (!title) {
                title = item[@"name"];
            }
            NSString *details = item[@"description"];
            NSString *sourceName = item[@"application"][@"name"];
            lang = [[NSString stringWithFormat:@"%@ %@ %@", message, title, details] sm_langOfString];
            NSString *user = item[@"from"][@"id"];
            if ([lang isEqualToString:item[@"from"][@"name"]]) {
                user =  item[@"from"][@"name"];
            }
            
            // DISPLAYING
            NSString *sender;
            if (item[@"story"]) {
                sender = item[@"from"][@"name"];
            }
            else {
                sender = [NSString stringWithFormat:@"%@ %@ %@", user, self.phrases[@"via"][lang], sourceName];
            }
            infopoint.postSender = sender;
            infopoint.title = item[@"message"];
            
            NSString *summary = item[@"caption"];
            if (!summary) {
                summary = [NSString stringWithFormat:@"%@ %@", item[@"name"], item[@"description"]];
            }
            infopoint.summary = summary;
            
            // VOCALIZING
            NSMutableString *vocalizing = [NSMutableString stringWithFormat:@"%@ %@. ", self.phrases[@"video_from"][lang], user];
            
            if (message) {
                [vocalizing appendFormat:@"%@: %@ ", self.phrases[@"with_comment"][lang], message];
            }
            if (title) {
                [vocalizing appendFormat:@"%@: %@ ", self.phrases[@"title"][lang], title];
            }
            if (details) {
                [vocalizing appendFormat:@"%@: %@ ", self.phrases[@"details"][lang], details];
            }
            infopoint.textVocalizing = [vocalizing copy];
        }
    }
    
    else if ([type isEqualToString:@"app_created_story"] || [type isEqualToString:@"published_story"]) {
        NSString *type = item[@"type"];
        if ([type isEqualToString:@"link"]) {
            NSString *message = item[@"message"];
            NSString *title = item[@"name"];
            NSString *details = item[@"description"];
            NSString *sourceName = item[@"application"][@"name"];
            lang = [[NSString stringWithFormat:@"%@ %@ %@", item[@"message"], item[@"name"], details] sm_langOfString];
            NSString *user = item[@"from"][@"id"];
            if ([lang isEqualToString:item[@"from"][@"name"]]) {
                user =  item[@"from"][@"name"];
            }
            
            // DISPLAYING
            NSString *sender;
            if (item[@"story"]) {
                sender = item[@"from"][@"name"];
            }
            else {
                sender = [NSString stringWithFormat:@"%@ %@ %@", user, self.phrases[@"via"][lang], sourceName];
            }
            infopoint.postSender = sender;
            infopoint.title = item[@"message"];
            
            NSString *summary = item[@"caption"];
            if (!summary) {
                summary = [NSString stringWithFormat:@"%@ %@", item[@"name"], item[@"description"]];
            }
            infopoint.summary = summary;
            
            // VOCALIZING
            NSMutableString *vocalizing = [NSMutableString stringWithFormat:@"%@ %@. ", self.phrases[@"link_from"][lang], user];
            if (message) {
                [vocalizing appendFormat:@"%@: %@ ", self.phrases[@"with_comment"][lang], message];
            }
            if (title) {
                [vocalizing appendFormat:@"%@: %@ ", self.phrases[@"title"][lang], title];
            }
            if (details) {
                [vocalizing appendFormat:@"%@: %@ ", self.phrases[@"details"][lang], details];
            }
            infopoint.textVocalizing = [vocalizing copy];
        }
        else if ([type isEqualToString:@"status"]) {
            NSString *message = item[@"message"];
            NSString *sourceName = item[@"application"][@"name"];
            lang = [item[@"message"] sm_langOfString];
            NSString *user = item[@"from"][@"id"];
            if ([lang isEqualToString:item[@"from"][@"name"]]) {
                user =  item[@"from"][@"name"];
            }
            
            // DISPLAYING
            NSString *sender;
            if (item[@"story"]) {
                sender = item[@"from"][@"name"];
            }
            else {
                sender = [NSString stringWithFormat:@"%@ %@ %@", user, self.phrases[@"via"][lang], sourceName];
            }
            infopoint.postSender = sender;
            infopoint.title = @"";
            infopoint.summary = item[@"message"];
            
            // VOCALIZING
            NSMutableString *vocalizing = [NSMutableString stringWithFormat:@"%@ %@ %@ %@. ", self.phrases[@"post_from"][lang], user, self.phrases[@"via"][lang], sourceName];
            if (message) {
                [vocalizing appendFormat:@"%@: %@ ", self.phrases[@"post_text"][lang], message];
            }
            infopoint.textVocalizing = [vocalizing copy];

        }
        else if ([type isEqualToString:@"photo"]) {
            NSString *message = item[@"message"];
            NSString *title = item[@"caption"];
            if (!title) {
                title = item[@"name"];
            }
            NSString *details = item[@"description"];
            NSString *sourceName = item[@"application"][@"name"];
            lang = [[NSString stringWithFormat:@"%@ %@ %@", message, title, details] sm_langOfString];
            NSString *user = item[@"from"][@"id"];
            if ([lang isEqualToString:item[@"from"][@"name"]]) {
                user =  item[@"from"][@"name"];
            }
            
            // DISPLAYING
            NSString *sender;
            if (item[@"story"]) {
                sender = item[@"from"][@"name"];
            }
            else {
                sender = [NSString stringWithFormat:@"%@ %@ %@", user, self.phrases[@"via"][lang], sourceName];
            }
            infopoint.postSender = sender;
            infopoint.title = item[@"message"];
            
            NSString *summary = item[@"caption"];
            if (!summary) {
                summary = [NSString stringWithFormat:@"%@ %@", item[@"name"], item[@"description"]];
            }
            infopoint.summary = summary;
            
            // VOCALIZING
            NSMutableString *vocalizing = [NSMutableString stringWithFormat:@"%@ %@ %@ %@. ", self.phrases[@"photo_from"][lang], user, self.phrases[@"via"][lang], sourceName];
            if (message) {
                [vocalizing appendFormat:@"%@: %@ ", self.phrases[@"with_comment"][lang], message];
            }
            if (title) {
                [vocalizing appendFormat:@"%@: %@ ", self.phrases[@"title"][lang], title];
            }
            if (details) {
                [vocalizing appendFormat:@"%@: %@ ", self.phrases[@"details"][lang], details];
            }
            infopoint.textVocalizing = [vocalizing copy];
        }
        else if ([type isEqualToString:@"video"]) {
            NSString *message = item[@"message"];
            NSString *title = item[@"caption"];
            if (!title) {
                title = item[@"name"];
            }
            NSString *details = item[@"description"];
            NSString *sourceName = item[@"application"][@"name"];
            lang = [[NSString stringWithFormat:@"%@ %@ %@", message, title, details] sm_langOfString];
            NSString *user = item[@"from"][@"id"];
            if ([lang isEqualToString:item[@"from"][@"name"]]) {
                user =  item[@"from"][@"name"];
            }
            
            // DISPLAYING
            NSString *sender;
            if (item[@"story"]) {
                sender = item[@"from"][@"name"];
            }
            else {
                sender = [NSString stringWithFormat:@"%@ %@ %@", user, self.phrases[@"via"][lang], sourceName];
            }
            infopoint.postSender = sender;
            infopoint.title = item[@"message"];
            
            NSString *summary = item[@"caption"];
            if (!summary) {
                summary = [NSString stringWithFormat:@"%@ %@", item[@"name"], item[@"description"]];
            }
            infopoint.summary = summary;
            
            // VOCALIZING
            NSMutableString *vocalizing = [NSMutableString stringWithFormat:@"%@ %@ %@ %@. ", self.phrases[@"video_from"][lang], user, self.phrases[@"via"][lang], sourceName];
            
            if (message) {
                [vocalizing appendFormat:@"%@: %@ ", self.phrases[@"with_comment"][lang], message];
            }
            if (title) {
                [vocalizing appendFormat:@"%@: %@ ", self.phrases[@"title"][lang], title];
            }
            if (details) {
                [vocalizing appendFormat:@"%@: %@ ", self.phrases[@"details"][lang], details];
            }
            infopoint.textVocalizing = [vocalizing copy];
        }
    }
    infopoint.lang = lang;
    
    return infopoint;
}

#pragma mark Processing

- (NSString*)p_textForItem:(NSDictionary<FBOpenGraphAction>*)item
{
    return item[@"message"];
}

- (NSString*)p_titleForItem:(NSDictionary<FBOpenGraphAction>*)item
{
    NSString *title = @"";
    NSString *type = item[@"status_type"];
    if ([type isEqualToString:@"mobile_status_update"]) {
        
    }
    else if ([type isEqualToString:@"added_photos"]) {
        
    }
    else if ([type isEqualToString:@"added_video"]) {
        
    }
    else if ([type isEqualToString:@"shared_story"]) {
        
    }
    else if ([type isEqualToString:@"app_created_story"]) {
        
    }
    
    return title;
}

- (NSString*)p_textVocalizingForItem:(NSDictionary<FBOpenGraphAction>*)item
{
    NSMutableString *phrase = [NSMutableString string];
    NSString *lang = [[self p_textForItem:item] sm_langOfString];
    
    NSString *type = item[@"status_type"];
    if ([type isEqualToString:@"mobile_status_update"]) {
        [phrase appendFormat:@"%@ %@. %@: %@", self.phrases[@"new_status"][lang], [self p_usernameForItem:item], self.phrases[@"status_text"][lang], [self p_textForItem:item]];
    }
    else if ([type isEqualToString:@"added_photos"]) {
        [phrase appendFormat:@"%@ %@. ", self.phrases[@"new_photo_from"][lang], [self p_usernameForItem:item]];
    
        NSString *comment = [self p_textForItem:item];
        if (comment) {
            [phrase appendFormat:@"%@: %@", self.phrases[@"with_comment"][lang], comment];
        }
    }
    else if ([type isEqualToString:@"added_video"]) {
        [phrase appendFormat:@"%@ %@. ", self.phrases[@"new_video_from"][lang], [self p_usernameForItem:item]];
        
        NSString *comment = [self p_textForItem:item];
        if (comment) {
            [phrase appendFormat:@"%@: %@", self.phrases[@"with_comment"][lang], comment];
        }
    }
    else if ([type isEqualToString:@"shared_story"]) {
        NSString *type = item[@"type"];
        if ([type isEqualToString:@"link"]) {
            
        }
        else if ([type isEqualToString:@"photo"]) {
            
        }
        else if ([type isEqualToString:@"video"]) {
            
        }
    }
    else if ([type isEqualToString:@"app_created_story"]) {
        NSString *type = item[@"type"];
        if ([type isEqualToString:@"link"]) {
            
        }
        else if ([type isEqualToString:@"status"]) {
            
        }
        else if ([type isEqualToString:@"photo"]) {
            
        }
        else if ([type isEqualToString:@"video"]) {
            
        }
    }
    return phrase;
}

- (NSString*)p_senderIconForItem:(NSDictionary<FBOpenGraphAction>*)item
{
    return item[@"icon"];
}

- (NSString*)p_postSenderForItem:(NSDictionary<FBOpenGraphAction>*)item
{
    NSString *sender;
    if (item[@"story"]) {
        sender = item[@"story"];
    }
    else {
        sender = item[@"from"][@"name"];
    }
    
    return sender;
}

- (NSString*)p_usernameForItem:(NSDictionary<FBOpenGraphAction>*)item
{
    return item[@"from"][@"name"];
}

- (NSString*)p_previewImageForItem:(NSDictionary<FBOpenGraphAction>*)item
{
    return item[@"picture"];
}

- (NSString*)p_linkForItem:(NSDictionary<FBOpenGraphAction>*)item
{
    return item[@"link"];
}

#pragma mark - Properties

- (NSDictionary *)phrases
{
    if (!_phrases) {
        _phrases = @{@"new_status" : @{
                             @"ru" : @"Новый статус",
                             @"en" : @"New status",
                             @"fr" : @"",
                             @"es" : @""},
                     @"status_text" : @{
                             @"ru" : @"Текст статуса",
                             @"en" : @"Status text is",
                             @"fr" : @"",
                             @"es" : @""},
                     @"new_photo_from" : @{
                             @"ru" : @"Новое фото от",
                             @"en" : @"New photo by",
                             @"fr" : @"",
                             @"es" : @""},
                     @"with_comment" : @{
                             @"ru" : @"С комментарием",
                             @"en" : @"With a comment",
                             @"fr" : @"",
                             @"es" : @""},
                     @"new_video_from" : @{
                             @"ru" : @"Новое видео от",
                             @"en" : @"New video by",
                             @"fr" : @"",
                             @"es" : @""},
                     @"link_from" : @{
                             @"ru" : @"Ссылка от",
                             @"en" : @"New link by",
                             @"fr" : @"",
                             @"es" : @""},
                     @"title" : @{
                             @"ru" : @"Заголовок",
                             @"en" : @"Caption",
                             @"fr" : @"",
                             @"es" : @""},
                     @"details" : @{
                             @"ru" : @"Подробнее",
                             @"en" : @"Details",
                             @"fr" : @"",
                             @"es" : @""},
                     @"photo_from" : @{
                             @"ru" : @"Фото от",
                             @"en" : @"Photo by",
                             @"fr" : @"",
                             @"es" : @""},
                     @"video_from" : @{
                             @"ru" : @"Видео от",
                             @"en" : @"Video by",
                             @"fr" : @""},
                     @"via" : @{
                             @"ru" : @"через",
                             @"en" : @"via",
                             @"fr" : @"",
                             @"es" : @""},
                     @"post_from" : @{
                             @"ru" : @"Пост от",
                             @"en" : @"Post by",
                             @"fr" : @"",
                             @"es" : @""},
                     @"post_text" : @{
                             @"ru" : @"Текст поста",
                             @"en" : @"Post content",
                             @"fr" : @"",
                             @"es" : @""}
                     };
    }
    return _phrases;
}

@end
