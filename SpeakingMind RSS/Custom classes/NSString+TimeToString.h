//
//  NSString+TimeToString.h
//  lastfmlocalplayback
//
//  Created by Kevin Renskers on 19-09-12.
//  Copyright (c) 2012 Last.fm. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (TimeToString)

/** Convert the time represented in NSTimeInterval to NSString in follow format:
 *
 * - time less than 1m — "ss";
 *
 * - time less than 1h — "mm:ss";
 *
 * - else — "hh:mm:ss".
 *
 * @return A string in specified format: "hh:mm:ss".
 *
 */
+ (NSString *)stringFromTime:(NSTimeInterval)seconds;

/** Convert the time represented in NSDate to NSString in follow format:
 *
 * - time less than 1m — "1m";
 *
 * - time less than 1h — "mm";
 *
 * - time less than 1d — "hh";
 *
 * - else — "d".
 *
 * @return A string with format described above.
 *
 */
+ (NSString *)stringFromDate:(NSDate*)date;

@end
