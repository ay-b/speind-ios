//
//  NSString+TimeToString.m
//  lastfmlocalplayback
//
//  Created by Kevin Renskers on 19-09-12.
//  Copyright (c) 2012 Last.fm. All rights reserved.
//

#import "NSString+TimeToString.h"

@implementation NSString (TimeToString)

+ (NSString *)stringFromTime:(NSTimeInterval)seconds
{
    NSString *timeString = nil;
    const int secsPerMin = 60;
	const int minsPerHour = 60;
	const char *timeSep = ":";
	seconds = floor(seconds);

	if (seconds < 60.0) {
		timeString = [NSString stringWithFormat:@"0:%02.0f", seconds];
	} else {
        int mins = seconds/secsPerMin;
        int secs = seconds - mins*secsPerMin;

        if (mins < 60.0) {
            timeString = [NSString stringWithFormat:@"%d%s%02d", mins, timeSep, secs];
        } else {
            int hours = mins/minsPerHour;
            mins -= hours * minsPerHour;
            timeString = [NSString stringWithFormat:@"%d%s%02d%s%02d", hours, timeSep, mins, timeSep, secs];
        }
    }

    return timeString;
}

+ (NSString *)stringFromDate:(NSDate*)date
{
    NSUInteger unitFlags = NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit;
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *components = [calendar components:unitFlags fromDate:date toDate:[NSDate date] options:0];
    
    NSMutableString *dateString = [NSMutableString string];
    if ([components day] > 0) {
        [dateString appendFormat:@"%li%@", (long)[components day], NSLocalizedString(@"DayShort", nil)];
    }
    else if ([components hour] > 0) {
        [dateString appendFormat:@"%li%@", (long)[components hour], NSLocalizedString(@"HourShort", nil)];
    }
    else if ([components minute] > 0) {
        [dateString appendFormat:@"%li%@", (long)[components minute], NSLocalizedString(@"MinuteShort", nil)];
    }
    else {
        [dateString appendFormat:@"1%@", NSLocalizedString(@"MinuteShort", nil)];
    }
    [dateString appendFormat:@" %@", NSLocalizedString(@"Ago", nil)];
    
    return [dateString copy];
}

@end
