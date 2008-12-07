//
//  TimeIntervalToString.m
//  KronoX
//
//  Created by Peter Ljunglöf on 2008-04-03.
//  Copyright 2008 Heatherleaf. All rights reserved.
//

#import "TimeIntervalToString.h"


@implementation TimeIntervalToString

+ (Class) transformedValueClass { 
	return [NSString class]; 
}

+ (BOOL) allowsReverseTransformation { 
	return NO; 
}

- (NSString*) transformedValue: (NSNumber*) time {
	if (time == nil) return nil;
	if (![time intValue]) return nil;
	NSString* interval;
	int minutes = ([time intValue] + 30) / 60;
	switch ([PREFS integerForKey: @"durationAppearance"]) {
		case 0:
			interval = [NSString stringWithFormat: @"%02d:%02d", minutes/60, minutes%60];
			break;
		case 1:
			interval = [NSString stringWithFormat: @"%.1fh", (float)minutes/60];
			break;
	}
	return interval;
}

@end
