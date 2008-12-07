// 
//  Task.m
//  KronoX
//
//  Created by Peter Ljunglöf on 2008-02-23.
//  Copyright 2008 Heatherleaf. All rights reserved.
//

#import "Task.h"


@implementation Task 

#pragma mark ---- Properties in the data model ----

@dynamic order;
@dynamic name;
@dynamic enabled;
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

@dynamic totalDuration; 
- (NSTimeInterval) totalDuration {
	// if (! [self.enabled boolValue]) return 0;
	NSPredicate* pred = [[NSApp delegate] performSelector:@selector(viewPeriodPredicate)];
	if (!pred) return 0;
	NSTimeInterval dur = 0;
	for (WorkPeriod* work in [self.workperiods filteredSetUsingPredicate:pred]) 
		dur += [work.duration doubleValue];
	return dur;
}

@dynamic totalDurationIncludingSubtasks;
- (NSTimeInterval) totalDurationIncludingSubtasks {
	NSTimeInterval dur = 0;
	for (Task* child in self.children) 
		dur += child.totalDurationIncludingSubtasks;
	return dur + self.totalDuration;
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
