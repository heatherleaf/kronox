//
//  WorkPeriodController.m
//  KronoX
//
//  Created by Peter Ljunglöf on 2008-03-31.
//  Copyright 2008 Heatherleaf. All rights reserved.
//

#import "WorkPeriodController.h"
#import "TimeIntervalToString.h"

@implementation WorkPeriodController

@synthesize currentStartTime, currentDuration, isRecording, canChangeDate, currentWorkPeriod;


#pragma mark ---- Information on the status line ----

@synthesize totalDuration; 
- (void) updateTotalDuration {
	[self fetchImmediately: nil];
	NSTimeInterval duration = 0;
	for (WorkPeriod* work in [self arrangedObjects]) {
		if ([work isEqual: currentWorkPeriod])
			duration += [self.currentDuration doubleValue];
		else 
			duration += [work.duration doubleValue];
	}
	LOG(@"updateTotalDuration => %0.1f min", duration/60);
	self.totalDuration = duration;
}

@dynamic numberOfSelectedObjects;
- (NSNumber*) numberOfSelectedObjects {
	[self fetchImmediately: nil];
	return [NSNumber numberWithInt: [[self arrangedObjects] count]];
}


#pragma mark ---- Recording ----

- (void) tickTheClock: (id) sender {
	if (self.isRecording) { 
		self.currentDuration = [NSNumber numberWithDouble: -[self.currentWorkPeriod.start timeIntervalSinceNow]];
	} else {
		self.currentStartTime = [NSDate date];
	}
}

- (void) startRecordingTask: (Task*) newTask {	
	if (self.isRecording) {
		// If already recording this task, don't to anything (i.e., return)
		if (self.currentWorkPeriod.task == newTask) return;
		[self stopRecording: nil];
	}
	
	[[NSApp delegate] performSelector: @selector(changeContentView:) withObject: nil];
	[[NSApp delegate] performSelector: @selector(changeViewPeriodDate:) withObject: nil];
	[[self managedObjectContext] beginUndoGroup: @"Start Recording"];
	WorkPeriod* work = [self addForTask: newTask
								  start: [NSDate date]
							   duration: -1];
	[self setRecordingTo: work];
	[[self managedObjectContext] endUndoGroup];
}

- (IBAction) stopRecording: (id) sender { 
	if (!self.isRecording) return;
	LOG(@"stopRecording: %@", [sender className]);
	[[self managedObjectContext] beginUndoGroup: @"Stop Recording"];
	NSTimeInterval duration = -[self.currentWorkPeriod.start timeIntervalSinceNow];
	NSTimeInterval minimumDuration = [PREFS doubleForKey: @"minimumWorkPeriodLength"];
	if (duration < minimumDuration) {
		[self removeObject: self.currentWorkPeriod];
		LOG(@"Discarded too short work period (%0.0f s)", duration);
	}
	self.currentWorkPeriod.duration = [NSNumber numberWithDouble: duration];
	[self setRecordingTo: nil];
	[[self managedObjectContext] endUndoGroup];
	[self fetch: sender];
}

- (void) setRecordingTo: (WorkPeriod*) work {
	if (work) {
		LOG(@"setRecordingTo: %@", work.task.longName);
		[[[[self managedObjectContext] undoManager] prepareWithInvocationTarget: self] setRecordingTo: nil];
		self.isRecording = YES;
		self.currentStartTime = work.start;
		self.currentWorkPeriod = work;
	} else {
		LOG(@"setRecordingTo: NIL");
		[[[[self managedObjectContext] undoManager] prepareWithInvocationTarget: self] setRecordingTo: self.currentWorkPeriod];
		self.isRecording = NO;
		self.currentDuration = nil;
		self.currentWorkPeriod = nil;
	}
	[self tableViewSelectionDidChange: nil];
	[self synchronizeStatusTitle];
	[self tickTheClock: nil];
}

#pragma mark ---- The status menu/item

- (void) initStatusMenu {
	LOG(@"initStatusMenu");
	statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength: NSVariableStatusItemLength];
	[statusItem setHighlightMode: YES];
	[statusItem setToolTip: @"KronoX Task Timer"];
	[statusItem setMenu: recordingMenu];
}

- (void) synchronizeStatusTitle {
	NSString* title; 
	NSMutableDictionary* attrs = [NSMutableDictionary dictionary];
	CGFloat size = [NSFont systemFontSize];
	Task* task = self.currentWorkPeriod.task;
	LOG(@"synchronizeStatusTitle: %@", task.longName);
	if (task) {
		if ([PREFS boolForKey: @"statusItemBackgroundColorEnabled"]) {
			NSColor* bgColor = [NSKeyedUnarchiver unarchiveObjectWithData: 
								[PREFS dataForKey: @"statusItemBackgroundColor"]];
			if (bgColor != nil) [attrs setValue: bgColor forKey: NSBackgroundColorAttributeName];
		}
		if ([PREFS boolForKey: @"statusItemForegroundColorEnabled"]) {
			NSColor* fgColor = task.color;
			if (fgColor != nil) [attrs setValue: fgColor forKey: NSForegroundColorAttributeName];
		}
		int ix = [PREFS integerForKey: @"statusItemSymbolIndex"];
		if (ix == 0) 
			title = @" ▶ ";
		else {
			title = [NSString stringWithFormat:@" %@ ", (ix == 1 ? task.name : task.longName)];
			size = [NSFont smallSystemFontSize];
		}
	} else {
		title = @" ◐ ";
	}
	[attrs setValue: [NSFont menuFontOfSize: size] forKey: NSFontAttributeName];
	[statusItem setAttributedTitle: [[NSAttributedString alloc] initWithString: title attributes: attrs]];
}


#pragma mark ---- Updating ----

- (void) fetch: (id) sender {
	LOG(@"fetch: %@", [sender className]);
	[super fetch: sender];
	[self synchronizeStatusTitle];
	// this is so that bindings on currentWorkPeriod also will be updated:
	self.currentWorkPeriod = self.currentWorkPeriod;
	[self updateTotalDuration];
}

- (void) fetchImmediately: (id) sender {
	LOG(@"fetchImmediately: %@", [sender className]);
	if (![self managedObjectContext]) return;
	NSError *error;
	if (![super fetchWithRequest: nil merge: NO error: &error]) 
		[NSApp presentError: error];
}

#pragma mark ---- Adding, removing ----

- (void) remove: (id) sender {
	[[self managedObjectContext] beginUndoGroup: @"Remove Work Period"];
	[super remove: sender];
	[[self managedObjectContext] endUndoGroup];
}

- (WorkPeriod*) newWorkPeriod {
	return [NSEntityDescription insertNewObjectForEntityForName: @"WorkPeriod" 
										 inManagedObjectContext: [self managedObjectContext]];
}

- (WorkPeriod*) addForTask: (Task*) task 
					 start: (NSDate*) start
				  duration: (NSTimeInterval) duration
{
	WorkPeriod* work = [self newWorkPeriod];
	work.task = task;
	work.start = start;
	if (duration >= 0)
		work.duration = [NSNumber numberWithDouble: duration];
	[self addObject: work];
	LOG(@"addForTask: %@  duration: %f  start: %@", task.name, duration, start);
	return work;
}

- (void) addForTask: (Task*) task { 
	// calculate duration
	NSTimeInterval defaultDuration = [PREFS doubleForKey: @"standardWorkPeriodLength"];
	// calculate start time
	NSDate* start = [[NSApp delegate] performSelector: @selector(viewPeriodDate)];
	start = [start filterThroughComponents: [NSDate dateUnits]];
	start = [start addComponents: [[NSDate date] components: [NSDate timeUnits]]];
	start = [start addTimeInterval: -defaultDuration];
	// set the date filter, just in case the start time is on another date than the current date filter (= the end time)
	[[NSApp delegate] performSelector: @selector(changeViewPeriodDate:) 
						   withObject: start];
	// create and add the new WP
	[[self managedObjectContext] beginUndoGroup: @"Add Work Period"];
	[self addForTask: task
			   start: start
			duration: defaultDuration];
	[[self managedObjectContext] endUndoGroup];
}

#pragma mark ---- Delegate method ----

- (void) tableViewSelectionDidChange: (NSNotification*) notification {
	self.canChangeDate = ! (isRecording && [[self selectedObjects] containsObject: currentWorkPeriod]);
}

@end
