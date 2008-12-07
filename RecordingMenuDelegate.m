//
//  RecordingMenuDelegate.m
//  KronoX
//
//  Created by Peter Ljunglöf on 2008-10-09.
//  Copyright 2008 Heatherleaf. All rights reserved.
//

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
	return [tasksView numberOfRows] + EXTRA_ITEMS_ON_TOP;
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
	NSString* title = task.name;
	NSFont* font = [NSFont systemFontOfSize: [PREFS floatForKey: @"fontSize"]];
	NSDictionary* attrs = [NSDictionary dictionaryWithObjectsAndKeys:
						   task.color, NSForegroundColorAttributeName,
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
