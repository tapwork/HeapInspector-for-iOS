//
//  RMHeapEnumerator.h
//  HeapInspectorExample
//
//  Created by Christian Menschel on 22.08.14.
//  Copyright (c) 2014 tapwork. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^RMHeapEnumeratorBlock)(__unsafe_unretained id object, BOOL *stop);

@interface HINSPHeapStackInspector : NSObject

+ (void)performHeapShot;
+ (void)enumerateLiveObjectsUsingBlock:(RMHeapEnumeratorBlock)block;
+ (NSSet *)heap;
+ (NSSet *)recordedHeap;
+ (id)objectForPointer:(NSString *)pointer;
+ (void)reset;
@end
