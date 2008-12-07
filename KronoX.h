//
//  KronoX.h
//  KronoX
//
//  Created by Peter Ljunglöf on 2008-02-23.
//  Copyright Heatherleaf 2008 . All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DateExtensions.h"
#import "TasksController.h"
#import "WorkPeriod.h"
#import "WorkPeriodDatePicker.h"
#import "Task.h"
#import "ModalSheet.h"

@interface KronoX : NSObject 
{
	// Cocoa bindings
	NSArray* taskColorListKeys;
	NSArray* workPeriodSortDescriptors;
	NSArray* tasksSortDescriptors;

	NSInteger contentViewSegment;
	NSInteger viewPeriodSegment;
	NSDate* viewPeriodDate;
	NSDate* viewPeriodStart;
	NSDate* viewPeriodEnd;
	NSPredicate* viewPeriodPredicate;
	NSString* commentFilter;
	BOOL viewPeriodStartEnabled;
	BOOL viewPeriodEndEnabled;
	BOOL taskFilterEnabled;
	BOOL commentFilterEnabled;
	
	// Outlets
	IBOutlet WorkPeriodController* workPeriodController;
	IBOutlet NSArrayController* tasksArrayController;
	IBOutlet TasksController* tasksController;

	IBOutlet NSMenuItem* dailyViewMenuItem;
	IBOutlet NSMenuItem* weeklyViewMenuItem;
	IBOutlet NSMenuItem* monthlyViewMenuItem;
	IBOutlet NSMenuItem* detailedViewMenuItem;
	IBOutlet NSMenuItem* statisticsViewMenuItem;
	
	IBOutlet NSScrollView* contentView;
	IBOutlet NSOutlineView* statisticsView;
	IBOutlet NSOutlineView* recordingView;
	IBOutlet NSOutlineView* tasksFilterView;
	IBOutlet NSTableView* workPeriodView;
	IBOutlet NSTableColumn* commentColumn;
	IBOutlet NSPanel* workPeriodPanel;
	IBOutlet ModalSheet* gotoDatePanel;
	IBOutlet ModalSheet* startDatePanel;
	IBOutlet ModalSheet* endDatePanel;
	IBOutlet NSSegmentedControl* viewPeriodSegmentedControl;
	IBOutlet NSTextField* startDateTextField;
	IBOutlet NSTextField* endDateTextField;
	IBOutlet WorkPeriodDatePicker* workPeriodDatePicker;
	
	// Core Data variables
	NSPersistentStoreCoordinator* persistentStoreCoordinator;
    NSManagedObjectModel*         managedObjectModel;
    NSManagedObjectContext*       managedObjectContext;
}

@property (copy) NSArray* taskColorListKeys;
@property (copy) NSArray* workPeriodSortDescriptors;
@property (copy) NSArray* tasksSortDescriptors;

@property NSInteger contentViewSegment;
@property NSInteger viewPeriodSegment;
@property (copy) NSDate* viewPeriodDate;
@property (copy) NSDate* viewPeriodStart;
@property (copy) NSDate* viewPeriodEnd;
@property (copy) NSPredicate* viewPeriodPredicate;
@property (copy) NSString* commentFilter;
@property BOOL viewPeriodStartEnabled;
@property BOOL viewPeriodEndEnabled;
@property BOOL taskFilterEnabled;
@property BOOL commentFilterEnabled;

// Views
- (IBAction) changeContentView: (id) sender;
- (IBAction) changeWorkPeriodDate: (id) sender;
- (IBAction) changeViewPeriodDate: (id) sender;
- (IBAction) changeViewPeriodSpan: (id) sender;
- (IBAction) updateViewPeriodPredicate: (id) sender;
- (IBAction) showInconsistentWorkPeriods: (id) sender;
- (IBAction) updateAdvancedViewPeriodPredicate: (id) sender;
- (void) filterWorkPeriodsByTask;
- (NSDate*) getViewPeriodStart;
- (NSDate*) getViewPeriodEnd;
- (NSNumber*) totalDurationOfWorkPeriods;

- (IBAction) print: (id) sender;

// Modal dialogs
- (IBAction) showGotoDatePanel: (id) sender;

// Delegate methods
- (NSRect) window:(NSWindow*)window willPositionSheet:(ModalSheet*)sheet usingRect:(NSRect)rect;
- (NSUndoManager*) windowWillReturnUndoManager: (NSWindow*) window;

// Initialization & Preferences
- (IBAction) applyPreferences: (id) sender;
+ (void) initialize;
- (void) awakeFromNib;
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
