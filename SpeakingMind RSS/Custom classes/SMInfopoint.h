//
//  SMInfopoint.h
//  Speind
//
//  Created by Sergey Butenko on 9/30/14.
//  Copyright (c) 2014 Speaking Mind. All rights reserved.
//

#import <Foundation/Foundation.h>

/** 
 * Basic class for infopoints.
 */
@interface SMInfopoint : NSObject <NSCoding>

#pragma mark - System

@property NSInteger priority;
@property NSString *lang;

#pragma mark - Public

@property NSString *senderIcon;
@property NSString *postSender;
@property NSString *postSenderVocalizing;
@property NSDate *pubDate;

@property NSString *title;
@property NSString *summary;
@property NSString *enclosure;
@property (nonatomic, readonly) NSString *placeholder;
@property (nonatomic, readonly) UIImage *sourceIcon;

@property NSString *link;
@property NSString *fullArticle;

@property NSString *textVocalizing;



/**
 *
 * An abstract getter for text which will be speaking by TTS.
 *
 * @return NSString prepared for speaking.
 *
 */
- (NSString*)vocalizingTextWithPreviuosInfopoint:(SMInfopoint*)infopoint fullArticle:(BOOL)fullArticle;

- (NSString*)displayingTextForFullArticle:(BOOL)fullArticle;

@end
