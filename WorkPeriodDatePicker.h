//
//  WorkPeriodDatePicker.h
//  KronoX
//
//  Created by Peter Ljunglöf on 2008-10-08.
//  Copyright 2008 Heatherleaf. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WorkPeriodController.h"


@interface WorkPeriodDatePicker : NSDatePicker {
	IBOutlet WorkPeriodController* workPeriodController;
	NSArray* selectedWorkPeriods;
}

@property (copy) NSArray* selectedWorkPeriods;

- (BOOL) becomeFirstResponder;
- (void) mouseDown: (NSEvent*) event;

@end
