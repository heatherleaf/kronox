//
//  WorkPeriod.h
//  KronoX
//
//  Created by Peter Ljunglöf on 2008-02-23.
//  Copyright 2008 Heatherleaf. All rights reserved.
//

#import <CoreData/CoreData.h>

@class Task;

@interface WorkPeriod :  NSManagedObject 

@property (retain) NSDate* start;
@property (retain) NSNumber* duration;
@property (retain) NSString* comment;
@property (retain) Task* task;

@property (retain) NSDate* end;

@end


