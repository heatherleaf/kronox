//
//  RecordingMenuDelegate.m
//  KronoX
//
//  Created by Peter Ljunglöf on 2008-10-09.
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

#import "RecordingMenuDelegate.h"

#define EXTRA_ITEMS_ON_TOP 4

@implementation RecordingMenuDelegate

NSImage* disclosureRight;
NSImage* disclosureDown;
NSImage* disclosureTransparent;

- (void) awakeFromNib {
	LOG(@"awakeFromNib");
	disclosureRight = [NSImage imageNamed: @"DisclosureRight.tiff"];
	disclosureDown = [NSImage imageNamed: @"DisclosureDown.tiff"];
	disclosureTransparent = [NSImage imageNamed: @"DisclosureTransparent.tiff"];
}

- (NSInteger) numberOfItemsInMenu: (NSMenu*) menu {
    NSInteger nrows = [tasksView numberOfRows] + EXTRA_ITEMS_ON_TOP;
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

	NSTreeNode* node = [tasksView itemAtRow: index];
	Task* task = [node representedObject];

	if ([workPeriodController isRecording] &&
		[task isEqual: [[workPeriodController currentWorkPeriod] task]])
		[item setState: NSOnState];
	else [item setState: NSOffState];
	[item setRepresentedObject: node];
	[item setTarget: tasksController];
	[item setAction: @selector(startRecording:)];

	NSUInteger indent = [[node indexPath] length] - 1;
	[item setIndentationLevel: indent];
	NSString* title = [task name];
	NSFont* font = [NSFont systemFontOfSize: [PREFS floatForKey: @"fontSize"]];
	NSDictionary* attrs = [NSDictionary dictionaryWithObjectsAndKeys:
						   [task color], NSForegroundColorAttributeName,
						   font, NSFontAttributeName,
						   nil];
	[item setAttributedTitle: [[NSAttributedString alloc] initWithString: title
															  attributes: attrs]];

	if ([node isLeaf])
		[item setImage: disclosureTransparent];
	else if ([tasksView isItemExpanded: node])
		[item setImage: disclosureDown];
	else
		[item setImage: disclosureRight];

	return YES;
}

@end
