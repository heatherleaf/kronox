//
//  SplitViewDelegate.m
//  KronoX
//
//  Created by Peter Ljunglöf on 2008-10-13.
//  Copyright 2008 Heatherleaf. All rights reserved.
//

#import "SplitViewDelegate.h"


@implementation SplitViewDelegate

- (CGFloat)     splitView: (NSSplitView*) sender 
   constrainMaxCoordinate: (CGFloat) proposedMax
			  ofSubviewAt: (int) offset
{
	NSRect theFrame = [[NSApp mainWindow] frame];
	return theFrame.size.width - 300;
}

- (CGFloat)     splitView: (NSSplitView*) sender 
   constrainMinCoordinate: (CGFloat) proposedMin
			  ofSubviewAt: (int) offset
{
	return 100;
}



@end
