//
//  TaskEditingController.m
//  KronoX
//
//  Created by Peter Ljunglöf on 2008-02-23.
//  Copyright 2008 Heatherleaf. All rights reserved.
//

#import "TasksController.h"

@implementation TasksController

#pragma mark ---- Manage work periods ----

- (IBAction) addWorkPeriod: (id) sender { 
	Task* task = [[self selectedObjects] count] > 0  ?  [[self selectedObjects] objectAtIndex: 0]  :  nil;
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
	Task* task = [NSEntityDescription insertNewObjectForEntityForName: @"Task" 
											   inManagedObjectContext: [self managedObjectContext]];
	[self insertObject: task
		  atArrangedObjectIndexPath: [NSIndexPath indexPathWithIndex: 0]];
	[self reorderTasks];
	[self.managedObjectContext endUndoGroup];
	[taskPanel makeKeyAndOrderFront: sender];
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

#pragma mark ---- Updating ----

- (void) fetch: (id) sender {
	LOG(@"fetch: %@", [sender className]);
	[super fetch: sender];
	[tasksArrayController fetch: sender];
	[workPeriodController fetch: sender];
}

- (void) fetchImmediately: (id) sender {
	LOG(@"fetchImmediately: %@", [sender className]);
	if (![self managedObjectContext]) return;
	NSError *error;
	if (![super fetchWithRequest: nil merge: NO error: &error]) 
		[NSApp presentError: error];
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

//- (IBAction) updateTotalDuration: (id) sender {
//	NSTimeInterval duration = 0;
//	for (NSTreeNode* node in [[self arrangedObjects] childNodes]) 
//		duration += [[node representedObject] totalDurationIncludingSubtasks];
//	LOG(@"updateTotalDuration => %0.1f min", duration/60);
//	self.totalDuration = duration;
//}


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
	if ([items count] != 1) return NO;
    [pboard declareTypes: [NSArray arrayWithObject: TaskDragType] owner: self];
    [pboard setData: [NSData data] forType: TaskDragType];
	draggedNode = [items objectAtIndex:0];
    return YES;
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
    // Use the tree controller to move the node... 
    [self moveNode: draggedNode toIndexPath: newIndexPath];
	// ... but we have to reorder the nodes ourselves
	[self reorderTasks];
	[self.managedObjectContext endUndoGroup];
	[self fetch: nil];
    return YES;
}


@end
