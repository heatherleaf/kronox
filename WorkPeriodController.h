//
//  WorkPeriodController.h
//  KronoX
//
//  Created by Peter Ljunglöf on 2008-03-31.
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

#import <Cocoa/Cocoa.h>
#import <CalendarStore/CalendarStore.h>
#import "UndoExtensions.h"
#import "DateExtensions.h"
#import "WorkPeriod.h"
#import "Task.h"


@interface WorkPeriodController : NSArrayController {
	// Status item, -menu, -line
	NSStatusItem* statusItem;
	IBOutlet NSMenu* recordingMenu;

    // Total duration of all visible work periods
	NSTimeInterval totalDuration;
	
	// Current recording
	WorkPeriod* currentWorkPeriod;
	NSDate* currentStartTime;
	NSNumber* currentDuration;
	BOOL isRecording;
	BOOL canChangeDate;
	IBOutlet NSDateFormatter* currentDurationFormatter;
}

@property (assign) WorkPeriod* currentWorkPeriod;
@property (copy) NSDate* currentStartTime;
@property (copy) NSNumber* currentDuration;
@property BOOL isRecording;
@property BOOL canChangeDate;

// Information on the status line
@property NSTimeInterval totalDuration;
@property (readonly) NSNumber* numberOfSelectedObjects;
- (void) updateTotalDuration;

// Recording
- (void)     tickTheClock: (id) sender;
- (void)     startRecordingTask: (Task*) newTask;
- (IBAction) stopRecording: (id) sender;
- (void)     setRecordingTo: (WorkPeriod*) work;

// The status item/menu
- (void) initStatusMenu;
- (void) synchronizeStatusTitle;

// Updating
// - (void) fetch: (id) sender;
- (void) fetchImmediately: (id) sender;

// Adding, removing
// - (void) remove: (id) sender;
- (WorkPeriod*) newWorkPeriod;
- (WorkPeriod*) addForTask: (Task*) task 
					 start: (NSDate*) start
				  duration: (NSTimeInterval) duration;
- (void) addForTask: (Task*) task;

// Delegate method
- (void) tableViewSelectionDidChange: (NSNotification*) notification;

@end
