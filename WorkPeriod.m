// 
//  WorkPeriod.m
//  KronoX
//
//  Created by Peter Ljunglöf on 2008-02-23.
//  Copyright 2008 Heatherleaf. All rights reserved.
//

#import "WorkPeriod.h"

#import "Task.h"

@implementation WorkPeriod 

@dynamic start;
@dynamic duration;
@dynamic comment;
@dynamic task;

@dynamic end;
- (NSDate*) end {
	if (self.duration == nil) return nil;
	return [self.start addTimeInterval: [self.duration doubleValue]];
}

#define SECONDS_PER_DAY (24*60*60)

- (void) setEnd: (NSDate*) date {
	if (self.start == nil) return;
	NSTimeInterval dur = [date timeIntervalSinceDate: self.start];
	while (dur < 0) 
		dur += SECONDS_PER_DAY;
	while (dur > SECONDS_PER_DAY)
		dur -= SECONDS_PER_DAY;
	self.duration = [NSNumber numberWithDouble: dur];
}

@end
