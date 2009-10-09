//
//  ColumnsMenuDelegate.h
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

#import <Cocoa/Cocoa.h>

@interface ColumnsMenuDelegate : NSObject {
    IBOutlet NSScrollView* enclosingView;
}

- (NSInteger) numberOfItemsInMenu: (NSMenu*) menu;

- (BOOL) menu: (NSMenu*) menu
   updateItem: (NSMenuItem*) item 
	  atIndex: (NSInteger) index
 shouldCancel: (BOOL) shouldCancel;

- (void) toggleVisibility: (id) sender;

@end
