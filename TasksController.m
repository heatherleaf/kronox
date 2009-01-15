//
//  TaskEditingController.m
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

#import "TasksController.h"

@implementation TasksController

#pragma mark ---- Manage work periods ----

- (IBAction) addWorkPeriod: (id) sender { 
	Task* task = [[self selectedObjects] count] > 0  ?  [[self selectedObjects] objectAtIndex: 0]  :  nil;
	LOG(@"addWorkPeriod: %@", task.name);
	[workPeriodController addForTask: task];
	[workPeriodPanel makeKeyAndOrderFront: sender];
}

- (IBAction) startRecording: (id) sender {
	LOG(@"startRecording: %@", [sender className]);
	if ([sender respondsToSelector: @selector(representedObject)] && [sender representedObject])
		[self setSelectionIndexPath: [[sender representedObject] indexPath]];

	NSArray* tasks = [self selectedObjects];
	if (![tasks count]) return;
	Task* newTask = [tasks objectAtIndex: 0];
	[workPeriodController startRecordingTask: newTask];
	if ([sender isKindOfClass:[NSView class]] && [sender enclosingMenuItem])
		[[[sender enclosingMenuItem] menu] cancelTracking];
}

#pragma mark ---- Changing ----

- (IBAction) addTask: (id) sender {
	[[self managedObjectContext] beginUndoGroup: @"Add Task"];
	NSIndexPath* path = [self selectionIndexPath];
	if (path) path = [path indexPathByAddingIndex:0];
	else path = [NSIndexPath indexPathWithIndex:0];
	Task* task = [NSEntityDescription insertNewObjectForEntityForName: @"Task" 
											   inManagedObjectContext: [self managedObjectContext]];
	[self insertObject:task atArrangedObjectIndexPath:path];
	[self reorderTasks];
	[self.managedObjectContext endUndoGroup];
	[taskPanel makeKeyAndOrderFront:sender];
}

- (IBAction) removeTask: (id) sender {
	Task* task = [[self selectedObjects] objectAtIndex:0];
	int nr_wps = [task.workperiods count];
	if (nr_wps) {
		NSInteger response = NSRunAlertPanel(@"Delete Task", 
											 @"The task %@ contains %d work periods, which will be deleted too.\n\nAre you sure you want to delete this task?",
											 @"Delete", @"Cancel", @"Show Work Periods", task.name, nr_wps);
		if (response == NSAlertOtherReturn) {
			[self enableSelectedTasks: sender];
			[[NSApp delegate] performSelector: @selector(filterWorkPeriodsByTask)];
		}
		if (response != NSAlertDefaultReturn) return;
	}		
	[self.managedObjectContext beginUndoGroup: @"Remove Task"];
	[self remove: sender];
	[self.managedObjectContext endUndoGroup];
	[self fetch: sender];
}

#pragma mark ---- Enabled tasks ----

- (BOOL) allTasksAreEnabled {
	for (Task* task in [tasksArrayController arrangedObjects]) 
		if (! [task.enabled boolValue]) return NO;
	return YES;
}

- (IBAction) toggleEnableAllTasks: (id) sender {
	if ([self allTasksAreEnabled]) [self enableSelectedTasks: sender];
	else [self enableAllTasks: sender];
}

- (IBAction) enableSelectedTasks: (id) sender {
	NSArray* selectedTasks = [self selectedObjects];
	for (Task* task in [tasksArrayController arrangedObjects]) 
		task.enabled =  [NSNumber numberWithBool: [selectedTasks containsObject: task]];
	[self fetch: sender];
}

- (IBAction) enableAllTasks: (id) sender {
	for (Task* task in [tasksArrayController arrangedObjects]) 
		task.enabled =  [NSNumber numberWithBool: YES];
	[self fetch: sender];
}


#pragma mark ---- Expanded tasks ----

- (void) reexpandTree:(NSTreeNode*)node {
	if (node == nil) {
		node = [self arrangedObjects];
	} else if (![node isLeaf]) {
		Task* task = [node representedObject];
		BOOL expanded = [task.expanded boolValue];
		[self expandOrCollapseItem:node expanded:expanded];
	}
	for (NSTreeNode* child in [node childNodes]) {
		[self reexpandTree:child];
	}
}

- (void) expandOrCollapseItem:(id)item expanded:(BOOL)expanded {
	[self expandOrCollapseItem:item expanded:expanded outlineView:recordingView];
	[self expandOrCollapseItem:item expanded:expanded outlineView:statisticsView];
	[self expandOrCollapseItem:item expanded:expanded outlineView:tasksFilterView];
}

- (void) expandOrCollapseItem:(id)item expanded:(BOOL)expanded outlineView:(NSOutlineView*)view {
	if (expanded != [view isItemExpanded:item]) {
		if (expanded) [view expandItem:item];
		else [view collapseItem:item];
	}
}

- (void) outlineViewItemDidExpandOrCollapse:(NSNotification*)notification expanded:(BOOL)expanded {
	NSTreeNode* node = [[notification userInfo] valueForKey: @"NSObject"];
	Task* task = [node representedObject];
	task.expanded = [NSNumber numberWithBool:expanded];
	[self expandOrCollapseItem:node expanded:expanded];
}

- (void) outlineViewItemDidExpand:(NSNotification*)notification {
	[self outlineViewItemDidExpandOrCollapse:notification expanded:YES];
}

- (void) outlineViewItemDidCollapse:(NSNotification*)notification {
	[self outlineViewItemDidExpandOrCollapse:notification expanded:NO];
}


#pragma mark ---- Updating ----

// Bug in Leopard 10.5.6 (Issue #19 in Google Code):
// After upgrading to 10.5.6, all items on level>=2 get collapsed on [super fetch...]
// The reason is that new NSTreeNodes are created instead of reusing the old ones.

// This is solved by adding a Task attribute "expanded", which has the additional 
// advantage that expanded/collapsed tasks are remembered between sessions

- (void) fetch: (id) sender {
	LOG(@"fetch: %@", [sender className]);
	// Issue #19: We have to fetchImmediately instead of fetch
	[self fetchImmediately: sender];
	[tasksArrayController fetch: sender];
	[workPeriodController fetch: sender];
}

- (void) fetchImmediately: (id) sender {
	LOG(@"fetchImmediately: %@", [sender className]);
	if (![self managedObjectContext]) return;
	NSError *error;
	if (![super fetchWithRequest: nil merge: NO error: &error]) 
		[NSApp presentError: error];
	[self reexpandTree:nil];
}

- (void) reorderTasks {
	LOG(@"reorderTasks");
	[self reorder: [self arrangedObjects] fromIndex: 0];
}

- (int) reorder: (NSTreeNode*) root fromIndex: (int) ix {
	for (NSTreeNode* child in [root childNodes]) {
		Task* task = [child representedObject];
		task.order = [NSNumber numberWithInt: ix];
		ix = [self reorder: child fromIndex: ix+1];
	}
	return ix;
}


#pragma mark ---- Drag and drop ----

#define TaskDragType @"Task Drag Type"

// This is called from the application's awakeFromNib
- (void) registerForDragging: (NSOutlineView*) view {
	[view registerForDraggedTypes: [NSArray arrayWithObject: TaskDragType]];
}

// Global variable used when dragging
NSTreeNode* draggedNode;

// Beginning the drag from the outline view.
- (BOOL) outlineView: (NSOutlineView*) view
		  writeItems: (NSArray*) items
		toPasteboard: (NSPasteboard*) pboard 
{
	if ([items count] == 1 &&
		[[view registeredDraggedTypes] containsObject: TaskDragType]) 
	{
		[pboard declareTypes: [NSArray arrayWithObject: TaskDragType] owner: self];
		[pboard setData: [NSData data] forType: TaskDragType];
		draggedNode = [items objectAtIndex: 0];
		return YES;
	}
	return NO;
}

// Validating a drop in the outline view.
- (NSDragOperation) outlineView: (NSOutlineView*) view
				   validateDrop: (id <NSDraggingInfo>) info
				   proposedItem: (id) item
			 proposedChildIndex: (NSInteger) index
{
	// Check that we're not trying to drop on a descendant
	while (item != nil) {
		if (item == draggedNode) return NSDragOperationNone;
		item = [item parentNode];
	}
    return NSDragOperationGeneric;
}

// Performing a drop in the outline view. 
- (BOOL) outlineView: (NSOutlineView*) view 
		  acceptDrop: (id <NSDraggingInfo>) info
				item: (id) item
		  childIndex: (NSInteger) index
{
	[self.managedObjectContext beginUndoGroup: @"Move Task"];
	NSIndexPath* newIndexPath;
	if (index < 0) index = 0;
	if (item == nil) {
		newIndexPath = [NSIndexPath indexPathWithIndex: index];
	} else {
		newIndexPath = [[item indexPath] indexPathByAddingIndex: index];
	}
    // Use the tree controller to move the node
    [self moveNode: draggedNode toIndexPath: newIndexPath];
	// Finally reorder the nodes before fetching
	[self reorderTasks];
	[self.managedObjectContext endUndoGroup];
	[self fetch: nil];
    return YES;
}


@end
