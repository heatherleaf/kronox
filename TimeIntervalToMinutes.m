//
//  TimeIntervalToMinutes.m
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

#import "TimeIntervalToMinutes.h"

@implementation TimeIntervalToMinutes

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
    NSInteger minutes = (NSInteger) (seconds+30)/60;
	return [NSNumber numberWithInteger:minutes];
}

- (NSNumber*) reverseTransformedValue: (NSNumber*) value {
	if (value == nil) 
        return nil;
    NSInteger minutes = [value integerValue];
	return [NSNumber numberWithInteger:minutes*60];
}

@end

