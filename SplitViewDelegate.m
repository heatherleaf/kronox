//
//  SplitViewDelegate.m
//  KronoX
//
//  Created by Peter Ljunglöf on 2008-10-13.
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

#import "SplitViewDelegate.h"

@implementation SplitViewDelegate

#define MIN_WIDTH 100

- (CGFloat) splitView:(NSSplitView*)sender constrainMaxCoordinate:(CGFloat)max ofSubviewAt:(NSInteger)offset {
	return [[NSApp mainWindow] frame].size.width - 300;
}

- (CGFloat) splitView:(NSSplitView*)sender constrainMinCoordinate:(CGFloat)min ofSubviewAt:(NSInteger)offset {
	return MIN_WIDTH;
}

// Only the right subview should be resized
- (void) splitView:(NSSplitView*)sender resizeSubviewsWithOldSize:(NSSize)oldSize {
    NSView* leftSubView = [[sender subviews] objectAtIndex:0];
    NSView* rightSubView = [[sender subviews] objectAtIndex:1];
    
    NSRect newFrame = [sender frame];
    NSRect leftFrame = [leftSubView frame];
    NSRect rightFrame = [rightSubView frame];
	
    leftFrame.size.height = rightFrame.size.height = newFrame.size.height;
    rightFrame.size.width = newFrame.size.width - leftFrame.size.width - [sender dividerThickness];
    
    [leftSubView setFrame:leftFrame];
    [rightSubView setFrame:rightFrame];
}

@end
