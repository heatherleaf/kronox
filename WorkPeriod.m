// 
//  WorkPeriod.m
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

#import "WorkPeriod.h"
#import "Task.h"

@implementation WorkPeriod 

@dynamic start;
@dynamic duration;
@dynamic comment;
@dynamic task;

@dynamic end;
- (NSDate*) end {
	if (self.duration == nil) return nil;
	return [self.start addTimeInterval: [self.duration doubleValue]];
}

#define SECONDS_PER_DAY (24*60*60)

- (void) setEnd: (NSDate*) date {
	if (self.start == nil) return;
	NSTimeInterval dur = [date timeIntervalSinceDate: self.start];
	while (dur < 0) 
		dur += SECONDS_PER_DAY;
	while (dur > SECONDS_PER_DAY)
		dur -= SECONDS_PER_DAY;
	self.duration = [NSNumber numberWithDouble: dur];
}

@end
