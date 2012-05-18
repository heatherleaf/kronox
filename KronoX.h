//
//  KronoX.h
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
#import "DateExtensions.h"
#import "TasksController.h"
#import "WorkPeriod.h"
#import "Task.h"
#import "ModalSheet.h"
#import "TimeIntervalToNormalWorkingTime.h"
#import "HSFairware.h"

@interface KronoX : NSObject 
{
    // Cocoa bindings variables:
    NSArray* workPeriodSortDescriptors;
    NSArray* tasksSortDescriptors;

    NSInteger contentViewSegment;
    NSInteger viewPeriodSegment;
    NSDate* viewPeriodDate;
    NSDate* viewPeriodStart;
    NSDate* viewPeriodEnd;
    NSPredicate* viewPeriodPredicate;
    BOOL viewPeriodStartEnabled;
    BOOL viewPeriodEndEnabled;
    NSString* searchString;
    
    NSInteger searchAttribute;
    NSInteger comparisonOperator;
    
    HSFairware *fairwareController;
    
    // Outlets in Interface Builder:
    IBOutlet WorkPeriodController* workPeriodController;
    IBOutlet NSArrayController* tasksArrayController;
    IBOutlet TasksController* tasksController;

    IBOutlet NSMenuItem* dailyViewMenuItem;
    IBOutlet NSMenuItem* weeklyViewMenuItem;
    IBOutlet NSMenuItem* monthlyViewMenuItem;
    IBOutlet NSMenuItem* detailedViewMenuItem;
    IBOutlet NSMenuItem* statisticsViewMenuItem;
    
    IBOutlet NSView* searchView;
    IBOutlet NSPopUpButton* searchAttributePopup;
    IBOutlet NSPopUpButton* comparisonOperatorPopup;
    IBOutlet NSSearchField* searchField;
    
//     IBOutlet NSSplitView* splitView;
    IBOutlet NSScrollView* contentView;
    IBOutlet NSView* contentEnclosingView;
    IBOutlet NSOutlineView* statisticsView;
    IBOutlet NSOutlineView* recordingView;
    IBOutlet NSTableView* workPeriodView;
    
    IBOutlet NSPanel* workPeriodPanel;
    IBOutlet ModalSheet* gotoDatePanel;
//     IBOutlet ModalSheet* startDatePanel;
//     IBOutlet ModalSheet* endDatePanel;
    IBOutlet NSSegmentedControl* viewPeriodSegmentedControl;
//     IBOutlet NSTextField* startDateTextField;
//     IBOutlet NSTextField* endDateTextField;
    
    IBOutlet NSTextFieldCell* normalWorkingTimeTextField;
    
    // Core Data variables:
    NSPersistentStoreCoordinator* persistentStoreCoordinator;
    NSManagedObjectModel*         managedObjectModel;
    NSManagedObjectContext*       managedObjectContext;
}

// Cocoa bindings:
@property (copy) NSArray* workPeriodSortDescriptors;
@property (copy) NSArray* tasksSortDescriptors;

@property NSInteger contentViewSegment;
@property NSInteger viewPeriodSegment;
@property (copy) NSDate* viewPeriodDate;
@property (copy) NSDate* viewPeriodStart;
@property (copy) NSDate* viewPeriodEnd;
@property (copy) NSPredicate* viewPeriodPredicate;
@property BOOL viewPeriodStartEnabled;
@property BOOL viewPeriodEndEnabled;
@property (copy) NSString* searchString;

@property NSInteger searchAttribute;
@property NSInteger comparisonOperator;

// Content views
- (IBAction) changeContentView: (id) sender;
- (IBAction) sizeTableColumnsToFit: (id) sender;

// View periods
- (NSNumber*) viewPeriodTimeInterval;
- (IBAction) changeViewPeriodDate: (id) sender;
- (IBAction) changeViewPeriodSpan: (id) sender;

// Showing & hiding the search view 
- (void) setSearchViewHidden:(BOOL)hidden;
- (IBAction) showSearchView:(id)sender;
- (IBAction) hideSearchView:(id)sender;

// Searching
- (IBAction) showInconsistentWorkPeriods: (id) sender;
- (IBAction) filterWorkPeriodsByTask: (id) sender;
- (void) searchForTasksEqualTo:(NSString*)taskname;
- (IBAction) updateViewPeriodPredicate: (id) sender;
- (IBAction) updateAdvancedViewPeriodPredicate: (id) sender;

// Called by other classes, via performSelector:
- (NSDate*) getViewPeriodStart;
- (NSDate*) getViewPeriodEnd;
- (NSNumber*) totalDurationOfWorkPeriods;
- (NSColor*) getColorIfOverlappingTime: (NSDate*) time;

// Printing
- (IBAction) print: (id) sender;

// Modal dialogs
- (IBAction) showGotoDatePanel: (id) sender;

// Delegate methods
- (NSRect) window:(NSWindow*)window willPositionSheet:(ModalSheet*)sheet usingRect:(NSRect)rect;
- (NSUndoManager*) windowWillReturnUndoManager: (NSWindow*) window;
- (void) windowDidResignKey:(NSNotification*)note;

// Initialization & Preferences
- (IBAction) applyPreferences: (id) sender;
- (IBAction) setNormalWorkingTimeInterval: (id) sender;
+ (void) initialize;
- (void) awakeFromNib;
- (void) finalInitializations: (id) sender;
- (IBAction) activateApplication: (id) sender;

// Termination
- (BOOL) applicationShouldTerminateAfterLastWindowClosed: (NSApplication*) theApplication;
- (NSApplicationTerminateReply) applicationShouldTerminate: (NSApplication*) sender;

// Core Data
- (IBAction) saveManagedObjectContext: (id) sender;
- (NSPersistentStoreCoordinator*) persistentStoreCoordinator;
- (NSManagedObjectModel*) managedObjectModel;
- (NSManagedObjectContext*) managedObjectContext;


@end
