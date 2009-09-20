//
//  TimeIntervalToNumber.m
//  KronoX
//
//  Created by Peter Ljunglöf on 1/16/09.
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

#import "TimeIntervalToNumber.h"

@implementation TimeIntervalToNumber

+ (Class) transformedValueClass { 
	return [NSNumber class]; 
}

+ (BOOL) allowsReverseTransformation { 
	return YES; 
}

- (NSNumber*) transformedValue: (NSNumber*) value {
	if (value == nil) 
        return nil;
	NSTimeInterval seconds = [value doubleValue];
	if (seconds < -0.0001) 
        return nil;
	int hours = seconds/3600;
	double minutes = seconds/60 - hours*60;
	double formatted = hours*100 + minutes;
	return [NSNumber numberWithDouble:formatted];
}

- (NSNumber*) reverseTransformedValue: (NSNumber*) value {
	if (value == nil) 
        return nil;
	double formatted = [value doubleValue];
	if (formatted <= 0) 
        return [NSNumber numberWithInt:0];
	int hours = formatted/100;
	double minutes = formatted - hours*100;
	NSTimeInterval seconds = hours*3600 + minutes*60;
	return [NSNumber numberWithDouble:seconds];
}

@end

