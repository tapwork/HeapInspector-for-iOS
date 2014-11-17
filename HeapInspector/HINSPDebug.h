//
//  RMDebug.h
//
//  Created by Christian Menschel on 16.08.14.
//  Copyright (c) 2014 tapwork. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface HINSPDebug : NSObject

// Start the HeapInspector with a specific class prefix. Nil records all classes and not just yours.
+ (void)startWithClassPrefix:(NSString*)classPrefix;

// Stops the HeapInspector and removes the inspector's view
+ (void)stop;

// Default is NO, because recording the backtrace for each retain/strong/release has a large performance impact
+ (void)recordBacktraces:(BOOL)recordBacktraces;

@end
