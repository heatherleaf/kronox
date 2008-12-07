//
//  TimeIntervalToDate.m
//  KronoX
//
//  Created by Peter Ljunglöf on 2008-03-02.
//  Copyright 2008 Heatherleaf. All rights reserved.
//

#import "TimeIntervalToDate.h"


@implementation TimeIntervalToDate

+ (Class) transformedValueClass { 
	return [NSDate class]; 
}

+ (BOOL) allowsReverseTransformation { 
	return YES; 
}

- (NSDate*) transformedValue: (NSNumber*) time {
	if (time == nil) return nil;
	NSTimeZone* tz = [NSTimeZone defaultTimeZone];
	NSTimeInterval seconds = [time doubleValue] - [tz secondsFromGMT];
	if ([tz isDaylightSavingTime]) 
		seconds += [tz daylightSavingTimeOffset];
	return [NSDate dateWithTimeIntervalSinceReferenceDate: seconds];
}

- (NSNumber*) reverseTransformedValue: (NSDate*) date {
	if (date == nil) return nil;
	NSTimeZone* tz = [NSTimeZone defaultTimeZone];
	NSTimeInterval seconds = [date timeIntervalSinceReferenceDate] + [tz secondsFromGMT];
	if ([tz isDaylightSavingTime]) 
		seconds -= [tz daylightSavingTimeOffset];
	return [NSNumber numberWithDouble: seconds];
}

@end
