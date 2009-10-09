//
//  ColumnsMenuDelegate.m
//  KronoX
//
//  Created by Peter Ljunglöf on 2009-09-21.
//  Copyright 2009 Heatherleaf. All rights reserved.
//
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

#import "ColumnsMenuDelegate.h"

#define EXTRA_ITEMS_ON_TOP 2

@implementation ColumnsMenuDelegate

- (void) awakeFromNib {
	LOG(@"awakeFromNib");
}

- (NSInteger) numberOfItemsInMenu: (NSMenu*) menu {
    NSInteger nrows = [[[enclosingView documentView] tableColumns] count] + EXTRA_ITEMS_ON_TOP;
    LOG(@"numberOfItemsInMenu: %d", nrows);
	return nrows;
}

- (BOOL) menu: (NSMenu*) menu
   updateItem: (NSMenuItem*) item 
	  atIndex: (NSInteger) index
 shouldCancel: (BOOL) shouldCancel
{
	index -= EXTRA_ITEMS_ON_TOP;
	if (index < 0) return YES;

    NSTableColumn* column = [[[enclosingView documentView] tableColumns] objectAtIndex:index];
    NSString* title = [[column headerCell] stringValue];
    [item setTitle:title];
    [item setState:([column isHidden] ? NSOffState : NSOnState)];
    [item setRepresentedObject:column];
    [item setTarget:self];
    [item setAction:@selector(toggleVisibility:)];
	return YES;
}

- (void) toggleVisibility: (id) sender {
    id object = sender;
    if ([sender isKindOfClass:[NSMenuItem class]]) 
        object = [sender representedObject];
    LOG(@"toggleColumnVisbility: -> %@", [object isHidden] ? @"YES" : @"NO");
    [object setHidden:![object isHidden]];
}

@end
