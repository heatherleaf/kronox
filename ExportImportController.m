//
//  ExportImportController.m
//  KronoX
//
//  Created by Peter Ljunglöf on 2008-10-29.
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

#import "ExportImportController.h"

@implementation ExportImportController

@synthesize exportFromDate, exportToDate, exportDelimitor, exportEncoding, exportCalendar, iCalCalendars;

- (IBAction) exportToFile: (id) sender {
    NSSavePanel* sp = [NSSavePanel savePanel];
    [sp setTitle:@"Export to Text File"];
    [sp setRequiredFileType:@"txt"];
    [sp setAllowsOtherFileTypes:YES];
    [sp setCanSelectHiddenExtension:YES];
    [sp setAccessoryView:exportTextView];
    [self setExportDelimitor:@", "];
    [self setExportEncoding:NSUTF8StringEncoding];
    
    int result = [sp runModalForDirectory:nil file:@"KronoX-data"];
    if (result != NSOKButton) return;
    
    [progressPanel setTitle:@"Exporting to text"];
    NSModalSession exportSession = [NSApp beginModalSessionForWindow:progressPanel];
    [progressIndicator setIndeterminate:YES];
    [progressIndicator startAnimation:self];
    
    NSArray* periods = [workPeriodController arrangedObjects];
    LOG(@"Nr. work periods to export: %d", [periods count]);
    
    NSStringEncoding encoding = [self exportEncoding];
    if (!encoding) encoding = NSUTF8StringEncoding;
    
    NSString* delim = [self exportDelimitor];
    if (!delim) delim = @", ";
    if ([delim isEqualToString:@"TAB"]) delim = @"\t";
    
    [progressIndicator setIndeterminate:NO];
    [progressIndicator setMaxValue:[periods count]];
    [progressIndicator setDoubleValue:0];
    int incrementInterval = 1 + [periods count] / 50;
    
    int counter = 0;
    BOOL didCancel = NO;
    NSMutableString* textData = [NSMutableString string];
    for (WorkPeriod* work in periods) {
        [progressIndicator incrementBy:1];
        didCancel = !(counter++ % incrementInterval) && [NSApp runModalSession:exportSession] != NSRunContinuesResponse;
        if (didCancel)
            break;
        [textData appendFormat:@"%@%@%@%@%@%@%@%@%@\n", 
         [[work start] description],    delim,
         [[work end] description],      delim,
         [[work duration] stringValue], delim,
         [[work task] longName],        delim,
         [[work comment] stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"]];
        // perhaps use [comment stringByAddingPercentEscapesUsingEncoding:encoding]
        // but it doesn't escape "," ";" ":", which nevertheless gives us problems with ","-separation
    }
    
    if (didCancel) {
        LOG(@"Did cancel");
    } else {
        NSError* error;
        if (![textData writeToFile:[sp filename] atomically:YES encoding:encoding error:&error]) {
            [NSApp presentError:error];
        } else {
            NSRunAlertPanel(@"Finished exporting", 
                            @"%d work periods exported to file\n%@",
                            @"OK", nil, nil,
                            [periods count], [sp filename]);
        }
        LOG(@"Finished exporting");
    }
    
    [NSApp endModalSession:exportSession];
    [progressPanel orderOut:self];
}

- (IBAction) exportToICal: (id) sender {
    CalCalendarStore* store = [CalCalendarStore defaultCalendarStore];
    
    NSAlert* alert = [[NSAlert alloc] init];
    [alert setMessageText:@"Export to iCal"];
    [alert setInformativeText:@"Existing events will not be duplicated\nIt can be wise to quit iCal before exporting"];
    [alert addButtonWithTitle:@"Export"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setAccessoryView:exportICalView];
    [self setICalCalendars:[[[CalCalendarStore defaultCalendarStore] calendars] valueForKey:@"title"]];
    
    int result = [alert runModal];
    if (result != NSAlertFirstButtonReturn) return;
    CalCalendar* calendar = [[store calendars] objectAtIndex:[self exportCalendar]];
    
    [progressPanel setTitle:@"Exporting to iCal"];
    NSModalSession exportSession = [NSApp beginModalSessionForWindow:progressPanel];
    [progressIndicator setIndeterminate:YES];
    
    int    hoursToAdd = [PREFS integerForKey:@"dateChangeHour"];
    NSDate* fromDate = [[NSApp delegate] performSelector:@selector(getViewPeriodStart)]; 
    NSDate* uptoDate = [[NSApp delegate] performSelector:@selector(getViewPeriodEnd)]; 
    if (!uptoDate) uptoDate = [NSDate date];
    if (!fromDate) fromDate = [uptoDate addMonths:-24];
    fromDate = [fromDate lastMidnight];
    uptoDate = [[uptoDate lastMidnight] addHours:24+hoursToAdd];
    NSPredicate* eventsPredicate = [CalCalendarStore eventPredicateWithStartDate:fromDate
                                                                         endDate:[uptoDate addDays:1]
                                                                       calendars:[NSArray arrayWithObject:calendar]];
    NSMutableSet* existingEvents = [NSMutableSet set];
    for (CalEvent* event in [store eventsWithPredicate:eventsPredicate]) {
        [existingEvents addObject:[[event title] stringByAppendingFormat:@";%@;%@", 
                                   [[event startDate] description], [[event endDate] description]]];
    }
    LOG(@"Nr. existing events in iCal calendar: %d", [existingEvents count]);
    
    NSArray* periods = [workPeriodController arrangedObjects];
    LOG(@"Nr. work periods to export: %d", [periods count]);
    
    [progressIndicator setIndeterminate:NO];
    [progressIndicator setMaxValue:[periods count]];
    [progressIndicator setDoubleValue:0];
    int incrementInterval = 1 + [periods count] / 50;
    
    int exported = 0;
    int counter = 0;
    BOOL didCancel = NO;
    for (WorkPeriod* work in periods) {
        [progressIndicator incrementBy:1];
        didCancel = !(counter++ % incrementInterval) && [NSApp runModalSession:exportSession] != NSRunContinuesResponse;
        if (didCancel)
            break;
        if ([existingEvents containsObject:[[[work task] longName] stringByAppendingFormat:@";%@;%@", 
                                             [[work start] description], [[work end] description]]])
            continue;
        
        CalEvent* event = [CalEvent event];
        [event setCalendar:calendar];
        [event setTitle:[[work task] longName]];
        [event setNotes:[work comment]];
        [event setStartDate:[work start]];
        [event setEndDate:[work end]];
        
        NSError* error;
        if (![store saveEvent:event span:CalSpanThisEvent error:&error]) {
            [NSApp presentError:error];
            break;
        }
        exported++;
    }
    
    if (didCancel)
        LOG(@"Did cancel");
    LOG(@"Nr. exported events: %d", exported);
    NSRunAlertPanel(@"Finished exporting", 
                    @"%d work periods (out of %d) exported to iCal calendar %@",
                    @"OK", nil, nil,
                    exported, [periods count], [calendar title]);
    
    [NSApp endModalSession:exportSession];
    [progressPanel orderOut:self];
}


@end
