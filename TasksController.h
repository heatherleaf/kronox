//
//  TaskEditingController.h
//  KronoX
//
//  Created by Peter Ljunglöf on 2008-02-23.
//  Copyright 2008 Heatherleaf. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "UndoExtensions.h"
#import "WorkPeriodController.h"
#import "DateExtensions.h"
#import "Task.h"

@interface TasksController : NSTreeController {
	IBOutlet NSArrayController* tasksArrayController;
	IBOutlet WorkPeriodController* workPeriodController;
	IBOutlet NSPanel* workPeriodPanel;
	IBOutlet NSPanel* taskPanel;
}

// Manage work periods
- (IBAction) addWorkPeriod: (id) sender;
- (IBAction) startRecording: (id) sender;

// Changing
- (IBAction) addTask: (id) sender;
- (IBAction) removeTask: (id) sender;

// Enabled tasks
- (BOOL) allTasksAreEnabled;
- (IBAction) toggleEnableAllTasks: (id) sender;
- (IBAction) enableSelectedTasks: (id) sender;
- (IBAction) enableAllTasks: (id) sender;

// Updating
// - (void) fetch: (id) sender;
- (void) fetchImmediately: (id) sender;
- (void) reorderTasks;
- (int)  reorder: (NSTreeNode*) root fromIndex: (int) ix;

// Drag and drop
- (void) registerForDragging: (NSOutlineView*) view;

- (BOOL) outlineView: (NSOutlineView*) ov
		  writeItems: (NSArray*) items
		toPasteboard: (NSPasteboard*) pboard;

- (NSDragOperation) outlineView: (NSOutlineView*) ov
				   validateDrop: (id <NSDraggingInfo>) info
				   proposedItem: (id) item
			 proposedChildIndex: (NSInteger) index;

- (BOOL) outlineView: (NSOutlineView*) ov 
		  acceptDrop: (id <NSDraggingInfo>) info
				item: (id) item
		  childIndex: (NSInteger) index;

@end

