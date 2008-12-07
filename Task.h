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

@interface Task :  NSManagedObject  

// Properties in the data model:
@property (retain) NSNumber* order;
@property (retain) NSString* name;
@property (retain) NSNumber* enabled;
@property (retain) NSString* appearance;
@property (retain) NSSet* children;
@property (retain) Task* parent;
@property (retain) NSSet* workperiods;

// Calculated properties:
@property (readonly) NSString* longName;
@property (readonly) NSString* startRecordingName;
@property (readonly) NSColor* color;
@property (readonly) NSTimeInterval totalDuration;
@property (readonly) NSTimeInterval totalDurationIncludingSubtasks;
@property (readonly) NSNumber* totalDurationPercent;
@property (readonly) BOOL allParentsAreEnabled;

// Other methods
- (void) awakeFromInsert;
+ (NSColorList*) taskColorList;

@end

