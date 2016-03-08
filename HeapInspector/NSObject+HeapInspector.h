//
//  NSObject+HeapInspector.h
//
//  Created by Christian Menschel on 06.08.14.
//  Copyright (c) 2014 tapwork. All rights reserved.
//

#import <Foundation/Foundation.h>

extern bool canRecordObject(id obj);

@interface NSObject (HeapInspector)

+ (void)addClassPrefixesToRecord:(NSArray *)prefixes;
+ (void)removeAllClassPrefixesToRecord;

+ (void)beginSnapshot;
+ (void)endSnapshot;
+ (BOOL)isSnapshotRecording;
+ (void)resumeSnapshot;
+ (NSArray *)referenceHistoryForObject:(id)obj;
+ (NSString *)symbolForPointerValue:(NSValue *)pointerValue;
+ (void)startSwizzle;

// Default is NO, because it is a large performance impact recording the backtrace for each retain/release
+ (void)setRecordBacktrace:(BOOL)recordBacktrace;

@end
