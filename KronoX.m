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

// Cocoa bindings variables:
@synthesize workPeriodSortDescriptors, tasksSortDescriptors, 
    contentViewSegment, viewPeriodSegment, viewPeriodDate, 
    viewPeriodStart, viewPeriodEnd, viewPeriodPredicate, 
    viewPeriodStartEnabled, viewPeriodEndEnabled, 
    searchString, searchAttribute, comparisonOperator;


#pragma mark ---- Content views and view periods ----

// Return the content view that is selected by the segmented control in the toolbar.
- (NSTableView*) selectedContentView {
    switch ([self contentViewSegment]) {
        case 0: return workPeriodView;
        case 1: return statisticsView;
        default: return workPeriodView;
    }
}

// Return the UserDefaults key for storing the size of a content view.
- (NSString*) sizeKeyForContentView: (NSTableView*) theContentView {
    if (theContentView == workPeriodView) return @"workPeriodViewSize";
    if (theContentView == statisticsView) return @"statisticsViewSize";
    return @"DUMMY_KEY_THAT_IS_NOT_USED";
}

// Toggle between Detailed View (workPeriodView) and Statistics View.
//  - called from the toolbar, from the View menu, and from awakeFromNib in KronoX.m
- (IBAction) changeContentView: (id) sender {
    LOG(@"changeContentView: %@", sender);
    
    // If the sender is not the segmented control in the toolbar, we have to select it:
    if (![sender isKindOfClass:[NSSegmentedControl class]] && [sender respondsToSelector:@selector(tag)]) {
        [self setContentViewSegment:[sender tag]];
    }
    NSWindow* window = [contentView window];
    NSRect frame = [window frame];
    NSTableView* oldContentView = [contentView documentView];
    NSTableView* newContentView = [self selectedContentView];
    
    // Store the size for the current content view:
    [PREFS setObject:NSStringFromSize(frame.size) 
              forKey:[self sizeKeyForContentView:oldContentView]];
    
    // We only change the size of the window if the user selected a different content view:
    if (oldContentView != newContentView) {
        NSString* newSizeString = [PREFS stringForKey:[self sizeKeyForContentView:newContentView]];
        LOG(@"change content view size: %@ --> %@", NSStringFromSize(frame.size), newSizeString);
        NSSize newSize = newSizeString == nil ? frame.size : NSSizeFromString(newSizeString);
        frame.origin.y += frame.size.height - newSize.height;
        frame.size = newSize;
        [contentView setDocumentView:newContentView];
        [recordingView setNextKeyView:newContentView];
        [window setFrame:frame display:YES animate:YES];
    }
    
    
    // Change the state of the menu items:
    [detailedViewMenuItem setState: (newContentView == workPeriodView ? NSOnState : NSOffState)];
    [statisticsViewMenuItem setState: (newContentView == statisticsView ? NSOnState : NSOffState)];
    
    // Finally we update the content of the content view:
    [tasksController fetch:sender];
}

// Called from the contextual menu in the content views (workPeriodView and statisticsView)
- (IBAction) sizeTableColumnsToFit: (id) sender {
    LOG(@"sizeTableColumnsToFit");
    [[self selectedContentView] sizeToFit]; 
}


#pragma mark ---- Content views and view periods ----

// Returns the number of seconds (NSTimeInterval as a NSNumber object) 
// between the start and end dates of the view period.
//  - called from normalDuration in Task.m
- (NSNumber*) viewPeriodTimeInterval {
    if ([self viewPeriodStartEnabled] && [self viewPeriodEndEnabled]) {
        NSTimeInterval interval = [[[[self viewPeriodEnd] lastMidnight] addHours:24]
                                   timeIntervalSinceDate:[[self viewPeriodStart] lastMidnight]];
        return [NSNumber numberWithDouble:interval];
    } else {
        return nil;
    }
}

// This is called by:
//  - Next, Previous, Go to Today (in the View menu)
//  - when changing date in the Edit Workperiod panel
//  - addForTask:, startRecordingTask: (in WorkPeriodController)
//  - changeViewPeriodSpan:, showGotoDatePanel:, awakeFromNib (in KronoX)
- (IBAction) changeViewPeriodDate: (id) sender {
    // We remove focus from all fields in the work period panel,
    // just in case there are pending edits:
    [workPeriodPanel makeFirstResponder:nil];
    
    NSDate* newDate;
    if ([sender isKindOfClass:[NSDate class]]) {
        // Set an absolute date.
        newDate = sender;
    } else if ([sender respondsToSelector:@selector(dateValue)]) {
        // Set an absolute date.
        newDate = [sender dateValue];
    } else {
        // delta is one of {-1, 0, 1}
        //   0: go to Today
        //  -1: move back, relative
        //   1: move forward, relative
        NSInteger delta = 0;
        if ([sender isKindOfClass:[NSNumber class]]) {
            delta = [sender intValue];
        } else if ([sender respondsToSelector:@selector(tag)]) {
            delta = [sender tag];
        }
        if (delta) {
            // If delta != 0, set a relative date.
            switch ([self viewPeriodSegment]) {
                case 1: newDate = [[self viewPeriodDate] addDays:delta];
                    break;
                case 2: newDate = [[self viewPeriodDate] addWeeks:delta];
                    break;
                case 3: newDate = [[self viewPeriodDate] addMonths:delta];
                    break;
            }
        } else {
            // If delta == 0, go to Today.
            newDate = [NSDate date];
        }
    }
    [self setViewPeriodDate:[newDate noon]];
    LOG(@"changeViewPeriodDate: %@", [self viewPeriodDate]);
    [self changeViewPeriodSpan:nil];
}

// Change between Day, Week, and Month view.
// Called from:
//  - changeViewPeriodDate in KronoX.m
//  - the segmented control in the toolbar
//  - the View menu items "by Day", "by Week" and "by Month"
- (IBAction) changeViewPeriodSpan: (id) sender {
    // currentSegment is needed to switch back to the previous segment; in case the user 
    // clicked previous/next in the segmented control, they should never be selected:
    static NSInteger currentSegment = 1;

    // if user pressed previous/next, call changeViewPeriodDate instead:
    if ([sender isKindOfClass:[NSSegmentedControl class]]) {
        int seg = [sender selectedSegment];
        if (seg==0 || seg==4) {
            [self setViewPeriodSegment:currentSegment];
            [self changeViewPeriodDate:[NSNumber numberWithInt:(seg==0 ? -1 : 1)]];
            return;
        }
    }
    
    // set the view period, and make sure it is selected in the segmented control:
    if ([sender isKindOfClass:[NSSegmentedControl class]]) 
        currentSegment = [self viewPeriodSegment];
    else if ([sender respondsToSelector:@selector(tag)])
        currentSegment = [sender tag];
    [self setViewPeriodSegment:currentSegment];
    LOG(@"changeViewPeriodSpan: %d", [self viewPeriodSegment]);
    
    // reset the menu items (we select the correct one later):
    [dailyViewMenuItem setState:NSOffState];
    [weeklyViewMenuItem setState:NSOffState];
    [monthlyViewMenuItem setState:NSOffState];
    
    // make sure the start and end dates are enabled:
    [self setViewPeriodStartEnabled:YES];
    [self setViewPeriodEndEnabled:YES];
    
    // set the start and end dates, and select the corresponding menu item:
    switch ([self viewPeriodSegment]) {
        case 1: // view by day
            [self setViewPeriodStart:[self viewPeriodDate]];
            [self setViewPeriodEnd:[self viewPeriodDate]];
            [dailyViewMenuItem setState:NSOnState];
            break;
        case 2: // view by week
            [self setViewPeriodStart:[[self viewPeriodDate] 
                                      filterThroughComponents:(NSYearCalendarUnit | NSWeekCalendarUnit)]];
            [self setViewPeriodEnd:[[[self viewPeriodStart] addWeeks:1] addDays:-1]];
            [weeklyViewMenuItem setState:NSOnState];
            break;
        case 3: // view by month
            [self setViewPeriodStart:[[self viewPeriodDate] 
                                      filterThroughComponents:(NSYearCalendarUnit | NSMonthCalendarUnit)]];
            [self setViewPeriodEnd:[[[self viewPeriodStart] addMonths:1] addDays:-1]];
            [monthlyViewMenuItem setState:NSOnState];
            break;
    }
    
    // update the contents view:
    [self updateViewPeriodPredicate:sender];
}

# pragma mark ---- Showing & hiding the search view ----

// Show or hide the search view. Called by 
//  - showSearchView:, hideSearchView:, and searchForTasksEqualTo:
- (void) setSearchViewHidden:(BOOL)hidden {
    LOG(@"setSearchViewHidden: %d", hidden);
    NSRect contentFrame = [contentEnclosingView frame];
    NSRect searchFrame = [searchView frame];
    [searchView setHidden:hidden];
    contentFrame.size.height = searchFrame.origin.y - contentFrame.origin.y;
    if (hidden) 
        contentFrame.size.height += searchFrame.size.height;
    [contentEnclosingView setFrame:contentFrame];
}

- (IBAction) showSearchView:(id)sender {
    [self setSearchViewHidden:NO];
    [searchField selectText:sender];
}

- (IBAction) hideSearchView:(id)sender {
    [self setSearchViewHidden:YES];
    [self setSearchString:@""];
    [self updateViewPeriodPredicate:sender];
}

# pragma mark ---- Searching ----

// Show all work periods which have no corresponding task,
// (i.e., inconsistent work periods).
// We do this by searching for a task which (probably) doesn't exist,
// since WPs without task are always found.
- (IBAction) showInconsistentWorkPeriods: (id) sender {
    [self searchForTasksEqualTo:@"-----"];
}

// Show all work periods of the selected task.
- (IBAction) filterWorkPeriodsByTask: (id) sender {
    // We can only do this if a task is selected:
    if ([[tasksController selectedObjects] count] > 0) {
        [self searchForTasksEqualTo:[[[tasksController selectedObjects] objectAtIndex:0] longName]];
    }
}

// Show all work periods with the given task name.
- (void) searchForTasksEqualTo:(NSString*)taskname {
    [self setSearchString:taskname];
    [self setSearchAttribute:0];          // Search for task.longName
    [self setComparisonOperator:2];       // Search using LIKE[cd] (case- and diacritic insensitive equality)
    [self setViewPeriodStartEnabled:NO];  // Turn off start and end dates
    [self setViewPeriodEndEnabled:NO];    // -- '' --
    [self setSearchViewHidden:NO];        // Show the search view
    [self updateAdvancedViewPeriodPredicate:nil];
}

- (NSString*) searchAttributeString {
    switch ([self searchAttribute]) {
        case 1:  return @"task.name";     // The name of the task
        case 2:  return @"comment";       // The workperiod comment
        default: return @"task.longName"; // The full name of the task (including parents)
    }
}

- (NSString*) comparisonOperatorString {
    switch ([self comparisonOperator]) {
        // We always search case- and diacritic insensitive
        case 1:  return @"BEGINSWITH[cd]"; // begins with
        case 2:  return @"LIKE[cd]";       // is equal to
        default: return @"CONTAINS[cd]";   // contains
    }
}

// Update the search predicate which is used for filtering work periods in 
// the content views. The predicate is stored in the Cocoa Bindings variable 
// viewPeriodPredicate, which is read by the method duration in the class Task.
- (IBAction) updateViewPeriodPredicate: (id) sender {
    LOG(@"updateViewPeriodPredicate: %@", [sender className]);
    
    // Extra hours to include after midnight, the end date:
    int hoursToAdd = [PREFS integerForKey:@"dateChangeHour"];
    
    // The search predicate for the start time (if enabled):
    NSPredicate* fromPredicate = [NSPredicate predicateWithValue:YES];
    if ([self viewPeriodStartEnabled] && [self viewPeriodStart]) {
        fromPredicate = [NSPredicate predicateWithFormat:@"%@ <= start", 
                         [[self viewPeriodStart] lastMidnight]];
        // alternatively [[from ...] addHours:hoursToAdd], 
        // but then there are problems with changing times in edit work period panel
    }
    
    // The search predicate for the end time (if enabled):
    NSPredicate* uptoPredicate = [NSPredicate predicateWithValue:YES];
    if ([self viewPeriodEndEnabled] && [self viewPeriodEnd]) {
        uptoPredicate = [NSPredicate predicateWithFormat:@"start <= %@", 
                         [[[self viewPeriodEnd] lastMidnight] addHours:24+hoursToAdd]];
    }
    
    // The search predicate for the search string (if any):
    NSPredicate* searchPredicate = [NSPredicate predicateWithValue:YES];
    NSString* search = [self searchString];
    if ([search length] > 0) {
        NSString* formatString = [NSString stringWithFormat:@"%@ %@ %%@ OR task == nil", 
                                  [self searchAttributeString], [self comparisonOperatorString]];
        searchPredicate = [NSPredicate predicateWithFormat:formatString, [self searchString]];
    }
    
    // The final predicate is the conjunction of the three above:
    NSArray* preds = [NSArray arrayWithObjects:fromPredicate, uptoPredicate, searchPredicate, nil];
    [self setViewPeriodPredicate:[NSCompoundPredicate andPredicateWithSubpredicates:preds]];
    LOG(@"setViewPeriodPredicate: %@", [self viewPeriodPredicate]);
    
    // Set the filter predicate of the work period controller, and reload the content:
    [workPeriodController setFilterPredicate:[self viewPeriodPredicate]];
    [tasksController fetch:nil];
}

// Update the search predicate, and reset the menu items, and the segmented control.
// Used when the user manually changes the start or end dates.
- (IBAction) updateAdvancedViewPeriodPredicate: (id) sender {
    [self updateViewPeriodPredicate:sender];
    [dailyViewMenuItem setState:NSOffState];
    [weeklyViewMenuItem setState:NSOffState];
    [monthlyViewMenuItem setState:NSOffState];
    [self setViewPeriodSegment:-1];
}


#pragma mark ---- Called by other classes, via performSelector: ----

// Called from ExportImportController:
- (NSDate*) getViewPeriodStart {
    return [self viewPeriodStartEnabled] ? [self viewPeriodStart] : nil;
}

// Called from ExportImportController:
- (NSDate*) getViewPeriodEnd {
    return [self viewPeriodEndEnabled] ? [self viewPeriodEnd] : nil;
}

// Called from Task:
- (NSNumber*) totalDurationOfWorkPeriods {
    return [NSNumber numberWithDouble:[workPeriodController totalDuration]];
}

// Called from WorkPeriod:
- (NSColor*) getColorIfOverlappingTime: (NSDate*) time {
    for (WorkPeriod* other in [workPeriodController arrangedObjects]) {
        if ([time isBetween:[other start] and:[other end]])
            return [NSColor redColor];
    }
    return nil;
}

#pragma mark ---- Printing ----

// TODO: transform the tables to HTML and print that instead

- (IBAction) print: (id) sender {
    // Mess up the content view:
    NSSize size = [contentView frame].size;
    CGFloat originalHeight = size.height;
    NSTableView* table = [contentView documentView];
    size.height = [table frame].size.height + [[table headerView] frame].size.height;
    [contentView setFrameSize:size];
    [contentView setHasVerticalScroller:NO];
    
    // Show the print panel:
    NSPrintInfo* printInfo = [NSPrintInfo sharedPrintInfo];
    [printInfo setHorizontalPagination:NSFitPagination];
    [printInfo setVerticalPagination:NSAutoPagination];
    NSPrintOperation* op = [NSPrintOperation printOperationWithView:contentView
                                                          printInfo:printInfo];
    [op runOperation];
    
    // Restore the content view:
    size.height = originalHeight;
    [contentView setFrameSize:size];
    [contentView setHasVerticalScroller:YES];
}


#pragma mark ---- Modal dialogs ----

// Called by "Go to Date..." in the View menu.
- (IBAction) showGotoDatePanel: (id) sender {
    LOG(@"showGotoDatePanel: %@", [sender className]);
    [gotoDatePanel showModal];
    [self changeViewPeriodDate:[self viewPeriodDate]];
}


# pragma mark ---- Delegate methods ----

// From NSWindowDelegate Protocol Reference:
// "Tells the delegate that the window is about to show a sheet at the specified location, 
// giving it the opportunity to return a custom location for the attachment of the sheet to the window."
- (NSRect) window:(NSWindow*)window willPositionSheet:(ModalSheet*)sheet usingRect:(NSRect)rect {
    if ([sheet enclosingView]) {
        // Calculate a new location, relative to the enclosing view:
        NSView* view = [sheet enclosingView];
        NSSize viewSize = [view frame].size;
        CGFloat ypos = [view isFlipped] ? 0 : viewSize.height;
        rect.origin = [view convertPoint:NSMakePoint(0, ypos) toView:nil];
        rect.size = NSMakeSize(viewSize.width, 0);
        LOG(@"window:willPositionSheet:usingRect: %@", NSStringFromRect(rect));
    }
    return rect;
}

// From NSWindowDelegate Protocol Reference:
// "Tells the delegate that the window's undo manager has been requested. 
// Returns the appropriate undo manager for the window."
- (NSUndoManager*) windowWillReturnUndoManager: (NSWindow*) window {
    // We want to use the core data undo manager, not the default one:
    return [[self managedObjectContext] undoManager];
}

// From NSWindowDelegate Protocol Reference:
// "Informs the delegate that the window has resigned key window status."
- (void) windowDidResignKey:(NSNotification*)note {
    LOG(@"windowDid Resign Key: %@", [note object]);
    
    // In case edit workperiod (or task) panel did close, save its content:
    // Maybe not necessary??
    [self saveManagedObjectContext:nil];
    
    // We have to wait until the database is saved, before we can redisplay:
    [NSTimer scheduledTimerWithTimeInterval:0
                                     target:tasksController
                                   selector:@selector(fetch:)
                                   userInfo:nil
                                    repeats:NO];

    // Perhaps the following works as good as the current solution:
    // [[note object] makeFirstResponder:nil];
}


#pragma mark ---- Initialization & Preferences ----

// Called whenever the user changes a value in the preference panel.
- (IBAction) applyPreferences: (id) sender {
    LOG(@"applyPreferences: %@", [sender className]);
    [statisticsView setUsesAlternatingRowBackgroundColors:[PREFS boolForKey:@"viewAlternatingRows"]];
    [workPeriodView setUsesAlternatingRowBackgroundColors:[PREFS boolForKey:@"viewAlternatingRows"]];
    [workPeriodController checkIdleTime:sender];
    [tasksController fetch:sender];
}

// Called by popup buttons changing normalWorkingTimeInterval
// (in edit task panel & preferences panel).
// We need to to this, otherwise the normalWorkingTime text field is not updated.
- (IBAction) setNormalWorkingTimeInterval: (id) sender {
    [normalWorkingTimeTextField setDoubleValue:
     [TimeIntervalToNormalWorkingTime transform: [PREFS doubleForKey:@"normalWorkingTimePerYear"]]];
    [tasksController fetch:sender];
}

// Called when the program starts, before anything else is loaded.
// We use this to register default values to the preferences.
+ (void) initialize {
    LOG(@"initialize");
    NSDictionary* initialDefaults = 
        [NSDictionary dictionaryWithObjectsAndKeys:
         [NSNumber numberWithInt: [NSFont systemFontSize]], @"fontSize",
         [NSNumber numberWithInt:  30], @"minimumWorkPeriodLength",
         [NSNumber numberWithInt: 600], @"standardWorkPeriodLength",
         [NSNumber numberWithInt:   3], @"dateChangeHour",
         [NSNumber numberWithInt:   0], @"durationAppearance",
         // durationAppearance: 0 = 37:30, 1 = 37h30m, 2 = 37.5, 3 = 37.5h
         [NSNumber numberWithInt:   0], @"idleTimeInterval",
         [NSNumber numberWithDouble: 40*365.25/7*3600], @"normalWorkingTimePerYear",
         // normalWorkingTimePerYear: 40 hrs/week * 365.25 days/year / 7 days/week * 3600 secs/hr = X secs/year
         [NSNumber numberWithInt:   0], @"normalWorkingTimeInterval",
         // normalWorkingTimeInterval: 0 = hrs/week, 1 = hrs/month, 2 = hrs/year
         [NSNumber numberWithBool: NO], @"viewAlternatingRows",
         [NSNumber numberWithBool: NO], @"showOverlappingTimes",
         [NSNumber numberWithInt:   0], @"statusItemSymbolIndex",
         // statusItemSymbolIndex: 0 = Generic symbol, 1 = Last task in path, 2 = All tasks in path
         [NSNumber numberWithBool: NO], @"statusItemAnimated",
         [NSNumber numberWithBool: NO], @"statusItemForegroundColorEnabled",
         [NSNumber numberWithBool: NO], @"statusItemColorEnabled",
         [NSNumber numberWithFloat: 150], @"splitViewDividerPosition",
         [NSKeyedArchiver archivedDataWithRootObject:[NSColor whiteColor]], @"statusItemBackgroundColor",
         nil];
    [PREFS registerDefaults:initialDefaults];
}

// The Awakening...
- (void) awakeFromNib {
    LOG(@"awakeFromNib");
    
    // To be able to drag around tasks:
    [tasksController registerForDragging:recordingView];
    
    // How the work periods and the tasks are sorted:
    [self setWorkPeriodSortDescriptors:
     [NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"start" ascending:YES]]];
    [self setTasksSortDescriptors:
     [NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"order" ascending:YES]]];
    
    // When double-clicking in the work period view, show the Edit Workperiod panel:
    [workPeriodView setTarget:workPeriodPanel];
    [workPeriodView setDoubleAction:@selector(makeKeyAndOrderFront:)];
    
    // When double-clicking in the tasks view, start recording:
    [recordingView setTarget:tasksController];
    [recordingView setDoubleAction:@selector(startRecording:)];
    
    // Some additional initializations:
    [workPeriodController initStatusMenu];
    [self applyPreferences:nil];
    [workPeriodController stopRecording:nil];
    
    // ...and some more:
    [self changeContentView:nil];
    [self changeViewPeriodSpan:nil];
    [self changeViewPeriodDate:nil];
    [self hideSearchView:nil];
    
    // Whenever the user performs undo or redo, recalculate the content:
    [[NSNotificationCenter defaultCenter] addObserver:tasksController
                                             selector:@selector(fetch:)
                                                 name:NSUndoManagerDidUndoChangeNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:tasksController
                                             selector:@selector(fetch:)
                                                 name:NSUndoManagerDidRedoChangeNotification
                                               object:nil];
    
    // Tick the clock during recording, every second, starting now:
    [workPeriodController tickTheClock:nil];
    [NSTimer scheduledTimerWithTimeInterval:1
                                     target:workPeriodController
                                   selector:@selector(tickTheClock:)
                                   userInfo:nil
                                    repeats:YES];
    
    // And final initializations that we only can do after all data have been fetched:
    [tasksController fetch:nil];
    [NSTimer scheduledTimerWithTimeInterval:0
                                     target:self
                                   selector:@selector(finalInitializations:)
                                   userInfo:nil
                                    repeats:NO];
}

// Initializations that we do *after* all data have been fetched from the database.
- (void) finalInitializations: (id) sender {
    // Make sure the tasks are expanded/collapsed the same way as last time:
    [tasksController expandOutlineView:recordingView];
    [tasksController expandOutlineView:statisticsView];
    
    // If there are no tasks, show a splash screen:
    if ([[[tasksController arrangedObjects] childNodes] count] == 0) {
        // Show splash screen
        NSRunAlertPanel(@"There are no tasks defined yet", 
                        @"Choose 'New Task...' from the 'KronoX' menu, \
                        and then you are ready to start tracking",
                        @"OK", nil, nil);
    }
}

// Called from the status menu.
- (IBAction) activateApplication: (id) sender {
    [NSApp activateIgnoringOtherApps:YES];
}


#pragma mark ---- Termination ----

// An application delegate method.
- (BOOL) applicationShouldTerminateAfterLastWindowClosed: (NSApplication*) theApplication {
    return YES;
}

// An application delegate method.
- (NSApplicationTerminateReply) applicationShouldTerminate: (NSApplication*) sender {
    [workPeriodController stopRecording:sender];
    NSError *error;
    int reply = NSTerminateNow;
    if (managedObjectContext != nil) {
        if ([managedObjectContext commitEditing]) {
            if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
                BOOL errorResult = [NSApp presentError:error];
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

// All these are standard methods, automatically created when starting a Core Data project.

- (IBAction) saveManagedObjectContext: (id) sender {
    NSError *error;
    if ([[self managedObjectContext] hasChanges]) {
        LOG(@"saveManagedObjectContext: %@", [sender className]);
        if (![[self managedObjectContext] save:&error])
            [NSApp presentError:error];
    }
}

- (NSString*) applicationSupportFolder {
    LOG(@"applicationSupportFolder");
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString* basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();
    return [basePath stringByAppendingPathComponent:APPLICATION_NAME];
}

- (NSManagedObjectModel*) managedObjectModel {
    LOG(@"managedObjectModel");
    if (managedObjectModel == nil) {
        NSString* path = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:MODELFILE];
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
        if (![fileManager fileExistsAtPath:applicationSupportFolder isDirectory:NULL]) {
            [fileManager createDirectoryAtPath:applicationSupportFolder withIntermediateDirectories:YES attributes:nil error:nil];
        }
        NSURL* url = [NSURL fileURLWithPath:[applicationSupportFolder stringByAppendingPathComponent:DATABASEFILE]];
        persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
        NSDictionary *optionsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
            [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
            // With the option below, we don't need data mapping for simple data model changes
            [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption,
            nil];
        NSError* error;
        NSPersistentStore* store = [persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                                            configuration:nil
                                                                                      URL:url
                                                                                  options:optionsDictionary
                                                                                    error:&error];
        if (store == nil) [NSApp presentError:error];
    }
    return persistentStoreCoordinator;
}

- (NSManagedObjectContext*) managedObjectContext {
    LOG(@"managedObjectContext");
    if (managedObjectContext == nil) {
        NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
        if (coordinator != nil) {
            managedObjectContext = [[NSManagedObjectContext alloc] init];
            [managedObjectContext setPersistentStoreCoordinator:coordinator];
        }
    }
    return managedObjectContext;
}


@end
