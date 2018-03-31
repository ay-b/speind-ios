//
//  NSString+Language.h
//  SpeakingMind RSS
//
//  Created by Sergey Butenko on 10/6/14.
//  Copyright (c) 2014 Speaking Mind. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Language)

/**
 * Tries to detect a language of the string.
 */
- (NSString*)sm_langOfString;

@end
 