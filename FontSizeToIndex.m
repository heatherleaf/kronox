//
//  FontSizeToIndex.m
//  KronoX
//
//  Created by Peter Ljunglöf on 2008-04-01.
//  Copyright 2008 Heatherleaf. All rights reserved.
//

#import "FontSizeToIndex.h"


@implementation FontSizeToIndex

#define NormalSize [NSFont systemFontSize]
#define SmallSize  [NSFont smallSystemFontSize]
#define MiniSize   [NSFont systemFontSizeForControlSize: NSMiniControlSize]

+ (Class) transformedValueClass { 
	return [NSNumber class]; 
}

+ (BOOL) allowsReverseTransformation { 
	return YES; 
}

- (NSNumber*) transformedValue: (NSNumber*) fontSize {
	int index = 1 + SmallSize - [fontSize intValue];
	if (index < 0) index = 0;
	if (index > 2) index = 2;
	return [NSNumber numberWithInt: index];
}

- (NSNumber*) reverseTransformedValue: (NSNumber*) index {
	double size;
	switch ([index intValue]) {
		case 0:  size = NormalSize; break;
		case 1:  size = SmallSize;  break;
		case 2:  size = MiniSize;   break;
	}
	return [NSNumber numberWithDouble: size];
}

@end
