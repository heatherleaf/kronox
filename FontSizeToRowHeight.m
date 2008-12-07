//
//  FontSizeToRowHeight.m
//  KronoX
//
//  Created by Peter Ljunglöf on 2008-05-02.
//  Copyright 2008 Heatherleaf. All rights reserved.
//

#import "FontSizeToRowHeight.h"


@implementation FontSizeToRowHeight

+ (Class) transformedValueClass { 
	return [NSNumber class]; 
}

+ (BOOL) allowsReverseTransformation { 
	return NO; 
}

- (NSNumber*) transformedValue: (NSNumber*) fontSize {
	return [NSNumber numberWithDouble: 4 + [fontSize doubleValue]];
}

@end
