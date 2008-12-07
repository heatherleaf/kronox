//
//  ModalSheet.h
//  KronoX
//
//  Created by Peter Ljunglöf on 2008-10-13.
//  Copyright 2008 Heatherleaf. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ModalSheet : NSPanel {
	NSView* viewThatSheetEmergesBelow;
}

@property (retain) NSView* viewThatSheetEmergesBelow;

- (IBAction) showModal: (id) sender;
- (NSInteger) showModal;
- (NSInteger) showModalBelow: (NSView*) view;
- (IBAction) stopModal: (id) sender;
- (IBAction) abortModal: (id) sender;
- (IBAction) stopModalWithTag: (id) sender;

@end
