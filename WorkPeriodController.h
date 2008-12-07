//
//  WorkPeriodController.h
//  KronoX
//
//  Created by Peter Ljunglöf on 2008-03-31.
//  Copyright 2008 Heatherleaf. All rights reserved.
//

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

	NSTimeInterval totalDuration;
	
	// Current recording
	WorkPeriod* currentWorkPeriod;
	NSDate* currentStartTime;
	NSNumber* currentDuration;
	BOOL isRecording;
	BOOL canChangeDate;
	IBOutlet NSDateFormatter* currentDurationFormatter;
}

@property (retain) WorkPeriod* currentWorkPeriod;
@property (copy) NSDate*   currentStartTime;
@property (copy) NSNumber* currentDuration;
@property        BOOL      isRecording;
@property        BOOL      canChangeDate;

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
