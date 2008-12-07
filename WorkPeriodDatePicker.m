//
//  WorkPeriodDatePicker.m
//  KronoX
//
//  Created by Peter Ljunglöf on 2008-10-08.
//  Copyright 2008 Heatherleaf. All rights reserved.
//

#import "WorkPeriodDatePicker.h"


@implementation WorkPeriodDatePicker

@synthesize selectedWorkPeriods;

- (void) selectWPs {
	self.selectedWorkPeriods = [workPeriodController selectedObjects];
	LOG(@"selectWPs: %d", [self.selectedWorkPeriods count]);
}

- (BOOL) becomeFirstResponder {
	[self selectWPs];
	return YES;
}

- (void) mouseDown: (NSEvent*) event {
	[self selectWPs];
	[super mouseDown: event];
}

@end
