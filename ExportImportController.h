//
//  ExportImportController.h
//  KronoX
//
//  Created by Peter Ljunglöf on 2008-10-29.
//  Copyright 2008 Heatherleaf. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WorkPeriodController.h"

@interface ExportImportController : NSObject {
	// Outlets
	IBOutlet NSPanel* progressPanel;
	IBOutlet NSProgressIndicator* progressIndicator;
	IBOutlet NSView* exportTextView;
	IBOutlet NSView* exportICalView;
	IBOutlet WorkPeriodController* workPeriodController;
	
	// Bindings
	NSDate* exportFromDate;
	NSDate* exportToDate;
	NSString* exportDelimitor;
	NSStringEncoding exportEncoding;
	int exportCalendar;
	NSArray* iCalCalendars;
}

@property (copy) NSDate* exportFromDate;
@property (copy) NSDate* exportToDate;
@property (copy) NSString* exportDelimitor;
@property NSStringEncoding exportEncoding;
@property int exportCalendar;
@property (copy) NSArray* iCalCalendars;

- (IBAction) exportToFile: (id) sender;
- (IBAction) exportToICal: (id) sender;

@end
