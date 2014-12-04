//
//  NSObject+HeapInspector.h
//
//  Created by Christian Menschel on 06.08.14.
//  Copyright (c) 2014 tapwork. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (HeapInspector)

+ (void)beginSnapshot;
+ (void)beginSnapshotWithClassPrefixes:(NSSet*)prefixes;
+ (void)endSnapshot;
+ (BOOL)isSnapshotRecording;
+ (void)resumeSnapshot;
+ (NSArray *)referenceHistoryForObject:(id)obj;

// Default is NO, because it is a large performance impact recording the backtrace for each retain/release
+ (void)setRecordBacktrace:(BOOL)recordBacktrace;

@end
