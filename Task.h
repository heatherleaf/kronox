//
//  Task.h
//  KronoX
//
//  Created by Peter Ljunglöf on 2008-02-23.
//  Copyright 2008 Heatherleaf. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "WorkPeriod.h"
#import "DateExtensions.h"


@interface Task :  NSManagedObject  

// Properties in the data model:
@property (retain) NSNumber* order;
@property (retain) NSString* name;
@property (retain) NSNumber* enabled;
@property (retain) NSString* appearance;
@property (retain) NSSet* children;
@property (retain) Task* parent;
@property (retain) NSSet* workperiods;

// Calculated properties:
@property (readonly) NSString* longName;
@property (readonly) NSString* startRecordingName;
@property (readonly) NSColor* color;
@property (readonly) NSTimeInterval totalDuration;
@property (readonly) NSTimeInterval totalDurationIncludingSubtasks;
@property (readonly) NSNumber* totalDurationPercent;
@property (readonly) BOOL allParentsAreEnabled;

// Other methods
- (void) awakeFromInsert;
+ (NSColorList*) taskColorList;

@end

