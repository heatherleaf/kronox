// 
//  Task.m
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

#import "Task.h"

@implementation Task 

#pragma mark ---- Properties in the data model ----

@dynamic order;
@dynamic name;
@dynamic enabled;
@dynamic expanded;
@dynamic appearance;
@dynamic children;
@dynamic parent;
@dynamic workperiods;

#pragma mark ---- Calculated properties ----

@dynamic longName;
- (NSString*) longName {
	NSString* pname = self.name;
	Task* prnt = self;
	while (prnt = prnt.parent) 
		pname = [NSString stringWithFormat: @"%@ - %@", prnt.name, pname];
	return pname;
}

@dynamic startRecordingName;
- (NSString*) startRecordingName {
	return [NSString stringWithFormat: @"Start \"%@\"", self.longName];
}

@dynamic color;
- (NSColor*) color {
	NSColor* color = [[Task taskColorList] colorWithKey: self.appearance];
	if (color == nil) {
		if (self.parent == nil) {
			color = [NSColor textColor];
		} else {
			color = self.parent.color;
		}
	}
	return color;
}

@dynamic duration; 
- (NSTimeInterval) duration {
	// if (! [self.enabled boolValue]) return 0;
	NSPredicate* pred = [[NSApp delegate] performSelector:@selector(viewPeriodPredicate)];
	if (!pred) return 0;
	NSTimeInterval dur = 0;
	for (WorkPeriod* work in [self.workperiods filteredSetUsingPredicate:pred]) 
		dur += [work.duration doubleValue];
	return dur;
}

@dynamic totalDuration;
- (NSTimeInterval) totalDuration {
	NSTimeInterval dur = 0;
	for (Task* child in self.children) 
		dur += child.totalDuration;
	return dur + self.duration;
}

@dynamic durationPercent;
- (NSNumber*) durationPercent {
	NSTimeInterval totalTotal = [[[NSApp delegate] performSelector:@selector(totalDurationOfWorkPeriods)] doubleValue];
	if (totalTotal && self.duration) 
		return [NSNumber numberWithDouble: self.duration / totalTotal];
	return nil;
}

@dynamic totalDurationPercent;
- (NSNumber*) totalDurationPercent {
	NSTimeInterval totalTotal = [[[NSApp delegate] performSelector:@selector(totalDurationOfWorkPeriods)] doubleValue];
	if (totalTotal && self.totalDuration) 
		return [NSNumber numberWithDouble: self.totalDuration / totalTotal];
	return nil;
}

@dynamic allParentsAreEnabled;
- (BOOL) allParentsAreEnabled {
	if (!self.parent) return YES;
	return [self.parent.enabled boolValue] && self.parent.allParentsAreEnabled;
}

#pragma mark ---- Other methods ----

- (void) awakeFromInsert {
	[super awakeFromInsert];
	static int nr = 1;
	self.name = [NSString stringWithFormat: @"New Task %i", nr];
	self.order = [NSNumber numberWithInt: -nr];
	nr++;
}

+ (NSColorList*) taskColorList {
	NSString* colorListName = [[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: @"colorListName"];
	return [NSColorList colorListNamed: colorListName];
}

@end
