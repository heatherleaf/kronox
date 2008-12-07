//
//  PanelExtensions.m
//  KronoX
//
//  Created by Peter Ljunglöf on 2008-03-29.
//  Copyright 2008 Heatherleaf. All rights reserved.
//

#import "PanelExtensions.h"


@implementation NSPanel (PanelExtensions)

- (void) toggleVisibility: (id) sender {
	if ([self isKeyWindow]) {
		[self orderOut: sender];
	} else {
		[self makeKeyAndOrderFront: sender];
	}
}

@end
