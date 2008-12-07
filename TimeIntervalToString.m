//
//  TimeIntervalToString.m
//  KronoX
//
//  Created by Peter Ljunglöf on 2008-04-03.
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

#import "TimeIntervalToString.h"

@implementation TimeIntervalToString

+ (Class) transformedValueClass { 
	return [NSString class]; 
}

+ (BOOL) allowsReverseTransformation { 
	return NO; 
}

- (NSString*) transformedValue: (NSNumber*) time {
	if (time == nil) return nil;
	if (![time intValue]) return nil;
	NSString* interval;
	int minutes = ([time intValue] + 30) / 60;
	switch ([PREFS integerForKey: @"durationAppearance"]) {
		case 0:
			interval = [NSString stringWithFormat: @"%02d:%02d", minutes/60, minutes%60];
			break;
		case 1:
			interval = [NSString stringWithFormat: @"%.1fh", (float)minutes/60];
			break;
	}
	return interval;
}

@end
