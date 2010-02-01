//
//  EscapableDatePicker.h
//  KronoX
//
//  Created by Peter Ljunglöf on 2010-02-01.
//  Copyright 2010 heatherleaf. All rights reserved.
//

#import <Cocoa/Cocoa.h>

// This is a subclass of NSDatePicker to overcome a bug in Snow Leopard:
// When pressing "escape", the key is not transmitted to the next responder
// which means that you cannot close NSPanels from the keyboard while in a Datepicker

@interface EscapableDatePicker : NSDatePicker

- (void) keyDown:(NSEvent*)event;

@end
