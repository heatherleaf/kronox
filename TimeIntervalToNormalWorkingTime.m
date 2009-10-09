//
//  TimeIntervalToNormalWorkingTime.m
//  KronoX
//
//  Created by Peter Ljunglöf on 9/27/09.
//  Copyright 2009 Heatherleaf. All rights reserved.
//
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

#import "TimeIntervalToNormalWorkingTime.h"

@implementation TimeIntervalToNormalWorkingTime

#define SECONDS_PER_HOUR (60*60)
#define MONTHS_PER_YEAR 12
#define WEEKS_PER_YEAR (365.25/7)

+ (Class) transformedValueClass { 
	return [NSNumber class]; 
}

+ (BOOL) allowsReverseTransformation { 
	return YES; 
}

- (NSNumber*) transformedValue: (NSNumber*) value {
	if (value == nil) return nil;
    return [NSNumber numberWithDouble:[[self class] transform:[value doubleValue]]];
}

- (NSNumber*) reverseTransformedValue: (NSNumber*) value {
	if (value == nil) return nil;
    return [NSNumber numberWithDouble:[[self class] reverseTransform:[value doubleValue]]];
}

+ (double) transform: (NSTimeInterval) seconds {
    double hours = seconds / SECONDS_PER_HOUR;
    switch ([PREFS integerForKey:@"normalWorkingTimeInterval"]) {
        // 0 = hours/week, 1 = hours/month, 2 = hours/year
        case 0: return hours / WEEKS_PER_YEAR;
        case 1: return hours / MONTHS_PER_YEAR;
        case 2: return hours;
    }
    return 0;
}

+ (NSTimeInterval) reverseTransform: (double) hours {
    NSTimeInterval seconds = hours * SECONDS_PER_HOUR;
    switch ([PREFS integerForKey:@"normalWorkingTimeInterval"]) {
        // 0 = hours/week, 1 = hours/month, 2 = hours/year
        case 0: return seconds * WEEKS_PER_YEAR;
        case 1: return seconds * MONTHS_PER_YEAR;
        case 2: return seconds;
    }
    return 0;
}

@end

