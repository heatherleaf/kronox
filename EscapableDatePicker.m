//
//  EscapableDatePicker.m
//  KronoX
//
//  Created by Peter Ljunglöf on 2010-02-01.
//  Copyright 2010 heatherleaf. All rights reserved.
//

#import "EscapableDatePicker.h"


@implementation EscapableDatePicker

- (void) keyDown:(NSEvent*)event {
    if ([event keyCode] == 53) {
        LOG(@"ESCAPE was pressed: transmitting to next responder");
        [[self nextResponder] keyDown:event];
    } else {
        [super keyDown:event];
    }
}

@end
