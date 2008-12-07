//
//  UndoExtensions.m
//  KronoX
//
//  Created by Peter Ljunglöf on 2008-03-31.
//  Copyright 2008 Heatherleaf. All rights reserved.
//

#import "UndoExtensions.h"


@implementation NSManagedObjectContext (UndoExtensions)

- (void) beginUndoGroup: (NSString*) action {
	[[self undoManager] beginUndoGrouping];
	[[self undoManager] setActionName: action];
}

- (void) endUndoGroup {
	[[self undoManager] endUndoGrouping];
}


@end
