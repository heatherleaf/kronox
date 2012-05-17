//
//  Task.h
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
#import "WorkPeriod.h"
#import "DateExtensions.h"

@interface Task : NSManagedObject  

// Properties in the data model:
@property (retain) NSNumber* order;
@property (retain) NSString* name;
@property (retain) NSNumber* enabled; // boolean value
@property (retain) NSNumber* expanded; // boolean value 
@property (retain) NSSet* children;
@property (retain) Task* parent;
@property (retain) NSSet* workperiods;
@property (retain) NSColor* colorValue;
@property (retain) NSNumber* colorEnabled; // boolean value
@property (retain) NSString* comment;
@property (retain) NSNumber* normalWorkingTimePerYear;
@property (retain) NSNumber* completed; // boolean value
@property (retain) NSDate* completedDate;
@property (retain) NSDecimalNumber* hourlyRate;

// Calculated properties:

// "parent - parent - ... - name":
@property (readonly) NSString* longName;
// "Start \"(longName)\"":
@property (readonly) NSString* startRecordingName;
// either 'colorValue' or the color of the parent:
@property (readonly) NSColor* color;
// the total duration of this task's currently shown workperiods:
@property (readonly) NSTimeInterval duration;
// this task's duration / total duration of all shown workperiods:
@property (readonly) NSNumber* durationPercent;
// the duration of this task and its subtasks:
@property (readonly) NSTimeInterval totalDuration;
// this task's duration (incl subtasks) / total duration:
@property (readonly) NSNumber* totalDurationPercent;
// normal working time/year incl subtasks:
@property (readonly) NSTimeInterval totalNormalWorkingTimePerYear;
// normal duration incl subtasks:
@property (readonly) NSTimeInterval normalDuration;
// normal duration / normal working time/year:
@property (readonly) NSNumber* normalDurationPercent;
// total duration / normal duration
// >1: has worked too much, <1: has worked too little:
@property (readonly) NSNumber* relativeDurationPercent;
// only show the completedDate if the date is checked as 'completed':
@property (readonly) NSDate* completedDateIfCompleted;
// If hourlyRate is 0, look in the parent task for an inherited hourly rate we might use.
@property (readonly) NSDecimalNumber* inheritedHourlyRate;

// Other methods
- (void) awakeFromInsert;

@end

