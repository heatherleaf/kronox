//
//  KronoX.m
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

#import "KronoX.h"

@implementation KronoX

#define APPLICATION_NAME @"KronoX"

#define MODELFILE @"KronoX-model.momd"

#ifdef DEBUG
#define DATABASEFILE @"KronoX-debug-data.sql"
#else
#define DATABASEFILE @"KronoX-data.sql"
#endif

@synthesize /* taskColorListKeys, */ workPeriodSortDescriptors, tasksSortDescriptors, 
	contentViewSegment, viewPeriodSegment, viewPeriodDate, 
    viewPeriodStart, viewPeriodEnd, viewPeriodPredicate, 
    commentFilter, viewPeriodStartEnabled, viewPeriodEndEnabled,
    taskFilterEnabled, commentFilterEnabled;

#pragma mark ---- Views ----

- (IBAction) changeContentView: (id) sender {
	if (![sender isKindOfClass: [NSSegmentedControl class]] && [sender respondsToSelector: @selector(tag)])
		[self setContentViewSegment: [sender tag]];
	LOG(@"changeContentView: %d", [self contentViewSegment]);
	switch ([self contentViewSegment]) {
		case 0:
			[detailedViewMenuItem setState: NSOnState];
			[statisticsViewMenuItem setState: NSOffState];
			[contentView setDocumentView: workPeriodView];
			[workPeriodView sizeToFit];
			break;
		case 1:
			[detailedViewMenuItem setState: NSOffState];
			[statisticsViewMenuItem setState: NSOnState];
			[contentView setDocumentView: statisticsView];
			[statisticsView sizeToFit];
			break;
	}
	[tasksController fetch: sender];
}

- (IBAction) changeWorkPeriodDate: (id) sender {
	[self changeViewPeriodDate: sender];
	LOG(@"SELECT: %d", [[workPeriodDatePicker selectedWorkPeriods] count]);
	[workPeriodController setSelectedObjects: [workPeriodDatePicker selectedWorkPeriods]];
}

- (IBAction) changeViewPeriodDate: (id) sender {
	NSDate* newDate = [NSDate date];
	if ([sender isKindOfClass: [NSDate class]]) {
		newDate = sender;
	} else if ([sender respondsToSelector: @selector(dateValue)]) {
		newDate = [sender dateValue];
	} else {
		NSInteger delta = 0;
		if ([sender respondsToSelector: @selector(intValue)])
			delta = [sender intValue];
		else if ([sender respondsToSelector: @selector(tag)])
			delta = [sender tag];
		if (delta) {
			switch ([self viewPeriodSegment]) {
				case 1: newDate = [[self viewPeriodDate] addDays: delta];
					break;
				case 2: newDate = [[self viewPeriodDate] addWeeks: delta];
					break;
				case 3: newDate = [[self viewPeriodDate] addMonths: delta];
					break;
			}
		}
	}
	[self setViewPeriodDate: [newDate noon]];
	LOG(@"changeViewPeriodDate: %@", [self viewPeriodDate]);
	[self changeViewPeriodSpan: nil];
}

- (IBAction) changeViewPeriodSpan: (id) sender {
	// currentSegment is needed to switch back to the previous segment
	// since previous/next should never be selected
	static NSInteger currentSegment = 1;

	// if user pressed previous/next, call changeViewPeriodDate instead
	if ([sender isKindOfClass: [NSSegmentedControl class]]) {
		int seg = [sender selectedSegment];
		if (seg==0 || seg==4) {
			[self setViewPeriodSegment: currentSegment];
			[self changeViewPeriodDate: [NSNumber numberWithInt: seg==0 ? -1 : 1]];
			return;
		}
	}
	
	if ([sender isKindOfClass: [NSSegmentedControl class]]) 
		currentSegment = [self viewPeriodSegment];
	else if ([sender respondsToSelector: @selector(tag)])
		currentSegment = [sender tag];
	[self setViewPeriodSegment: currentSegment];
	LOG(@"changeViewPeriodSpan: %d", [self viewPeriodSegment]);

	[dailyViewMenuItem setState: NSOffState];
	[weeklyViewMenuItem setState: NSOffState];
	[monthlyViewMenuItem setState: NSOffState];
	[self setViewPeriodStartEnabled: YES];
    [self setViewPeriodEndEnabled: YES];
	[self setTaskFilterEnabled: NO];
    [self setCommentFilter: NO];
	switch ([self viewPeriodSegment]) {
		case 1: // view by day
			[self setViewPeriodStart: [self viewPeriodDate]];
			[self setViewPeriodEnd: [self viewPeriodDate]];
			[dailyViewMenuItem setState: NSOnState];
			break;
		case 2: // view by week
			[self setViewPeriodStart: [[self viewPeriodDate] filterThroughComponents: NSYearCalendarUnit | NSWeekCalendarUnit]];
			[self setViewPeriodEnd: [[[self viewPeriodStart] addWeeks:1] addDays:-1]];
			[weeklyViewMenuItem setState: NSOnState];
			break;
		case 3: // view by month
			[self setViewPeriodStart: [[self viewPeriodDate] filterThroughComponents: NSYearCalendarUnit | NSMonthCalendarUnit]];
			[self setViewPeriodEnd: [[[self viewPeriodStart] addMonths:1] addDays:-1]];
			[monthlyViewMenuItem setState: NSOnState];
			break;
	}
	[self updateViewPeriodPredicate: sender];
}

- (IBAction) updateViewPeriodPredicate: (id) sender {
	LOG(@"updateViewPeriodPredicate: %@", [sender className]);
	int	hoursToAdd = [PREFS integerForKey: @"dateChangeHour"];
	NSPredicate* fromPredicate = [NSPredicate predicateWithValue: YES];
	if ([self viewPeriodStartEnabled] && [self viewPeriodStart]) {
		LOG(@"filter: from");
		fromPredicate = [NSPredicate predicateWithFormat: @"%@ <= start", 
						 [[self viewPeriodStart] lastMidnight]];
		// alternatively [[from ...] addHours: hoursToAdd], 
		// but then there are problems with changing times in edit work period panel
	}
	NSPredicate* uptoPredicate = [NSPredicate predicateWithValue: YES];
	if ([self viewPeriodEndEnabled] && [self viewPeriodEnd]) {
		LOG(@"filter: upto");
		uptoPredicate = [NSPredicate predicateWithFormat: @"start <= %@", 
						 [[[self viewPeriodEnd] lastMidnight] addHours: 24+hoursToAdd]];
	}
	NSPredicate* taskPredicate = [NSPredicate predicateWithValue: YES];
	if ([self taskFilterEnabled]) {
		LOG(@"filter: task");
		taskPredicate = [NSPredicate predicateWithFormat: @"task.enabled == YES OR task == nil"];
	}
	NSPredicate* commentPredicate = [NSPredicate predicateWithValue: YES];
	if ([self commentFilterEnabled] && [[self commentFilter] length] > 0) {
		LOG(@"filter: comment");
		commentPredicate = [NSPredicate predicateWithFormat: @"comment CONTAINS[cd] %@", [self commentFilter]];
	}
	NSArray* preds = [NSArray arrayWithObjects: fromPredicate, uptoPredicate, taskPredicate, commentPredicate, nil];
	[self setViewPeriodPredicate: [NSCompoundPredicate andPredicateWithSubpredicates: preds]];
	[workPeriodController setFilterPredicate: [self viewPeriodPredicate]];
	[tasksController fetch: nil];
}

- (IBAction) showInconsistentWorkPeriods: (id) sender {
	for (Task* task in [tasksArrayController arrangedObjects]) 
		[task setEnabled: [NSNumber numberWithBool: NO]];
	[self filterWorkPeriodsByTask];
}

- (IBAction) updateAdvancedViewPeriodPredicate: (id) sender {
	[self updateViewPeriodPredicate: sender];
	[dailyViewMenuItem setState: NSOffState];
    [weeklyViewMenuItem setState: NSOffState];
    [monthlyViewMenuItem setState: NSOffState];
	[self setViewPeriodSegment: -1];
}

- (void) filterWorkPeriodsByTask {
	[self setTaskFilterEnabled: YES];
	[self setCommentFilterEnabled: NO];
    [self setViewPeriodStartEnabled: NO];
    [self setViewPeriodEndEnabled: NO];
	[self updateAdvancedViewPeriodPredicate: nil];
}

- (NSDate*) getViewPeriodStart {
	if ([self viewPeriodStartEnabled]) return [self viewPeriodStart];
	return nil;
}

- (NSDate*) getViewPeriodEnd {
	if ([self viewPeriodEndEnabled]) return [self viewPeriodEnd];
	return nil;
}

- (NSNumber*) totalDurationOfWorkPeriods {
	return [NSNumber numberWithDouble: [workPeriodController totalDuration]];
}

#pragma mark ---- Printing ----

- (IBAction) print: (id) sender {
	switch ([self contentViewSegment]) {
		case 0:
			[workPeriodView print: sender];
			break;
		case 1:
			[statisticsView print: sender];
			break;
	}
}

#pragma mark ---- Modal dialogs ----

- (IBAction) showGotoDatePanel: (id) sender {
	LOG(@"showGotoDatePanel: %@", [sender className]);
	[gotoDatePanel showModalBelow: viewPeriodSegmentedControl];
	[self changeViewPeriodDate: [self viewPeriodDate]];
}


# pragma mark ---- Delegate methods ----

- (NSRect) window:(NSWindow*)window willPositionSheet:(ModalSheet*)sheet usingRect:(NSRect)rect {
	if (![sheet viewThatSheetEmergesBelow]) return rect;
	NSRect newRect = [[sheet viewThatSheetEmergesBelow] frame];
	NSRect superRect = [[[sheet viewThatSheetEmergesBelow] superview] frame];
	newRect.origin.x += rect.size.width - superRect.size.width;
	newRect.origin.y += 2;
	newRect.size.height = 0;
	return newRect;
}

- (NSUndoManager*) windowWillReturnUndoManager: (NSWindow*) window {
    return [[self managedObjectContext] undoManager];
}

#pragma mark ---- Initialization & Preferences ----

- (IBAction) applyPreferences: (id) sender {
	LOG(@"applyPreferences: %@", [sender className]);
	// [self setTaskColorListKeys: [[Task taskColorList] allKeys]];
	[commentColumn setHidden: [PREFS boolForKey:@"hideCommentColumn"]];
	[statisticsView setUsesAlternatingRowBackgroundColors: [PREFS boolForKey:@"viewAlternatingRows"]];
	[workPeriodView setUsesAlternatingRowBackgroundColors: [PREFS boolForKey:@"viewAlternatingRows"]];
	[tasksController fetch: sender];
}

+ (void) initialize {
	LOG(@"initialize");
	NSDictionary* initialDefaults = [NSDictionary dictionaryWithObjectsAndKeys:
									 // @"Apple", @"colorListName",
									 [NSNumber numberWithInt: [NSFont systemFontSize]], @"fontSize",
									 [NSNumber numberWithInt:  30], @"minimumWorkPeriodLength",
									 [NSNumber numberWithInt: 600], @"standardWorkPeriodLength",
									 [NSNumber numberWithInt:   3], @"dateChangeHour",
									 [NSNumber numberWithInt:   0], @"durationAppearance",
									 [NSNumber numberWithBool: NO], @"hideCommentColumn",
									 [NSNumber numberWithBool: NO], @"viewAlternatingRows",
									 [NSNumber numberWithInt:   0], @"statusItemSymbolIndex",
									 [NSNumber numberWithBool: NO], @"statusItemAnimated",
									 [NSNumber numberWithBool: NO], @"statusItemForegroundColorEnabled",
									 [NSNumber numberWithBool: NO], @"statusItemColorEnabled",
									 [NSKeyedArchiver archivedDataWithRootObject: [NSColor whiteColor]], @"statusItemBackgroundColor",
									 nil];
	[PREFS registerDefaults: initialDefaults];
}

- (void) awakeFromNib {
	LOG(@"awakeFromNib");
	
	[tasksController registerForDragging: recordingView];
	
	[self setWorkPeriodSortDescriptors: [NSArray arrayWithObject: [[NSSortDescriptor alloc] initWithKey: @"start" ascending: YES]]];
	[self setTasksSortDescriptors:      [NSArray arrayWithObject: [[NSSortDescriptor alloc] initWithKey: @"order" ascending: YES]]];
	
	[workPeriodView setTarget: workPeriodPanel];
	[workPeriodView setDoubleAction: @selector(makeKeyAndOrderFront:)];
	
	[recordingView setTarget: tasksController];
	[recordingView setDoubleAction: @selector(startRecording:)];
	
	[workPeriodController initStatusMenu];
	[self applyPreferences: nil];
	[workPeriodController stopRecording: nil];

	[self changeContentView: nil];
	[self changeViewPeriodSpan: nil];
	[self changeViewPeriodDate: nil];
	
	[[NSNotificationCenter defaultCenter] addObserver: tasksController
											 selector: @selector(fetch:)
												 name: @"NSUndoManagerDidUndoChangeNotification" 
											   object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: tasksController
											 selector: @selector(fetch:)
												 name: @"NSUndoManagerDidRedoChangeNotification" 
											   object: nil];
	
	[NSTimer scheduledTimerWithTimeInterval: 1
									 target: workPeriodController
								   selector: @selector(tickTheClock:)
								   userInfo: nil
									repeats: YES];
	[NSTimer scheduledTimerWithTimeInterval: 30
									 target: self
								   selector: @selector(saveManagedObjectContext:)
								   userInfo: nil
									repeats: YES];
	
	[workPeriodController tickTheClock: self];
    [tasksController fetchImmediately: self];
	if ([[[tasksController arrangedObjects] childNodes] count] == 0) {
		// Show splash screen
		NSRunAlertPanel(@"There are no tasks defined yet", 
						@"Choose 'Edit Tasks...' from the 'KronoX' menu, add some tasks and then you are ready to start tracking",
						@"OK", nil, nil);
	}
    [tasksController expandOutlineView:recordingView];
    [tasksController expandOutlineView:statisticsView];
    [tasksController expandOutlineView:tasksFilterView];
}

- (IBAction) activateApplication: (id) sender {
	[NSApp activateIgnoringOtherApps: YES];
}


#pragma mark ---- Termination ----

- (BOOL) applicationShouldTerminateAfterLastWindowClosed: (NSApplication*) theApplication {
    return YES;
}

- (NSApplicationTerminateReply) applicationShouldTerminate: (NSApplication*) sender {
	[workPeriodController stopRecording: sender];
    NSError *error;
    int reply = NSTerminateNow;
    if (managedObjectContext != nil) {
        if ([managedObjectContext commitEditing]) {
            if ([managedObjectContext hasChanges] && ![managedObjectContext save: &error]) {
                BOOL errorResult = [NSApp presentError: error];
                if (errorResult == YES) {
                    reply = NSTerminateCancel;
                } else {
                    int alertReturn = NSRunAlertPanel(nil, @"Could not save changes while quitting. Quit anyway?", 
													  @"Quit anyway", @"Cancel", nil);
                    if (alertReturn == NSAlertAlternateReturn) {
                        reply = NSTerminateCancel;	
                    }
                }
            }
        } else {
            reply = NSTerminateCancel;
        }
    }
    return reply;
}


#pragma mark ---- Core Data methods ----

- (IBAction) saveManagedObjectContext: (id) sender {
    NSError *error;
    if ([[self managedObjectContext] hasChanges]) {
		LOG(@"Saving managedObjectContext");
		if (![[self managedObjectContext] save: &error])
			[NSApp presentError: error];
	}
}

- (NSString*) applicationSupportFolder {
	LOG(@"applicationSupportFolder");
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString* basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();
    return [basePath stringByAppendingPathComponent: APPLICATION_NAME];
}

- (NSManagedObjectModel*) managedObjectModel {
	LOG(@"managedObjectModel");
    if (managedObjectModel == nil) {
		NSString* path = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent: MODELFILE];
		LOG(@"Path to managedObjectModel: %@", path);
		managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:[NSURL fileURLWithPath:path]];
	}
    return managedObjectModel;
}

- (NSPersistentStoreCoordinator*) persistentStoreCoordinator {
	LOG(@"persistentStoreCoordinator");
    if (persistentStoreCoordinator == nil) {
		NSFileManager* fileManager = [NSFileManager defaultManager];
		NSString* applicationSupportFolder = [self applicationSupportFolder];
		if (![fileManager fileExistsAtPath: applicationSupportFolder isDirectory: NULL]) 
			[fileManager createDirectoryAtPath: applicationSupportFolder attributes: nil];
		NSURL* url = [NSURL fileURLWithPath: [applicationSupportFolder stringByAppendingPathComponent: DATABASEFILE]];
		persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: [self managedObjectModel]];
		NSDictionary *optionsDictionary = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] 
																	  forKey:NSMigratePersistentStoresAutomaticallyOption]; 		
		NSError* error;
		NSPersistentStore* store = [persistentStoreCoordinator addPersistentStoreWithType: NSSQLiteStoreType
																			configuration: nil
																					  URL: url
																				  options: optionsDictionary
																					error: &error];
		if (store == nil) [NSApp presentError: error];
	}
    return persistentStoreCoordinator;
}

- (NSManagedObjectContext*) managedObjectContext {
	LOG(@"managedObjectContext");
    if (managedObjectContext == nil) {
		NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
		if (coordinator != nil) {
			managedObjectContext = [[NSManagedObjectContext alloc] init];
			[managedObjectContext setPersistentStoreCoordinator: coordinator];
		}
    }
    return managedObjectContext;
}


@end
