//
//  RMDebug.h
//
//  Created by Christian Menschel on 16.08.14.
//  Copyright (c) 2014 tapwork. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface HINSPDebug : NSObject

/// Shows the HeapInspector
+ (void)start;

/// Stops the HeapInspector and removes the inspector's view
+ (void)stop;

/// Add some (or only one) class prefix like `UI` OR `MK` to record classes that match the prefix only.
/// This improves performance and readibility
+ (void)addClassPrefixesToRecord:(NSArray *)classPrefixes;

/// You can also record classes that are owned by specific Swift modules
+ (void)addSwiftModulesToRecord:(NSArray *)swiftModules;

// Default is NO
+ (void)recordBacktraces:(BOOL)recordBacktraces;

@end
