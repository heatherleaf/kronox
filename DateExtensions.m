//
//  DateExtensions.m
//  KronoX
//
//  Created by Peter Ljunglöf on 2008-03-24.
//  Copyright (C) 2008, Peter Ljunglöf. All rights reserved.
/*
 This file is part of KronoX.
 
 KronoX is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 KronoX is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with KronoX.  If not, see <http://www.gnu.org/licenses/>.
 */

#import "DateExtensions.h"

@implementation NSDate (DateExtensions)

unsigned dateCalendarUnits = NSEraCalendarUnit | NSYearCalendarUnit | NSMonthCalendarUnit  | NSDayCalendarUnit;

- (NSString*) asTimeString {
    return [self descriptionWithCalendarFormat:@"%H:%M:%S" timeZone:nil locale:nil];
}

- (NSDate*) addHours: (int) hours {
	NSDateComponents* comps = [[NSDateComponents alloc] init];
	[comps setHour:hours];
	return [self addComponents:comps];
}

- (NSDate*) addMinutes: (int) minutes {
	NSDateComponents* comps = [[NSDateComponents alloc] init];
	[comps setMinute:minutes];
	return [self addComponents:comps];
}

- (NSDate*) addSeconds: (int) seconds {
	NSDateComponents* comps = [[NSDateComponents alloc] init];
	[comps setSecond:seconds];
	return [self addComponents:comps];
}

- (NSDate*) addDays: (int) days {
	NSDateComponents* comps = [[NSDateComponents alloc] init];
	[comps setDay:days];
	return [self addComponents:comps];
}

- (NSDate*) addWeeks: (int) weeks {
	NSDateComponents* comps = [[NSDateComponents alloc] init];
	[comps setWeek:weeks];
	return [self addComponents:comps];
}

- (NSDate*) addMonths: (int) months {
	NSDateComponents* comps = [[NSDateComponents alloc] init];
	[comps setMonth:months];
	return [self addComponents:comps];
}

- (NSDate*) noon {
	return [[self lastMidnight] addHours:12];
}

- (NSDate*) lastMidnight {
	return [self filterThroughComponents:[NSDate dateUnits]];
}


+ (NSDate*) dateFromComponents: (NSDateComponents*) comps {
	return [[NSCalendar currentCalendar] dateFromComponents:comps];
}

- (NSDate*) addComponents: (NSDateComponents*) comps {
	return [[NSCalendar currentCalendar] dateByAddingComponents:comps toDate:self options:0];
}

- (NSDate*) filterThroughComponents: (NSUInteger) unitFlags {
	return [NSDate dateFromComponents: [self components: unitFlags]];
}

- (NSDateComponents*) components: (NSUInteger) unitFlags {
	return [[NSCalendar currentCalendar] components:unitFlags fromDate:self];
}

- (NSDateComponents*) components: (NSUInteger) unitFlags
					   sinceDate: (NSDate*) date 
{
	return [[NSCalendar currentCalendar] components:unitFlags
										   fromDate:date
											 toDate:self
											options:0];
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

- (BOOL) isBetween: (NSDate*) start and: (NSDate*) end {
    return [start compare:self] == NSOrderedAscending && [self compare:end] == NSOrderedAscending;
}

@end
