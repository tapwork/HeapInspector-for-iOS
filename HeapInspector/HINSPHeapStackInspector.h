//
//  RMHeapEnumerator.h
//  HeapInspectorExample
//
//  Created by Christian Menschel on 22.08.14.
//  Copyright (c) 2014 tapwork. All rights reserved.
//

#import <Foundation/Foundation.h>



typedef void (^RMHeapEnumeratorBlock)(__unsafe_unretained id object, __unsafe_unretained Class actualClass);

@interface HINSPHeapStackInspector : NSObject

+ (void)performHeapShot;
+ (void)enumerateLiveObjectsUsingBlock:(RMHeapEnumeratorBlock)block;
+ (NSSet *)heapStack;
+ (NSSet *)recordedHeapStack;
+ (id)objectForPointer:(NSString *)pointer;
+ (void)reset;
@end
