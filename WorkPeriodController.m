//
//  WorkPeriodController.m
//  KronoX
//
//  Created by Peter Ljunglöf on 2008-03-31.
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

#import "WorkPeriodController.h"

@implementation WorkPeriodController

@synthesize currentStartTime, currentDuration, canChangeDate, currentWorkPeriod;


#pragma mark ---- Checking idle time ----

- (NSTimeInterval) currentIdleTime {
    return (NSTimeInterval) CGEventSourceSecondsSinceLastEventType(kCGEventSourceStateHIDSystemState, kCGAnyInputEventType);
}

- (void) checkIdleTime: (id) sender {
    static NSTimer* idleTimer;
    NSTimeInterval idleTimeInterval = [PREFS floatForKey:@"idleTimeInterval"];
    if (idleTimeInterval < 1.0)
        return;
    NSTimeInterval idleTime = [self currentIdleTime];
    LOG(@"checkIdleTime: %.1f s, interval: %.1f ", idleTime, idleTimeInterval);
    [idleTimer invalidate];
    if (![self isRecording])
        return;
    if (idleTime >= idleTimeInterval) {
        NSInteger answer = NSRunAlertPanel(@"You have been idle", 
                                           @"You have been idle for more than %.0f minutes.\
                                           Do you want to stop recording the current task?\
                                           (Remember to check the end time of the work period)",
                                           @"Stop recording", @"Continue recording", nil, idleTime/60);
        if (answer == NSAlertDefaultReturn) {
            [self stopRecording:sender];
            [editWorkperiodPanel makeKeyAndOrderFront:sender];
            [editWorkperiodPanel makeFirstResponder:endtimeDatePicker];
        } else {
            [self checkIdleTime:sender];
        }
    } else {
        NSTimeInterval nextTime = 1.0 + idleTimeInterval - idleTime;
        LOG(@"next time to checkIdleTime: %@ (%.1f s from now)", 
            [[NSDate dateWithTimeIntervalSinceNow:nextTime] asTimeString], nextTime);
        idleTimer = [NSTimer scheduledTimerWithTimeInterval:nextTime
                                                     target:self
                                                   selector:@selector(checkIdleTime:)
                                                   userInfo:nil
                                                    repeats:NO];
    }
}


#pragma mark ---- Recording ----

@dynamic isRecording;
- (BOOL) isRecording {
    return isRecording;
}
- (void) setIsRecording: (BOOL) isrec {
    isRecording = isrec;
    [self checkIdleTime:nil];
}

- (void) tickTheClock: (id) sender {
    if ([self isRecording]) { 
        [self setCurrentDuration:[NSNumber numberWithDouble:
                                  -[[[self currentWorkPeriod] start] timeIntervalSinceNow]]];
    } else {
        [self setCurrentStartTime:[NSDate date]];
    }
}

- (void) startRecordingTask: (Task*) newTask {
    if ([self isRecording]) {
        // If already recording this task, don't to anything (i.e., return)
        if ([[self currentWorkPeriod] task] == newTask) 
            return;
        [self stopRecording:nil];
    }
    
    [[NSApp delegate] performSelector:@selector(changeContentView:) withObject:nil];
    [[NSApp delegate] performSelector:@selector(changeViewPeriodDate:) withObject:nil];
    [[self managedObjectContext] beginUndoGroup: @"Start Recording"];
    WorkPeriod* work = [self addForTask:newTask start:[NSDate date] duration:-1];
    [self setRecordingTo:work];
    [[self managedObjectContext] endUndoGroup];
}

- (IBAction) stopRecording: (id) sender { 
    if (![self isRecording]) return;
    LOG(@"stopRecording: %@", [sender className]);
    [[self managedObjectContext] beginUndoGroup:@"Stop Recording"];
    NSTimeInterval duration = -[[[self currentWorkPeriod] start] timeIntervalSinceNow];
    NSTimeInterval minimumDuration = [PREFS doubleForKey:@"minimumWorkPeriodLength"];
    if (duration < minimumDuration) {
        [self removeObject:[self currentWorkPeriod]];
        LOG(@"Discarded too short work period (%0.0f s)", duration);
    } 
    [[self currentWorkPeriod] setDuration:[NSNumber numberWithDouble:duration]];
    [self setRecordingTo:nil];
    [[self managedObjectContext] endUndoGroup];
    [self fetch:sender];
}

- (void) setRecordingTo: (WorkPeriod*) work {
    if (work) {
        LOG(@"setRecordingTo: %@", [[work task] longName]);
        [[[[self managedObjectContext] undoManager] 
          prepareWithInvocationTarget:self] setRecordingTo:nil];
        [self setIsRecording:YES];
        [self setCurrentStartTime:[work start]];
        [self setCurrentWorkPeriod:work];
    } else {
        LOG(@"setRecordingTo: NIL");
        [[[[self managedObjectContext] undoManager] 
          prepareWithInvocationTarget:self] setRecordingTo:[self currentWorkPeriod]];
        [self setIsRecording:NO];
        [self setCurrentDuration:nil];
        [self setCurrentWorkPeriod:nil];
    }
    [self tableViewSelectionDidChange:nil];
    [self synchronizeStatusTitle];
    [self tickTheClock:nil];
}

#pragma mark ---- Information on the status line ----

@synthesize totalDuration; 
- (void) updateTotalDuration: (id) sender {
    NSTimeInterval duration = 0;
    for (WorkPeriod* work in [self arrangedObjects]) {
        if ([work isEqual:currentWorkPeriod])
            duration += [[self currentDuration] doubleValue];
        else 
            duration += [[work duration] doubleValue];
    }
    LOG(@"updateTotalDuration => %0.1f min", duration/60);
    [self setTotalDuration:duration];
}

@dynamic numberOfSelectedObjects;
- (NSNumber*) numberOfSelectedObjects {
    return [NSNumber numberWithInt:[[self arrangedObjects] count]];
}


#pragma mark ---- The status menu/item

- (void) initStatusMenu {
    LOG(@"initStatusMenu");
    statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [statusItem setHighlightMode:YES];
    [statusItem setToolTip:@"KronoX Task Timer"];
    [statusItem setMenu:recordingMenu];
    NSImage* statusMenuImage = [NSImage imageNamed: @"StatusMenuIcon.tiff"];
    [statusItem setImage:statusMenuImage];
}

- (void) synchronizeStatusTitle {
    Task* task = [[self currentWorkPeriod] task];
    LOG(@"synchronizeStatusTitle: %@", [task longName]);
    if (task) {
        NSString* title; 
        CGFloat size;
        NSMutableDictionary* attrs = [NSMutableDictionary dictionary];
        if ([PREFS boolForKey: @"statusItemBackgroundColorEnabled"]) {
            NSColor* bgColor = [NSKeyedUnarchiver unarchiveObjectWithData: 
                                [PREFS dataForKey:@"statusItemBackgroundColor"]];
            if (bgColor != nil) {
                [attrs setValue:bgColor forKey:NSBackgroundColorAttributeName];
            }
        }
        if ([PREFS boolForKey: @"statusItemForegroundColorEnabled"]) {
            NSColor* fgColor = [task color];
            if (fgColor != nil) {
                [attrs setValue:fgColor forKey:NSForegroundColorAttributeName];
            }
        }
        int ix = [PREFS integerForKey: @"statusItemSymbolIndex"];
        if (ix == 0) {
            // title = @" ⟳ ↻ ∞ ⌘ ✍ ☞  ⟳⃝  ↻⃝  ∞⃝  ⌘⃝  ✍⃝  ☞⃝  ⟳⃣  ↻⃣  ∞⃣  ⌘⃣  ✍⃣  ☞⃣ ";
            title = @"✔";
            size = 2.0 + [NSFont systemFontSize];
        } else {
            title = [NSString stringWithFormat:@" %@ ", (ix == 1 ? [task name] : [task longName])];
            size = [NSFont smallSystemFontSize];
        }
        [attrs setValue:[NSFont menuBarFontOfSize:size] forKey:NSFontAttributeName];
        [statusItem setAttributedTitle:[[NSAttributedString alloc] initWithString:title attributes:attrs]];
    } else {
        [statusItem setTitle:@""];
    }
}


#pragma mark ---- Updating ----

- (void) fetch: (id) sender {
    LOG(@"fetch: %@", [sender className]);
    // Sometimes, we call fetch: while the editWorkperiodPanel is in the middle of an edit. In these,
    // cases, if we don't do anything, we'll lose that edit. So, what we do is that we focus on the
    // panel itself to force an edit commit.
    if ([editWorkperiodPanel isKeyWindow]) {
        [editWorkperiodPanel makeFirstResponder:nil];
    }
    [super fetch:sender];
    [self synchronizeStatusTitle];
    
    // this is so that bindings on currentWorkPeriod also will be updated:
    [self setCurrentWorkPeriod:[self currentWorkPeriod]];
    
    // we have to schedule the status line updating, until all data have been
    // fetched from the database:
    [NSTimer scheduledTimerWithTimeInterval:0
                                     target:self
                                   selector:@selector(updateTotalDuration:)
                                   userInfo:nil
                                    repeats:NO];
}

#pragma mark ---- Adding, removing ----

- (void) remove: (id) sender {
    [[self managedObjectContext] beginUndoGroup:@"Remove Work Period"];
    if (isRecording && [[self selectedObjects] containsObject:[self currentWorkPeriod]]) {
        [self setRecordingTo:nil];
    }
    [super remove:sender];
    [[self managedObjectContext] endUndoGroup];
}

- (WorkPeriod*) newWorkPeriod {
    return [NSEntityDescription insertNewObjectForEntityForName:@"WorkPeriod" 
                                         inManagedObjectContext:[self managedObjectContext]];
}

- (WorkPeriod*) addForTask: (Task*) task 
                     start: (NSDate*) start
                  duration: (NSTimeInterval) duration
{
    WorkPeriod* work = [self newWorkPeriod];
    [work setTask:task];
    [work setStart:start];
    if (duration >= 0) {
        [work setDuration:[NSNumber numberWithDouble:duration]];
    }
    [self addObject:work];
    LOG(@"addForTask: %@  duration: %f  start: %@", [task name], duration, start);
    [[NSApp delegate] performSelector:@selector(saveManagedObjectContext:) withObject:work];
    return work;
}

- (void) addForTask: (Task*) task { 
    // calculate duration
    NSTimeInterval defaultDuration = [PREFS doubleForKey:@"standardWorkPeriodLength"];
    // calculate start time
    NSDate* start = [[NSApp delegate] performSelector:@selector(viewPeriodDate)];
    start = [start filterThroughComponents:[NSDate dateUnits]];
    start = [start addComponents:[[NSDate date] components:[NSDate timeUnits]]];
    start = [start dateByAddingTimeInterval:-defaultDuration];
    // set the date filter, just in case the start time is on another date than the current date filter (= the end time)
    [[NSApp delegate] performSelector:@selector(changeViewPeriodDate:) withObject:start];
    // create and add the new WP
    [[self managedObjectContext] beginUndoGroup:@"Add Work Period"];
    [self addForTask:task start:start duration:defaultDuration];
    [[self managedObjectContext] endUndoGroup];
}

#pragma mark ---- Delegate methods ----

- (void) tableViewSelectionDidChange: (NSNotification*) notification {
    BOOL cannotChange = isRecording && [[self selectedObjects] containsObject:[self currentWorkPeriod]];
    [self setCanChangeDate:!cannotChange];
}

@end
