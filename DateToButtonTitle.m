//
//  DateToButtonTitle.m
//  KronoX
//
//  Created by Peter Ljunglöf on 2008-03-23.
//  Copyright 2008 Heatherleaf. All rights reserved.
//

#import "DateToButtonTitle.h"


@implementation DateToButtonTitle

+ (Class) transformedValueClass { 
	return [NSString class]; 
}

+ (BOOL) allowsReverseTransformation { 
	return NO; 
}

+ (NSString*) transformedValue: (NSDate*) date {
	if (date == nil) return nil;
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateStyle: NSDateFormatterLongStyle];
	[dateFormatter setTimeStyle: NSDateFormatterNoStyle];
	return [dateFormatter stringFromDate: date];
}

- (NSString*) transformedValue: (NSDate*) date {
	return [DateToButtonTitle transformedValue: date];
}


@end
