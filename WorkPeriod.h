//
//  WorkPeriod.h
//  KronoX
//
//  Created by Peter Ljunglöf on 2008-02-23.
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

#import <CoreData/CoreData.h>

@class Task;

@interface WorkPeriod :  NSManagedObject 

@property (retain) NSDate* start;
@property (retain) NSNumber* duration;
@property (retain) Task* task;
@property (retain) NSString* comment;
// boolean checkbox:
@property (retain) NSNumber* ok; 

// Calculated properties

// start + duration:
@property (retain) NSDate* end;
// date portion of 'start':
@property (retain) NSDate* date;
// the color of the start/end time in the WP list;
// this will be colored if the time period is overlapping:
@property (readonly) NSColor* overlappingStartColor;
@property (readonly) NSColor* overlappingEndColor;
// a string version of the 'ok' bool,
// used in the WP list:
@property (readonly) NSString* okString;
// duration * hourlyRate
@property (readonly) NSDecimalNumber* dollarValue;

@end

