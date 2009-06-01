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
	LOG(@"addWorkPeriod: %@", [task name]);
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
	[[self managedObjectContext] endUndoGroup];
	[taskPanel makeKeyAndOrderFront:sender];
}

- (IBAction) removeTask: (id) sender {
	Task* task = [[self selectedObjects] objectAtIndex:0];
	int nr_wps = [[task workperiods] count];
	if (nr_wps) {
		NSInteger response = NSRunAlertPanel(@"Delete Task", 
											 @"The task %@ contains %d work periods, which will be deleted too.\n\nAre you sure you want to delete this task?",
											 @"Delete", @"Cancel", @"Show Work Periods", [task name], nr_wps);
		if (response == NSAlertOtherReturn) {
            // Enabled tasks are not used anymore:
			// [self enableSelectedTasks: sender];
			[[NSApp delegate] performSelector: @selector(filterWorkPeriodsByTask)];
		}
		if (response != NSAlertDefaultReturn) return;
	}		
	[[self managedObjectContext] beginUndoGroup: @"Remove Task"];
	[self remove: sender];
	[[self managedObjectContext] endUndoGroup];
	[self fetch: sender];
}

#pragma mark ---- Enabled tasks ----

- (BOOL) allTasksAreEnabled {
	for (Task* task in [tasksArrayController arrangedObjects]) 
		if (! [[task enabled] boolValue]) return NO;
	return YES;
}

- (IBAction) toggleEnableAllTasks: (id) sender {
	if ([self allTasksAreEnabled]) [self enableSelectedTasks: sender];
	else [self enableAllTasks: sender];
}

- (IBAction) enableSelectedTasks: (id) sender {
	NSArray* selectedTasks = [self selectedObjects];
	for (Task* task in [tasksArrayController arrangedObjects]) 
		[task setEnabled: [NSNumber numberWithBool: [selectedTasks containsObject: task]]];
	[self fetch: sender];
}

- (IBAction) enableAllTasks: (id) sender {
	for (Task* task in [tasksArrayController arrangedObjects]) 
		[task setEnabled: [NSNumber numberWithBool: YES]];
	[self fetch: sender];
}

#pragma mark ---- Expanding/collapsing tasks in an outline view (delegate methods) ----

- (void) _expandTreeNode:(NSTreeNode*)node inOutlineView:(NSOutlineView*)view  {
    if (node == nil) {
        node = [self arrangedObjects];
    } else if (![node isLeaf]) {
		Task* task = [node representedObject];
		BOOL expanded = [[task expanded] boolValue];
        if (expanded != [view isItemExpanded:node]) {
            if (expanded) {
                [view expandItem:node];
            } else {
                [view collapseItem:node];
            }
        }
	}
	for (NSTreeNode* child in [node childNodes]) {
		[self _expandTreeNode:child inOutlineView:view];
	}
}

- (void) expandOutlineView:(NSOutlineView*)view {
    LOG(@"expandOutlineView: %@", view);
    [self _expandTreeNode:nil inOutlineView:view];
}

- (void) outlineViewItemDidExpand:(NSNotification*)notification {
	[self outlineViewItemDidExpandOrCollapse:notification expanded:YES];
}

- (void) outlineViewItemDidCollapse:(NSNotification*)notification {
	[self outlineViewItemDidExpandOrCollapse:notification expanded:NO];
}

- (void) outlineViewItemDidExpandOrCollapse:(NSNotification*)notification expanded:(BOOL)expanded {
	NSTreeNode* node = [[notification userInfo] valueForKey: @"NSObject"];
	Task* task = [node representedObject];
    LOG(@"outlineViewItemDidExpandOrCollapse %d: %@", expanded, [task name]);
	[task setExpanded: [NSNumber numberWithBool:expanded]];
}

#pragma mark ---- Updating ----

/* [090530] Apparently Issue #19 is fixed in 10.5.7
 // Bug in Leopard 10.5.6 (Issue #19 in Google Code):
 // After upgrading to 10.5.6, all items on level>=2 get collapsed on [super fetch...]
 // The reason is that new NSTreeNodes are created instead of reusing the old ones.
 // This is solved by adding a Task attribute "expanded", which has the additional 
 // advantage that expanded/collapsed tasks are remembered between sessions
 */

- (void) fetch: (id) sender {
	LOG(@"fetch: %@", [sender className]);
    /* [090530] Apparently fixed in 10.5.7
     // Issue #19: We have to fetchImmediately instead of fetch
     // [self fetchImmediately: sender];
     */
	[super fetch: sender];
	[tasksArrayController fetch: sender];
	[workPeriodController fetch: sender];
}

- (void) fetchImmediately: (id) sender {
    LOG(@"fetchImmediately: %@", [sender className]);
    if (![self managedObjectContext]) return;
    NSError *error;
	if (![super fetchWithRequest:nil merge:NO error:&error]) 
		[NSApp presentError: error];
}    
// [090530] Apparently Issue #19 is fixed in 10.5.7
//    NSArray* selection = [self selectionIndexPaths];
//    LOG(@"1. selected nodes before fetch:");
//    for (NSTreeNode* n in [self selectedNodes])
//		LOG(@"  * %@", [[n representedObject] longName]);
//	NSError *error;
//	if (![super fetchWithRequest:nil merge:NO error:&error]) 
//		[NSApp presentError: error];
//	LOG(@"2. selected nodes after fetch:");
//	for (NSTreeNode* n in [self selectedNodes])
//		LOG(@"  * %@", [[n representedObject] longName]);
//	[self reexpandTree:nil];
//	LOG(@"reexpanded tree");
//	[self setSelectionIndexPaths:selection];
//	LOG(@"3. selected nodes after reexpansion:");
//	for (NSTreeNode* n in [self selectedNodes])
//		LOG(@"  * %@", [[n representedObject] longName]);

- (int) _reorderTreeNode:(NSTreeNode*)root fromIndex:(int)ix {
	for (NSTreeNode* child in [root childNodes]) {
		Task* task = [child representedObject];
		[task setOrder:[NSNumber numberWithInt:ix]];
		ix = [self _reorderTreeNode:child fromIndex:ix+1];
	}
	return ix;
}

- (void) reorderTasks {
	LOG(@"reorderTasks");
	[self _reorderTreeNode:[self arrangedObjects] fromIndex:0];
}


#pragma mark ---- Drag and drop (delegate methods) ----

#define TaskDragType @"Task Drag Type"

// This is called from the application's awakeFromNib
- (void) registerForDragging: (NSOutlineView*) view {
	[view registerForDraggedTypes: [NSArray arrayWithObject: TaskDragType]];
}

// Global variable used when dragging
NSTreeNode* _draggedNode;

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
		_draggedNode = [items objectAtIndex: 0];
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
		if (item == _draggedNode) return NSDragOperationNone;
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
	[[self managedObjectContext] beginUndoGroup: @"Move Task"];
	NSIndexPath* newIndexPath;
	if (index < 0) index = 0;
	if (item == nil) {
		newIndexPath = [NSIndexPath indexPathWithIndex: index];
	} else {
		newIndexPath = [[item indexPath] indexPathByAddingIndex: index];
	}
    // Use the tree controller to move the node
    [self moveNode: _draggedNode toIndexPath: newIndexPath];
	// Finally reorder the nodes before fetching
	[self reorderTasks];
	[[self managedObjectContext] endUndoGroup];
	[self fetch: nil];
    return YES;
}


@end
