//
//  TimeIntervalToDuration.m
//  KronoX
//
//  Created by Peter Ljunglöf on 9/26/09.
//  Copyright 2009 Heatherleaf. All rights reserved.
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

#import "TimeIntervalToDuration.h"

@implementation TimeIntervalToDuration

+ (Class) transformedValueClass { 
    return [NSString class]; 
}

+ (BOOL) allowsReverseTransformation { 
    return YES; 
}

- (NSString*) transformedValue: (NSNumber*) time {
    if (time == nil || [time integerValue] <= 0) 
        return nil;
    NSInteger minutes = ([time integerValue] + 30) / 60;
    switch ([PREFS integerForKey: @"durationAppearance"]) {
        // 0 = 37:30, 1 = 37h30m, 2 = 37.5, 3 = 37.5h
        case 0: return [NSString stringWithFormat:@"%ld:%02ld", (long)minutes/60, (long)minutes%60];
        case 1: return [NSString stringWithFormat:@"%ldh%02ldm", (long)minutes/60, (long)minutes%60];
        case 2: return [NSString stringWithFormat:@"%.1f", (float)minutes/60];
        case 3: return [NSString stringWithFormat:@"%.1fh", (float)minutes/60];
    }
    return nil;
}

- (NSNumber*) reverseTransformedValue: (NSString*) str {
    NSScanner* scanner = [NSScanner scannerWithString:str];
    double hours, minutes;
    [scanner scanDouble:&hours];
    if ([scanner isAtEnd]) {
        minutes = 0;
    } else if ([scanner scanString:@":" intoString:NULL]) {
        [scanner scanDouble:&minutes];
    } else if ([scanner scanString:@"h" intoString:NULL]) {
        [scanner scanDouble:&minutes];
        [scanner scanString:@"m" intoString:NULL];
    }
    if (![scanner isAtEnd]) 
        [NSException raise:NSInternalInconsistencyException
                    format:@"Time interval could not be parsed: %@", str];
    return [NSNumber numberWithDouble: 60 * (60 * hours + minutes)];
}

@end
