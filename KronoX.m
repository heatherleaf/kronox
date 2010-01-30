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

@synthesize workPeriodSortDescriptors, tasksSortDescriptors, 
    contentViewSegment, viewPeriodSegment, viewPeriodDate, 
    viewPeriodStart, viewPeriodEnd, viewPeriodPredicate, 
    viewPeriodStartEnabled, viewPeriodEndEnabled, 
    searchString, searchAttribute, comparisonOperator;

#pragma mark ---- Content views and view periods ----

- (NSTableView*) selectedContentView {
    return [self contentViewSegment]==1 ? statisticsView : workPeriodView;
}

#define STATISTICS_SIZE_KEY @"statisticsViewSize"
#define WORKPERIOD_SIZE_KEY @"workperiodViewSize"

// This is called from the toolbar and the View menu
// It toggles between Detailed View (workPeriodView) and Statistics View
- (IBAction) changeContentView: (id) sender {
    if (![sender isKindOfClass:[NSSegmentedControl class]] && [sender respondsToSelector:@selector(tag)]) {
        // If the sender is not the segmented control in the toolbar,
        // we have to change the appearance of the toolbar.
        [self setContentViewSegment:[sender tag]];
    }
    LOG(@"changeContentView: %d", [self contentViewSegment]);
    NSWindow* window = [contentView window];
    NSTableView* currentContentView = [contentView documentView];
    NSTableView* newContentView = [self selectedContentView];
    if (currentContentView != newContentView) {
        // We only change the size of the window if the user selected a different content view.
        NSRect frame = [window frame];
        NSString* key = newContentView==workPeriodView ? WORKPERIOD_SIZE_KEY : STATISTICS_SIZE_KEY;
        NSString* newSizeString = [PREFS stringForKey:key];
        NSSize newSize = newSizeString == nil ? frame.size : NSSizeFromString(newSizeString);
        LOG(@"change content view size: %@ --> %@", NSStringFromSize(frame.size), NSStringFromSize(newSize));
        if (currentContentView == workPeriodView || currentContentView == statisticsView) {
            // We don't want to do this when KronoX starts, since none of the views is current then.
            NSString* key = currentContentView==workPeriodView ? WORKPERIOD_SIZE_KEY : STATISTICS_SIZE_KEY;
            [PREFS setObject:NSStringFromSize(frame.size) forKey:key];
        }
        frame.origin.y += frame.size.height - newSize.height;
        frame.size = newSize;
        [contentView setDocumentView:newContentView];
        [window setFrame:frame display:YES animate:YES];
    }
    [detailedViewMenuItem setState: (newContentView == workPeriodView ? NSOnState : NSOffState)];
    [statisticsViewMenuItem setState: (newContentView == statisticsView ? NSOnState : NSOffState)];
    [tasksController fetch:sender];
}

- (IBAction) sizeTableColumnsToFit: (id) sender {
    LOG(@"sizeTableColumnsToFit");
    [[self selectedContentView] sizeToFit]; 
}


#pragma mark ---- Content views and view periods ----

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
//  - addForTask:, startRecordingTask: (in WorkPeriodController)
//  - changeViewPeriodSpan:, showGotoDatePanel:, awakeFromNib (in KronoX)
- (IBAction) changeViewPeriodDate: (id) sender {
    NSDate* newDate = [NSDate date];
    if ([sender isKindOfClass:[NSDate class]]) {
        newDate = sender;
    } else if ([sender respondsToSelector:@selector(dateValue)]) {
        newDate = [sender dateValue];
    } else {
        NSInteger delta = 0;
        if ([sender isKindOfClass:[NSNumber class]]) {
            delta = [sender intValue];
        } else if ([sender respondsToSelector:@selector(tag)]) {
            delta = [sender tag];
        }
        if (delta) {
            switch ([self viewPeriodSegment]) {
                case 1: newDate = [[self viewPeriodDate] addDays:delta];
                    break;
                case 2: newDate = [[self viewPeriodDate] addWeeks:delta];
                    break;
                case 3: newDate = [[self viewPeriodDate] addMonths:delta];
                    break;
            }
        }
    }
    [self setViewPeriodDate:[newDate noon]];
    LOG(@"changeViewPeriodDate: %@", [self viewPeriodDate]);
    [self changeViewPeriodSpan:nil];
}

- (IBAction) changeViewPeriodSpan: (id) sender {
    // currentSegment is needed to switch back to the previous segment
    // since previous/next should never be selected
    static NSInteger currentSegment = 1;

    // if user pressed previous/next, call changeViewPeriodDate instead
    if ([sender isKindOfClass:[NSSegmentedControl class]]) {
        int seg = [sender selectedSegment];
        if (seg==0 || seg==4) {
            [self setViewPeriodSegment:currentSegment];
            [self changeViewPeriodDate:[NSNumber numberWithInt:(seg==0 ? -1 : 1)]];
            return;
        }
    }
    
    if ([sender isKindOfClass:[NSSegmentedControl class]]) 
        currentSegment = [self viewPeriodSegment];
    else if ([sender respondsToSelector:@selector(tag)])
        currentSegment = [sender tag];
    [self setViewPeriodSegment:currentSegment];
    LOG(@"changeViewPeriodSpan: %d", [self viewPeriodSegment]);

    [dailyViewMenuItem setState:NSOffState];
    [weeklyViewMenuItem setState:NSOffState];
    [monthlyViewMenuItem setState:NSOffState];
    [self setViewPeriodStartEnabled:YES];
    [self setViewPeriodEndEnabled:YES];
    switch ([self viewPeriodSegment]) {
        case 1: // view by day
            [self setViewPeriodStart:[self viewPeriodDate]];
            [self setViewPeriodEnd:[self viewPeriodDate]];
            [dailyViewMenuItem setState:NSOnState];
            break;
        case 2: // view by week
            [self setViewPeriodStart:[[self viewPeriodDate] filterThroughComponents:(NSYearCalendarUnit | NSWeekCalendarUnit)]];
            [self setViewPeriodEnd:[[[self viewPeriodStart] addWeeks:1] addDays:-1]];
            [weeklyViewMenuItem setState:NSOnState];
            break;
        case 3: // view by month
            [self setViewPeriodStart:[[self viewPeriodDate] filterThroughComponents:(NSYearCalendarUnit | NSMonthCalendarUnit)]];
            [self setViewPeriodEnd:[[[self viewPeriodStart] addMonths:1] addDays:-1]];
            [monthlyViewMenuItem setState:NSOnState];
            break;
    }
    [self updateViewPeriodPredicate:sender];
}

# pragma mark ---- Showing & hiding the search view ----

- (void) setSearchViewHidden:(BOOL)hidden {
    LOG(@"setSearchViewHidden: %d", hidden);
    NSRect contentFrame = [contentEnclosingView frame];
    NSRect searchFrame = [searchView frame];
    [searchView setHidden:hidden];
    if (hidden) {
        contentFrame.size.height = searchFrame.origin.y + searchFrame.size.height - contentFrame.origin.y;
    } else {
        contentFrame.size.height = searchFrame.origin.y - contentFrame.origin.y;
    }
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

- (IBAction) showInconsistentWorkPeriods: (id) sender {
    [self searchForTasksEqualTo:@"-----"];
}

- (IBAction) filterWorkPeriodsByTask: (id) sender {
    if ([[tasksController selectedObjects] count] > 0)
        [self searchForTasksEqualTo:[[[tasksController selectedObjects] objectAtIndex:0] longName]];
}

- (void) searchForTasksEqualTo:(NSString*)taskname {
    [self setSearchString:taskname];
    [self setSearchAttribute:0];
    [self setComparisonOperator:2];
    [self setViewPeriodStartEnabled:NO];
    [self setViewPeriodEndEnabled:NO];
    [self setSearchViewHidden:NO];
    [self updateAdvancedViewPeriodPredicate:nil];
}

- (NSString*) searchAttributeString {
    switch ([self searchAttribute]) {
        case 1:  return @"task.name";
        case 2:  return @"comment";
        default: return @"task.longName";
    }
}

- (NSString*) comparisonOperatorString {
    switch ([self comparisonOperator]) {
        case 1:  return @"BEGINSWITH[cd]";
        case 2:  return @"LIKE[cd]";
        default: return @"CONTAINS[cd]";
    }
}

- (IBAction) updateViewPeriodPredicate: (id) sender {
    LOG(@"updateViewPeriodPredicate: %@", [sender className]);
    int    hoursToAdd = [PREFS integerForKey:@"dateChangeHour"];
    NSPredicate* fromPredicate = [NSPredicate predicateWithValue:YES];
    if ([self viewPeriodStartEnabled] && [self viewPeriodStart]) {
        fromPredicate = [NSPredicate predicateWithFormat:@"%@ <= start", 
                         [[self viewPeriodStart] lastMidnight]];
        // alternatively [[from ...] addHours:hoursToAdd], 
        // but then there are problems with changing times in edit work period panel
    }
    NSPredicate* uptoPredicate = [NSPredicate predicateWithValue:YES];
    if ([self viewPeriodEndEnabled] && [self viewPeriodEnd]) {
        uptoPredicate = [NSPredicate predicateWithFormat:@"start <= %@", 
                         [[[self viewPeriodEnd] lastMidnight] addHours:24+hoursToAdd]];
    }
    NSPredicate* searchPredicate = [NSPredicate predicateWithValue:YES];
    NSString* search = [self searchString];
    if ([search length] > 0) {
        NSString* formatString = [NSString stringWithFormat:@"%@ %@ %%@ OR task == nil", 
                                  [self searchAttributeString], [self comparisonOperatorString]];
        searchPredicate = [NSPredicate predicateWithFormat:formatString, [self searchString]];
    }
    NSArray* preds = [NSArray arrayWithObjects:fromPredicate, uptoPredicate, searchPredicate, nil];
    [self setViewPeriodPredicate:[NSCompoundPredicate andPredicateWithSubpredicates:preds]];
    LOG(@"PRED: %@", [self viewPeriodPredicate]);
    [workPeriodController setFilterPredicate:[self viewPeriodPredicate]];
    [tasksController fetch:nil];
}

- (IBAction) updateAdvancedViewPeriodPredicate: (id) sender {
    [self updateViewPeriodPredicate:sender];
    [dailyViewMenuItem setState:NSOffState];
    [weeklyViewMenuItem setState:NSOffState];
    [monthlyViewMenuItem setState:NSOffState];
    [self setViewPeriodSegment:-1];
}


#pragma mark ---- Called by other classes, via performSelector: ----

- (NSDate*) getViewPeriodStart {
    return [self viewPeriodStartEnabled] ? [self viewPeriodStart] : nil;
}

- (NSDate*) getViewPeriodEnd {
    return [self viewPeriodEndEnabled] ? [self viewPeriodEnd] : nil;
}

- (NSNumber*) totalDurationOfWorkPeriods {
    return [NSNumber numberWithDouble:[workPeriodController totalDuration]];
}

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
    // Mess up the content view
    NSSize size = [contentView frame].size;
    CGFloat originalHeight = size.height;
    NSTableView* table = [contentView documentView];
    size.height = [table frame].size.height + [[table headerView] frame].size.height;
    [contentView setFrameSize:size];
    [contentView setHasVerticalScroller:NO];
    // Show the print panel
    NSPrintInfo* printInfo = [NSPrintInfo sharedPrintInfo];
    [printInfo setHorizontalPagination:NSFitPagination];
    [printInfo setVerticalPagination:NSAutoPagination];
    NSPrintOperation* op = [NSPrintOperation printOperationWithView:contentView
                                                          printInfo:printInfo];
    [op runOperation];
    // Restore the content view
    size.height = originalHeight;
    [contentView setFrameSize:size];
    [contentView setHasVerticalScroller:YES];
}

#pragma mark ---- Modal dialogs ----

- (IBAction) showGotoDatePanel: (id) sender {
    LOG(@"showGotoDatePanel: %@", [sender className]);
    [gotoDatePanel showModalBelow:viewPeriodSegmentedControl];
    [self changeViewPeriodDate:[self viewPeriodDate]];
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
    [statisticsView setUsesAlternatingRowBackgroundColors:[PREFS boolForKey:@"viewAlternatingRows"]];
    [workPeriodView setUsesAlternatingRowBackgroundColors:[PREFS boolForKey:@"viewAlternatingRows"]];
    [workPeriodController checkIdleTime:sender];
    [tasksController fetch:sender];
}

// We need to to this, otherwise the normalWorkingTime text field is not updated
// Called by popup buttons changing normalWorkingTimeInterval
// (in edit task panel & preferences panel) 
- (IBAction) setNormalWorkingTimeInterval: (id) sender {
    [normalWorkingTimeTextField setDoubleValue:
     [TimeIntervalToNormalWorkingTime transform:
      [PREFS doubleForKey:@"normalWorkingTimePerYear"]]];
    [tasksController fetch:sender];
}

+ (void) initialize {
    LOG(@"initialize");
    NSDictionary* initialDefaults = [NSDictionary dictionaryWithObjectsAndKeys:
                                     [NSNumber numberWithInt: [NSFont systemFontSize]], @"fontSize",
                                     [NSNumber numberWithInt:  30], @"minimumWorkPeriodLength",
                                     [NSNumber numberWithInt: 600], @"standardWorkPeriodLength",
                                     [NSNumber numberWithInt:   3], @"dateChangeHour",
                                     // 0 = 37:30, 1 = 37h30m, 2 = 37.5, 3 = 37.5h
                                      [NSNumber numberWithInt:   0], @"durationAppearance",
                                     [NSNumber numberWithInt:   0], @"idleTimeInterval",
                                     // 40 hrs/week * 365.25 days/year / 7 days/week * 3600 secs/hr = X secs/year
                                     [NSNumber numberWithDouble: 40*365.25/7*3600], @"normalWorkingTimePerYear",
                                     // 0 = hrs/week, 1 = hrs/month, 2 = hrs/year
                                     [NSNumber numberWithInt:   0], @"normalWorkingTimeInterval",
                                     [NSNumber numberWithBool: NO], @"viewAlternatingRows",
                                     [NSNumber numberWithBool: NO], @"showOverlappingTimes",
                                     // 0 = Generic symbol, 1 = Last task in path, 2 = All tasks in path
                                     [NSNumber numberWithInt:   0], @"statusItemSymbolIndex",
                                     [NSNumber numberWithBool: NO], @"statusItemAnimated",
                                     [NSNumber numberWithBool: NO], @"statusItemForegroundColorEnabled",
                                     [NSNumber numberWithBool: NO], @"statusItemColorEnabled",
                                     [NSNumber numberWithFloat: 150], @"splitViewDividerPosition",
                                     [NSKeyedArchiver archivedDataWithRootObject:[NSColor whiteColor]], 
                                     @"statusItemBackgroundColor",
                                     nil];
    [PREFS registerDefaults:initialDefaults];
}

- (void) awakeFromNib {
    LOG(@"awakeFromNib");
        
    [tasksController registerForDragging:recordingView];
    
    [self setWorkPeriodSortDescriptors:
     [NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"start" ascending:YES]]];
    [self setTasksSortDescriptors:
     [NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"order" ascending:YES]]];
    
    [workPeriodView setTarget:workPeriodPanel];
    [workPeriodView setDoubleAction:@selector(makeKeyAndOrderFront:)];
    
    [recordingView setTarget:tasksController];
    [recordingView setDoubleAction:@selector(startRecording:)];
    
    [workPeriodController initStatusMenu];
    [self applyPreferences:nil];
    [workPeriodController stopRecording:nil];

    [self changeContentView:nil];
    [self changeViewPeriodSpan:nil];
    [self changeViewPeriodDate:nil];
    [self hideSearchView:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:tasksController
                                             selector:@selector(fetch:)
                                                 name:NSUndoManagerDidUndoChangeNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:tasksController
                                             selector:@selector(fetch:)
                                                 name:NSUndoManagerDidRedoChangeNotification
                                               object:nil];
    
    [NSTimer scheduledTimerWithTimeInterval:1
                                     target:workPeriodController
                                   selector:@selector(tickTheClock:)
                                   userInfo:nil
                                    repeats:YES];
    [NSTimer scheduledTimerWithTimeInterval:30
                                     target:self
                                   selector:@selector(saveManagedObjectContext:)
                                   userInfo:nil
                                    repeats:YES];
    
    [workPeriodController tickTheClock:self];
    [tasksController fetchImmediately:self];
    if ([[[tasksController arrangedObjects] childNodes] count] == 0) {
        // Show splash screen
        NSRunAlertPanel(@"There are no tasks defined yet", 
                        @"Choose 'New Task...' from the 'KronoX' menu, \
                        and then you are ready to start tracking",
                        @"OK", nil, nil);
    }
    [tasksController expandOutlineView:recordingView];
    [tasksController expandOutlineView:statisticsView];
}

- (IBAction) activateApplication: (id) sender {
    [NSApp activateIgnoringOtherApps:YES];
}

#pragma mark ---- Termination ----

- (BOOL) applicationShouldTerminateAfterLastWindowClosed: (NSApplication*) theApplication {
    return YES;
}

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
        if (![fileManager fileExistsAtPath:applicationSupportFolder isDirectory:NULL]) 
            [fileManager createDirectoryAtPath:applicationSupportFolder attributes:nil];
        NSURL* url = [NSURL fileURLWithPath:[applicationSupportFolder stringByAppendingPathComponent:DATABASEFILE]];
        persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
        NSDictionary *optionsDictionary = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] 
                                                                      forKey:NSMigratePersistentStoresAutomaticallyOption];
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
