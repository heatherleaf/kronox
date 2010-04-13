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
    Task* task = [[self selectedObjects] count] > 0  ?  [[self selectedObjects] objectAtIndex:0]  :  nil;
    LOG(@"addWorkPeriod: %@", [task name]);
    [workPeriodController addForTask:task];
    [workPeriodPanel makeKeyAndOrderFront:sender];
}

- (IBAction) startRecording: (id) sender {
    LOG(@"startRecording: %@", [sender className]);
    if ([sender respondsToSelector:@selector(representedObject)] && [sender representedObject])
        [self setSelectionIndexPath:[[sender representedObject] indexPath]];

    NSArray* tasks = [self selectedObjects];
    if (![tasks count]) return;
    Task* newTask = [tasks objectAtIndex:0];
    [workPeriodController startRecordingTask: newTask];
    if ([sender isKindOfClass:[NSView class]] && [sender enclosingMenuItem])
        [[[sender enclosingMenuItem] menu] cancelTracking];
}

#pragma mark ---- Changing ----

- (IBAction) addTask: (id) sender {
    [[self managedObjectContext] beginUndoGroup:@"Add Task"];
    NSIndexPath* path = [self selectionIndexPath];
    if (path) path = [path indexPathByAddingIndex:0];
    else path = [NSIndexPath indexPathWithIndex:0];
    Task* task = [NSEntityDescription insertNewObjectForEntityForName: @"Task" 
                                               inManagedObjectContext: [self managedObjectContext]];
    [self insertObject:task atArrangedObjectIndexPath:path];
    [self reorderTasks];
    [[NSApp delegate] performSelector:@selector(saveManagedObjectContext:) withObject:task];
    [[self managedObjectContext] endUndoGroup];
    [taskPanel makeKeyAndOrderFront:sender];
}

- (IBAction) removeTask: (id) sender {
    Task* task = [[self selectedObjects] objectAtIndex:0];
    int nr_wps = [[task workperiods] count];
    if (nr_wps) {
        NSInteger response = NSRunAlertPanel(@"Delete Task", 
                                             CONCAT(@"The task %@ contains %d work periods, which will be deleted too.\n\n",
                                                    @"Are you sure you want to delete this task?"),
                                             @"Delete", @"Cancel", @"Show Work Periods", [task name], nr_wps);
        if (response == NSAlertOtherReturn) 
            [[NSApp delegate] performSelector:@selector(filterWorkPeriodsByTask:) withObject:sender];
        if (response != NSAlertDefaultReturn) 
            return;
    }        
    [[self managedObjectContext] beginUndoGroup:@"Remove Task"];
    [self remove:sender];
    [[self managedObjectContext] endUndoGroup];
    [self fetch:sender];
}

// This is called when (de)selecting the "completed" checkbox
// in the "Edit Task" panel.
- (IBAction) makeTaskCompleted: (id) sender {
    LOG(@"makeTaskCompleted: %@", [sender className]);
    for (Task* task in [self selectedObjects]) {
        if ([[task completed] boolValue]) {
            if (![task completedDate]) {
                LOG(@"Setting completed date to today: %@", [task name]);
                [task setCompletedDate: [NSDate date]];
            }
        } else {
            [[sender window] makeFirstResponder:nil];
        }
    }
    [self fetch:sender];
}

#pragma mark ---- Expanding/collapsing tasks in an outline view (delegate methods) ----

- (void) _expandTreeNode: (NSTreeNode*) node inOutlineView: (NSOutlineView*) view {
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

- (void) expandOutlineView: (NSOutlineView*) view {
    LOG(@"expandOutlineView: %@", view);
    [self _expandTreeNode:nil inOutlineView:view];
}

- (void) outlineViewItemDidExpand: (NSNotification*) notification {
    [self outlineViewItemDidExpandOrCollapse:notification expanded:YES];
}

- (void) outlineViewItemDidCollapse: (NSNotification*) notification {
    [self outlineViewItemDidExpandOrCollapse:notification expanded:NO];
}

- (void) outlineViewItemDidExpandOrCollapse: (NSNotification*) notification
                                   expanded: (BOOL) expanded 
{
    NSTreeNode* node = [[notification userInfo] valueForKey:@"NSObject"];
    Task* task = [node representedObject];
    LOG(@"outlineViewItemDidExpandOrCollapse %d: %@", expanded, [task name]);
    [task setExpanded: [NSNumber numberWithBool:expanded]];
}

#pragma mark ---- Updating ----

- (void) fetch: (id) sender {
    LOG(@"fetch: %@", [sender className]);
    [super fetch:sender];
    [tasksArrayController fetch:sender];
    [workPeriodController fetch:sender];
}

- (int) _reorderTreeNode: (NSTreeNode*) root fromIndex: (int) ix {
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
    [view registerForDraggedTypes:[NSArray arrayWithObject:TaskDragType]];
}

// Global variable used when dragging
NSTreeNode* _draggedNode;

// Beginning the drag from the outline view.
- (BOOL) outlineView: (NSOutlineView*) view
          writeItems: (NSArray*) items
        toPasteboard: (NSPasteboard*) pboard 
{
    if ([items count] == 1 &&
        [[view registeredDraggedTypes] containsObject:TaskDragType]) 
    {
        [pboard declareTypes:[NSArray arrayWithObject:TaskDragType] owner: self];
        [pboard setData:[NSData data] forType:TaskDragType];
        _draggedNode = [items objectAtIndex:0];
        LOG(@"Starting dragging task: %@", [[_draggedNode representedObject] name]);
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
    [[self managedObjectContext] beginUndoGroup:@"Move Task"];
    NSIndexPath* newIndexPath;
    if (index < 0) index = 0;
    if (item == nil) {
        LOG(@"Dropping at toplevel index: %d", index);
        newIndexPath = [NSIndexPath indexPathWithIndex:index];
    } else {
        LOG(@"Dropping on task: %@, index: %d", [[item representedObject] name], index);
        newIndexPath = [[item indexPath] indexPathByAddingIndex:index];
    }
    // Use the tree controller to move the node
    [self moveNode:_draggedNode toIndexPath:newIndexPath];
    // Finally reorder the nodes before fetching
    [self reorderTasks];
    [[self managedObjectContext] endUndoGroup];
    [self fetch: nil];
    return YES;
}


@end
