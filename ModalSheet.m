//
//  ModalSheet.m
//  KronoX
//
//  Created by Peter Ljunglöf on 2008-10-13.
//  Copyright 2008 Heatherleaf. All rights reserved.
//

#import "ModalSheet.h"


@implementation ModalSheet

@synthesize viewThatSheetEmergesBelow;

- (IBAction) showModal: (id) sender {
	[self showModal];
}

- (NSInteger) showModal {
	return [self showModalBelow:nil];
}

- (NSInteger) showModalBelow: (NSView*) view {
	self.viewThatSheetEmergesBelow = view;
	[NSApp beginSheet: self
	   modalForWindow: [NSApp mainWindow] 
		modalDelegate: nil
	   didEndSelector: nil
		  contextInfo: nil];
	NSInteger response = [NSApp runModalForWindow: self];
	[NSApp endSheet: self];
	[self orderOut: nil];
	return response;
}

- (IBAction) stopModal: (id) sender { [NSApp stopModal]; }
- (IBAction) abortModal: (id) sender { [NSApp abortModal]; }
- (IBAction) stopModalWithTag: (id) sender { [NSApp stopModalWithCode: [sender tag]]; }

@end
