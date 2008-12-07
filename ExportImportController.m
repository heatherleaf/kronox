//
//  ExportImportController.m
//  KronoX
//
//  Created by Peter Ljunglöf on 2008-10-29.
//  Copyright 2008 Heatherleaf. All rights reserved.
//

#import "ExportImportController.h"

@implementation ExportImportController

@synthesize exportFromDate, exportToDate, exportDelimitor, exportEncoding, exportCalendar, iCalCalendars;

- (IBAction) exportToFile: (id) sender {
	NSSavePanel* sp = [NSSavePanel savePanel];
	[sp setTitle: @"Export to Text File"];
	[sp setRequiredFileType: @"txt"];
	[sp setAllowsOtherFileTypes: YES];
	[sp setCanSelectHiddenExtension: YES];
	[sp setAccessoryView: exportTextView];
	self.exportDelimitor = @", ";
	self.exportEncoding  = NSUTF8StringEncoding;
	
	int result = [sp runModalForDirectory: nil file: @"KronoX-data"];
	if (result != NSOKButton) return;
	
	[progressPanel setTitle: @"Exporting to text"];
	NSModalSession exportSession = [NSApp beginModalSessionForWindow: progressPanel];
	[progressIndicator setIndeterminate: YES];
	[progressIndicator startAnimation: self];
	
	NSArray* periods = [workPeriodController arrangedObjects];
	LOG(@"Nr. work periods to export: %d", [periods count]);
	
	NSStringEncoding encoding = self.exportEncoding;
	if (!encoding) encoding = NSUTF8StringEncoding;
	
	NSString* delim = self.exportDelimitor;
	if (!delim) delim = @", ";
	if ([delim isEqualToString: @"TAB"]) delim = @"\t";
	
	[progressIndicator setIndeterminate: NO];
	[progressIndicator setMaxValue: [periods count]];
	[progressIndicator setDoubleValue: 0];
	int incrementInterval = 1 + [periods count] / 50;
	
	int counter = 0;
	BOOL didCancel = NO;
	NSMutableString* textData = [NSMutableString string];
	for (WorkPeriod* work in periods) {
		[progressIndicator incrementBy: 1];
		if (!(counter++ % incrementInterval) && 
			[NSApp runModalSession: exportSession] != NSRunContinuesResponse) {
			didCancel = YES;
			break;
		}
		[textData appendFormat: @"%@%@%@%@%@%@%@%@%@\n", 
		 [work.start description],    delim,
		 [work.end description],      delim,
		 [work.duration stringValue], delim,
		 work.task.longName,          delim,
		 [work.comment stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"]];
		// kanske använda [comment stringByAddingPercentEscapesUsingEncoding: encoding]?
		// fast den escapear inte "," ";" ":" vilket iallafall blir problem med ","-separering
	}
	
	if (didCancel) {
		LOG(@"Did cancel");
	} else {
		NSError* error;
		if (![textData writeToFile: [sp filename]
						atomically: YES
						  encoding: encoding
							 error: &error]) {
			[NSApp presentError: error];
		} else {
			NSRunAlertPanel(@"Finished exporting", 
							@"%d work periods exported to file\n%@",
							@"OK", nil, nil,
							[periods count], [sp filename]);
		}
		LOG(@"Finished exporting");
	}
	
	[NSApp endModalSession: exportSession];
	[progressPanel orderOut: self];
}

- (IBAction) exportToICal: (id) sender {
	CalCalendarStore* store = [CalCalendarStore defaultCalendarStore];
	
	NSAlert* alert = [[NSAlert alloc] init];
	[alert setMessageText: @"Export to iCal"];
	[alert setInformativeText: @"Existing events will not be duplicated\nIt can be wise to quit iCal before exporting"];
	[alert addButtonWithTitle: @"Export"];
	[alert addButtonWithTitle: @"Cancel"];
	[alert setAccessoryView: exportICalView];
	self.iCalCalendars = [[[CalCalendarStore defaultCalendarStore] calendars] valueForKey: @"title"];
	
	int result = [alert runModal];
	if (result != NSAlertFirstButtonReturn) return;
	CalCalendar* calendar = [[store calendars] objectAtIndex: self.exportCalendar];
	
	[progressPanel setTitle: @"Exporting to iCal"];
	NSModalSession exportSession = [NSApp beginModalSessionForWindow: progressPanel];
	[progressIndicator setIndeterminate: YES];
	
	int	hoursToAdd = [PREFS integerForKey: @"dateChangeHour"];
	NSDate* fromDate = [[NSApp delegate] performSelector:@selector(getViewPeriodStart)]; 
	NSDate* uptoDate = [[NSApp delegate] performSelector:@selector(getViewPeriodEnd)]; 
	if (!uptoDate) uptoDate = [NSDate date];
	if (!fromDate) fromDate = [uptoDate addMonths:-24];
	fromDate = [fromDate lastMidnight];
	uptoDate = [[uptoDate lastMidnight] addHours: 24+hoursToAdd];
	NSPredicate* eventsPredicate = [CalCalendarStore eventPredicateWithStartDate: fromDate
																		 endDate: [uptoDate addDays:1]
																	   calendars: [NSArray arrayWithObject: calendar]];
	NSMutableSet* existingEvents = [NSMutableSet set];
	for (CalEvent* event in [store eventsWithPredicate: eventsPredicate]) {
		[existingEvents addObject: [event.title stringByAppendingFormat: @";%@;%@", 
									[event.startDate description], [event.endDate description]]];
	}
	LOG(@"Nr. existing events in iCal calendar: %d", [existingEvents count]);
	
	NSArray* periods = [workPeriodController arrangedObjects];
	LOG(@"Nr. work periods to export: %d", [periods count]);
	
	[progressIndicator setIndeterminate: NO];
	[progressIndicator setMaxValue: [periods count]];
	[progressIndicator setDoubleValue: 0];
	int incrementInterval = 1 + [periods count] / 50;
	
	int exported = 0;
	int counter = 0;
	for (WorkPeriod* work in periods) {
		[progressIndicator incrementBy: 1];
		if (!(counter++ % incrementInterval) && 
			[NSApp runModalSession: exportSession] != NSRunContinuesResponse) {
			break;
		}
		if ([existingEvents containsObject: [work.task.longName stringByAppendingFormat: @";%@;%@", 
											 [work.start description], [work.end description]]])
			continue;
		
		CalEvent* event = [CalEvent event];
		event.calendar = calendar;
		event.title = work.task.longName;
		event.notes = work.comment;
		event.startDate = work.start;
		event.endDate = work.end;
		
		NSError* error;
		if (![store saveEvent:event span:CalSpanThisEvent error:&error]) {
			[NSApp presentError:error];
			break;
		}
		exported++;
	}
	
	LOG(@"Nr. exported events: %d", exported);
	NSRunAlertPanel(@"Finished exporting", 
					@"%d work periods (out of %d) exported to iCal calendar %@",
					@"OK", nil, nil,
					exported, [periods count], calendar.title);
	
	[NSApp endModalSession: exportSession];
	[progressPanel orderOut: self];
}


@end
