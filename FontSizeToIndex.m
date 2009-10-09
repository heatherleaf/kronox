//
//  FontSizeToIndex.m
//  KronoX
//
//  Created by Peter Ljunglöf on 2008-04-01.
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
	return [NSNumber numberWithInt:index];
}

- (NSNumber*) reverseTransformedValue: (NSNumber*) index {
	switch ([index intValue]) {
		case 1:  return [NSNumber numberWithDouble: SmallSize];
		case 2:  return [NSNumber numberWithDouble: MiniSize];
		default: return [NSNumber numberWithDouble: NormalSize];
	}
}

@end
