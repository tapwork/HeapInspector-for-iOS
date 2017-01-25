//
//  RMDebug.h
//
//  Created by Christian Menschel on 16.08.14.
//  Copyright (c) 2014 tapwork. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HINSPDebug : NSObject

/// Shows the HeapInspector
+ (void)start;

/// Stops the HeapInspector and removes the inspector's view
+ (void)stop;

// Shows HeapInspector (if not visible yet) and starts the record immediately
+ (void)startRecord;

// Stops record - but does not hide the HeapInspector
+ (void)stopRecord;

/// Add some (or only one) class prefix like `UI` OR `MK` to record classes that match the prefix only.
/// It's highly recommended to record a specific class or prefix -
/// otherwise all Cocoa classes will be recorded, which slows down the performance.
/// This improves performance and readibility
+ (void)addClassPrefixesToRecord:(NSArray <NSString *> *)classPrefixes;

/// You can also record classes that are owned by specific Swift modules
+ (void)addSwiftModulesToRecord:(NSArray <NSString *> *)swiftModules;

// Default is YES
+ (void)recordBacktraces:(BOOL)recordBacktraces;

@end

NS_ASSUME_NONNULL_END
