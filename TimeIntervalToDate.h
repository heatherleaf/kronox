//
//  TimeIntervalToDate.h
//  KronoX
//
//  Created by Peter Ljunglöf on 2008-03-02.
//  Copyright 2008 Heatherleaf. All rights reserved.
//

// This transformer makes it possible to use a NSDatePicker for 
// showing and editing a NSTimeInterval (represented as a NSNumber)
// The important part here is to add/subtract [[NSTimeZone defaultTimeZone] secondsFromGMT]

#import <Cocoa/Cocoa.h>


@interface TimeIntervalToDate : NSValueTransformer 

@end
