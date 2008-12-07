//
//  RecordingMenuDelegate.h
//  KronoX
//
//  Created by Peter Ljunglöf on 2008-10-09.
//  Copyright 2008 Heatherleaf. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Task.h"
#import "TasksController.h"
#import "WorkPeriodController.h"

@interface RecordingMenuDelegate : NSObject {
	IBOutlet NSOutlineView* tasksView;
	IBOutlet TasksController* tasksController;
	IBOutlet WorkPeriodController* workPeriodController;
}

- (NSInteger) numberOfItemsInMenu: (NSMenu*) menu;

- (BOOL) menu: (NSMenu*) menu
   updateItem: (NSMenuItem*) item 
	  atIndex: (NSInteger) index
 shouldCancel: (BOOL) shouldCancel;

@end
