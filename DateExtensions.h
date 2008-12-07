//
//  DateExtensions.h
//  KronoX
//
//  Created by Peter Ljunglöf on 2008-03-24.
//  Copyright 2008 Heatherleaf. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSDate (DateExtensions)

- (NSDate*) addHours: (int) hours;
- (NSDate*) addMinutes: (int) minutes;
- (NSDate*) addSeconds: (int) seconds;

- (NSDate*) addDays: (int) days;
- (NSDate*) addWeeks: (int) weeks;
- (NSDate*) addMonths: (int) months;

//- (NSDate*) addHours: (int) hours
//			 minutes: (int) minutes
//			 seconds: (int) seconds;
//- (NSDate*) addDays: (int) days
//			  weeks: (int) weeks
//			 months: (int) months;

- (NSDate*) noon;
- (NSDate*) lastMidnight;

+ (NSDate*) dateFromComponents: (NSDateComponents*) comps;
- (NSDate*) addComponents: (NSDateComponents*) comps;
- (NSDate*) filterThroughComponents: (NSUInteger) unitFlags;

- (NSDateComponents*) components: (NSUInteger) unitFlags;
- (NSDateComponents*) components: (NSUInteger) unitFlags
					   sinceDate: (NSDate*) date;

+ (NSUInteger) dateUnits;
+ (NSUInteger) timeUnits;
+ (NSUInteger) allUnits;

@end
