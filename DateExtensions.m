//
//  DateExtensions.m
//  KronoX
//
//  Created by Peter Ljunglöf on 2008-03-24.
//  Copyright 2008 Heatherleaf. All rights reserved.
//

#import "DateExtensions.h"


@implementation NSDate (DateExtensions)


unsigned dateCalendarUnits = NSEraCalendarUnit | NSYearCalendarUnit | NSMonthCalendarUnit  | NSDayCalendarUnit;

- (NSDate*) addHours: (int) hours {
	NSDateComponents* comps = [[NSDateComponents alloc] init];
	[comps setHour: hours];
	return [self addComponents: comps];
}

- (NSDate*) addMinutes: (int) minutes {
	NSDateComponents* comps = [[NSDateComponents alloc] init];
	[comps setMinute: minutes];
	return [self addComponents: comps];
}

- (NSDate*) addSeconds: (int) seconds {
	NSDateComponents* comps = [[NSDateComponents alloc] init];
	[comps setSecond: seconds];
	return [self addComponents: comps];
}

- (NSDate*) addDays: (int) days {
	NSDateComponents* comps = [[NSDateComponents alloc] init];
	[comps setDay: days];
	return [self addComponents: comps];
}

- (NSDate*) addWeeks: (int) weeks {
	NSDateComponents* comps = [[NSDateComponents alloc] init];
	[comps setWeek: weeks];
	return [self addComponents: comps];
}

- (NSDate*) addMonths: (int) months {
	NSDateComponents* comps = [[NSDateComponents alloc] init];
	[comps setMonth: months];
	return [self addComponents: comps];
}


//- (NSDate*) addHours: (int) hours
//			 minutes: (int) minutes
//			 seconds: (int) seconds
//{
//	NSDateComponents* comps = [[NSDateComponents alloc] init];
//	[comps setHour: hours];
//	[comps setMinute: minutes];
//	[comps setSecond: seconds];
//	return [self addComponents: comps];
//}
//
//- (NSDate*) addDays: (int) days
//			  weeks: (int) weeks
//			 months: (int) months
//{
//	NSDateComponents* comps = [[NSDateComponents alloc] init];
//	[comps setDay: days];
//	[comps setWeek: weeks];
//	[comps setMonth: months];
//	return [self addComponents: comps];
//}

- (NSDate*) noon {
	return [[self lastMidnight] addHours: 12];
}

- (NSDate*) lastMidnight {
	return [self filterThroughComponents: [NSDate dateUnits]];
}


+ (NSDate*) dateFromComponents: (NSDateComponents*) comps
{
	return [[NSCalendar currentCalendar] dateFromComponents: comps];
}

- (NSDate*) addComponents: (NSDateComponents*) comps 
{
	return [[NSCalendar currentCalendar] dateByAddingComponents: comps
														 toDate: self
														options: 0];
}

- (NSDate*) filterThroughComponents: (NSUInteger) unitFlags {
	return [NSDate dateFromComponents: [self components: unitFlags]];
}

- (NSDateComponents*) components: (NSUInteger) unitFlags 
{
	return [[NSCalendar currentCalendar] components: unitFlags
										   fromDate: self];
}

- (NSDateComponents*) components: (NSUInteger) unitFlags
					   sinceDate: (NSDate*) date 
{
	return [[NSCalendar currentCalendar] components: unitFlags
										   fromDate: date
											 toDate: self
											options: 0];
}


+ (NSUInteger) dateUnits {
	return NSYearCalendarUnit | NSMonthCalendarUnit  | NSDayCalendarUnit;
}

+ (NSUInteger) timeUnits {
	return NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit;
}

+ (NSUInteger) allUnits  {
	return [NSDate dateUnits] | [NSDate timeUnits];
}

@end
