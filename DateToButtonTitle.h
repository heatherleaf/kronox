//
//  DateToButtonTitle.h
//  KronoX
//
//  Created by Peter Ljunglöf on 2008-03-23.
//  Copyright 2008 Heatherleaf. All rights reserved.
//

// Putting a NSFormatter (e.g., NSDateFormatter) inside a NSButton, 
// for formatting the title of the button, doesn't work.
// My solution is to use a NSValueTransformer for transforming the
// title with Cocoa Bindings


#import <Cocoa/Cocoa.h>


@interface DateToButtonTitle : NSValueTransformer 

+ (NSString*) transformedValue: (NSDate*) date;

@end
