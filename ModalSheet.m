//
//  ModalSheet.m
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

#import "ModalSheet.h"

@implementation ModalSheet

@synthesize enclosingView;

- (NSInteger) showModal {
    [NSApp beginSheet:self
       modalForWindow:[NSApp mainWindow] 
        modalDelegate:nil
       didEndSelector:nil
          contextInfo:nil];
    NSInteger response = [NSApp runModalForWindow:self];
    [NSApp endSheet:self];
    [self orderOut:nil];
    return response;
}

- (IBAction) showModal: (id) sender {
    [self showModal];
}

- (IBAction) stopModal: (id) sender { 
    [NSApp stopModal]; 
}

- (IBAction) abortModal: (id) sender { 
    [NSApp abortModal]; 
}

- (IBAction) stopModalWithTag: (id) sender { 
    [NSApp stopModalWithCode:[sender tag]]; 
}

@end
