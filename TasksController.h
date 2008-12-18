//
//  TaskEditingController.h
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
	
	IBOutlet NSOutlineView* statisticsView;
	IBOutlet NSOutlineView* recordingView;
	IBOutlet NSOutlineView* tasksFilterView;
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
- (BOOL) outlineView: (NSOutlineView*) outlineView shouldCollapseItem: (id) item;
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

