//
//  MoUtils.m
//  
//
//  Created by Sanjay Madan on 10/31/16.
//  Copyright © 2016 mowglii.com. All rights reserved.
//

#import <time.h>
#import "MoUtils.h"

NSTimeInterval MonotonicClockTime(void)
{
    struct timespec t;
    clock_gettime(CLOCK_MONOTONIC, &t);
    return t.tv_sec + t.tv_nsec * 1.e-9;
}

NSLocale *DisplayLocale(void)
{
    NSLocale *current = NSLocale.currentLocale;
    NSString *language = NSBundle.mainBundle.preferredLocalizations.firstObject;
    if (![language hasPrefix:@"ko"] || [current.languageCode isEqualToString:@"ko"]) return current;
    static NSLocale *previous = nil;
    static NSLocale *korean = nil;
    if (current != previous) {
        previous = current;
        NSMutableDictionary *parts = [[NSLocale componentsFromLocaleIdentifier:current.localeIdentifier] mutableCopy];
        parts[NSLocaleLanguageCode] = @"ko";
        NSString *hourFormat = [NSDateFormatter dateFormatFromTemplate:@"j" options:0 locale:current];
        if ([hourFormat containsString:@"H"]) parts[@"hours"] = @"h23";
        else if ([hourFormat containsString:@"h"]) parts[@"hours"] = @"h12";
        korean = [NSLocale localeWithLocaleIdentifier:[NSLocale localeIdentifierFromComponents:parts]];
    }
    return korean;
}

NSString *StringByStrippingZeroMinutes(NSString *duration)
{
    if ([[DisplayLocale() localeIdentifier] hasPrefix:@"en"]) {
        if ([duration containsString:@"AM"] || [duration containsString:@"PM"] ||
            [duration containsString:@"am"] || [duration containsString:@"pm"]) {
            duration = [duration stringByReplacingOccurrencesOfString:@":00" withString:@""];
        }
    }
    return duration;
}

NSLocale *DateIntervalFormatterLocale(void)
{
    static NSLocale *currentLocale = nil;
    static NSLocale *formatterLocale = nil;
    NSLocale *locale = DisplayLocale();
    // currentLocale returns the same object until the user's settings change.
    if (locale == currentLocale) return formatterLocale;
    currentLocale = locale;
    formatterLocale = locale;

    // If the current locale works, use it.
    NSDateIntervalFormatter *formatter = [NSDateIntervalFormatter new];
    formatter.locale = locale;
    formatter.dateStyle = NSDateIntervalFormatterNoStyle;
    formatter.timeStyle = NSDateIntervalFormatterShortStyle;
    NSDate *date = [NSDate dateWithTimeIntervalSinceReferenceDate:0];
    if ([formatter stringFromDate:date toDate:[date dateByAddingTimeInterval:3600]].length > 0) {
        return formatterLocale;
    }

    // It doesn't work. Build a locale from the current locale's identifier
    // with the region as the country (en_US@rg=hrzzzz -> en_HR). This drops
    // the sort order, which isn't in the identifier.
    NSMutableDictionary *components = [[NSLocale componentsFromLocaleIdentifier:locale.localeIdentifier] mutableCopy];
    NSString *region = components[@"rg"];
    if (region.length >= 2) {
        components[NSLocaleCountryCode] = [[region substringToIndex:2] uppercaseString];
        [components removeObjectForKey:@"rg"];
    }
    // A locale built from an identifier doesn't have the user's 12/24 hour
    // setting, so get it from NSDateFormatter, which isn't affected.
    NSString *hourFormat = [NSDateFormatter dateFormatFromTemplate:@"j" options:0 locale:locale];
    if      ([hourFormat containsString:@"H"]) components[@"hours"] = @"h23";
    else if ([hourFormat containsString:@"h"]) components[@"hours"] = @"h12";
    formatterLocale = [NSLocale localeWithLocaleIdentifier:[NSLocale localeIdentifierFromComponents:components]];
    return formatterLocale;
}

NSDate *MeetingJoinableThreshold(EKEvent *event, NSCalendar *calendar)
{
    return [calendar dateByAddingUnit:NSCalendarUnitSecond value:-(15 * 60 + 30) toDate:event.startDate options:0];
}
