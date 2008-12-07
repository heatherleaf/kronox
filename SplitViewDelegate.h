//
//  SplitViewDelegate.h
//  KronoX
//
//  Created by Peter Ljunglöf on 2008-10-13.
//  Copyright 2008 Heatherleaf. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface SplitViewDelegate : NSObject 

- (CGFloat)     splitView: (NSSplitView*) sender 
   constrainMaxCoordinate: (CGFloat) proposedMax
			  ofSubviewAt: (int) offset;

- (CGFloat)     splitView: (NSSplitView*) sender 
   constrainMinCoordinate: (CGFloat) proposedMin
			  ofSubviewAt: (int) offset;

@end
