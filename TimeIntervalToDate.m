//
//  TimeIntervalToDate.m
//  KronoX
//
//  Created by Peter Ljunglöf on 2008-03-02.
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

#import "TimeIntervalToDate.h"

@implementation TimeIntervalToDate

+ (Class) transformedValueClass { 
	return [NSDate class]; 
}

+ (BOOL) allowsReverseTransformation { 
	return YES; 
}

- (NSDate*) transformedValue: (NSNumber*) time {
	if (time == nil) return nil;
	NSTimeZone* tz = [NSTimeZone defaultTimeZone];
	NSTimeInterval seconds = [time doubleValue] - [tz secondsFromGMT];
	if ([tz isDaylightSavingTime]) 
		seconds += [tz daylightSavingTimeOffset];
	return [NSDate dateWithTimeIntervalSinceReferenceDate: seconds];
}

- (NSNumber*) reverseTransformedValue: (NSDate*) date {
	if (date == nil) return nil;
	NSTimeZone* tz = [NSTimeZone defaultTimeZone];
	NSTimeInterval seconds = [date timeIntervalSinceReferenceDate] + [tz secondsFromGMT];
	if ([tz isDaylightSavingTime]) 
		seconds -= [tz daylightSavingTimeOffset];
	return [NSNumber numberWithDouble: seconds];
}

@end
