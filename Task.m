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

#define SECONDS_PER_HOUR (60*60)
#define SECONDS_PER_DAY  (24*SECONDS_PER_HOUR)
#define SECONDS_PER_YEAR (365.25*SECONDS_PER_DAY)

#pragma mark ---- Properties in the data model ----

@dynamic order;
@dynamic name;
@dynamic enabled;
@dynamic expanded;
@dynamic children;
@dynamic parent;
@dynamic workperiods;
@dynamic colorValue;
@dynamic colorEnabled;
@dynamic comment;
@dynamic normalWorkingTimePerYear;

#pragma mark ---- Calculated properties ----

@dynamic longName;
- (NSString*) longName {
	NSString* pname = [self name];
	Task* prnt = self;
	while (prnt = [prnt parent]) 
		pname = [NSString stringWithFormat:@"%@ - %@", [prnt name], pname];
	return pname;
}

@dynamic startRecordingName;
- (NSString*) startRecordingName {
	return [NSString stringWithFormat:@"Start \"%@\"", [self longName]];
}

@dynamic color;
- (NSColor*) color {
    if ([[self colorEnabled] boolValue]) {
        return [self colorValue];
    } else if ([self parent] == nil) {
        return [NSColor textColor];
    } else {
        return [[self parent] color];
    }
}

@dynamic duration; 
- (NSTimeInterval) duration {
	NSPredicate* pred = [[NSApp delegate] performSelector:@selector(viewPeriodPredicate)];
	if (!pred) return 0;
	NSTimeInterval dur = 0;
	for (WorkPeriod* work in [[self workperiods] filteredSetUsingPredicate:pred]) 
		dur += [[work duration] doubleValue];
	return dur;
}

@dynamic durationPercent;
- (NSNumber*) durationPercent {
    NSTimeInterval duration = [self duration];
	NSTimeInterval totalTotal = [[[NSApp delegate] performSelector:@selector(totalDurationOfWorkPeriods)] doubleValue];
	if (duration && totalTotal) 
		return [NSNumber numberWithDouble: duration / totalTotal];
	return nil;
}

@dynamic totalDuration;
- (NSTimeInterval) totalDuration {
	NSTimeInterval dur = 0;
	for (Task* child in [self children]) 
		dur += [child totalDuration];
	return dur + [self duration];
}

@dynamic totalDurationPercent;
- (NSNumber*) totalDurationPercent {
    NSTimeInterval total = [self totalDuration];
	NSTimeInterval totalTotal = [[[NSApp delegate] performSelector:@selector(totalDurationOfWorkPeriods)] doubleValue];
	if (total > 1 && totalTotal > 1) 
		return [NSNumber numberWithDouble: total / totalTotal];
	return nil;
}

@dynamic totalNormalWorkingTimePerYear;
- (NSTimeInterval) totalNormalWorkingTimePerYear {
    NSTimeInterval normal = [[self normalWorkingTimePerYear] doubleValue];
    for (Task* child in [self children])
        normal += [child totalNormalWorkingTimePerYear];
    return normal;
}

@dynamic normalDuration;
- (NSTimeInterval) normalDuration {
    NSTimeInterval interval = [[[NSApp delegate] performSelector:@selector(viewPeriodTimeInterval)] doubleValue];
    if (interval < 1)
        return -1;
    return [self totalNormalWorkingTimePerYear] * interval / SECONDS_PER_YEAR;
}

@dynamic normalDurationPercent;
- (NSNumber*) normalDurationPercent {
    NSTimeInterval normal = [self totalNormalWorkingTimePerYear];
    NSTimeInterval totalNormal = [PREFS doubleForKey:@"normalWorkingTimePerYear"];
    if (normal && totalNormal)
        return [NSNumber numberWithDouble: normal / totalNormal];
    return nil;
}

@dynamic relativeDurationPercent;
- (NSNumber*) relativeDurationPercent {
    NSTimeInterval total = [self totalDuration];
    NSTimeInterval normal = [self normalDuration];
    if (total > 1 && normal > 1)
        return [NSNumber numberWithDouble: total / normal];
    return nil;
}


#pragma mark ---- Other methods ----

- (void) awakeFromInsert {
	[super awakeFromInsert];
	static int nr = 1;
	[self setName:[NSString stringWithFormat:@"New Task %i", nr]];
	[self setOrder:[NSNumber numberWithInt:-nr]];
	nr++;
}

@end
