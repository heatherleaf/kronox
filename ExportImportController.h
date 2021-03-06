//
//  ExportImportController.h
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
