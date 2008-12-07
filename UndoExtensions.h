//
//  UndoExtensions.h
//  KronoX
//
//  Created by Peter Ljunglöf on 2008-03-31.
//  Copyright 2008 Heatherleaf. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSManagedObjectContext (UndoExtensions) 

- (void) beginUndoGroup: (NSString*) action;
- (void) endUndoGroup;


@end
