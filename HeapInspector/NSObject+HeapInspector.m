//
//  NSObject+HeapInspector.m
//  TT
//
//  Created by Christian Menschel on 06.08.14.
//  Copyright (c) 2014 tapwork. All rights reserved.
//
#import <libkern/OSAtomic.h>
#import <pthread.h>
#import <Foundation/Foundation.h>
#import "NSObject+HeapInspector.h"
#import <objc/runtime.h>
#import <objc/message.h>
#include <execinfo.h>

static inline void SwizzleInstanceMethod(Class c, SEL orig, SEL new)
{
    Method origMethod = class_getInstanceMethod(c, orig);
    Method newMethod = class_getInstanceMethod(c, new);
    method_exchangeImplementations(origMethod, newMethod);
}

//static inline void SwizzleClassMethod(Class c, SEL orig, SEL new)
//{
//    Method origMethod = class_getClassMethod(c, orig);
//    Method newMethod = class_getClassMethod(c, new);
//    method_exchangeImplementations(origMethod, newMethod);
//}


// THANKS: https://github.com/mikeash/refcounting/blob/master/refcounting.m

static CFMutableDictionaryRef refcountDict;
static OSSpinLock refcountDictLock;
//static void *getCallerObject();
static bool isRecording;
static bool swizzleActive;
static const char *recordClassPrefix;
static BOOL shouldPrintLivingReferences;
static inline void printLivingReferences();

static inline void cleanup()
{
    if (refcountDict) {
        OSSpinLockLock(&refcountDictLock);
        CFDictionaryRemoveAllValues(refcountDict);
        OSSpinLockUnlock(&refcountDictLock);
    }
}

static uintptr_t GetRefcount(void *key)
{
    const void *value;
    if (!CFDictionaryGetValueIfPresent(refcountDict, key, &value)) {
        // initial reference count value is ONE - we assume that malloc ran before
        return 1;
    }
    
    return (uintptr_t)value;
}

static void SetRefcount(void *key, uintptr_t count)
{
    if (count < 1) {
        CFDictionaryRemoveValue(refcountDict, key);
    } else {
        CFDictionarySetValue(refcountDict, key, (void*)count);
    }
}

static void IncrementRefcount(void *key)
{
    OSSpinLockLock(&refcountDictLock);
    if (key) {
        uintptr_t count = GetRefcount(key);
        SetRefcount(key, count + 1);
    }
    OSSpinLockUnlock(&refcountDictLock);
}

static void DecrementRefcount(void *key)
{
    OSSpinLockLock(&refcountDictLock);
    if (key) {
        uintptr_t count = GetRefcount(key);
        if (count > 0) {
            uintptr_t newCount = count - 1;
            SetRefcount(key, newCount);
        }
    }
    OSSpinLockUnlock(&refcountDictLock);
}

static inline bool canRecordObject(Class cls)
{
    bool canRecord = true;
    const char *name = class_getName(cls);
    size_t prefixSize = sizeof(recordClassPrefix);
    if (recordClassPrefix && sizeof(name) >= prefixSize) {
        canRecord = (strncmp(name, recordClassPrefix, prefixSize > 0) == 0);
    }
    
    if (isRecording == false) {
        canRecord = false;
    }
    
    return canRecord;
}

static inline void runLoopActivity(CFRunLoopObserverRef observer, CFRunLoopActivity activity) {
    if (activity & kCFRunLoopExit) {
        if (shouldPrintLivingReferences) {
            shouldPrintLivingReferences = NO;
            printLivingReferences();
        }
    }
}

static inline void printLivingReferences() {
    if (refcountDict) {
        CFIndex size = CFDictionaryGetCount(refcountDict);
        CFTypeRef *keysTypeRef = (CFTypeRef *) malloc( size * sizeof(CFTypeRef) );
        CFDictionaryGetKeysAndValues(refcountDict, (const void **) keysTypeRef, NULL);
        void **keys = (void **)keysTypeRef;
        for (int i = 0; i < size; i++) {
            void *key = keys[i];
            uintptr_t number = GetRefcount(key);
            id obj = (__bridge id)(key);
            const char *className = class_getName(object_getClass(obj));
            printf("=================================\nReferences since begin of record:\n");
            printf("%s <%p> refCount: %lu\n",className,key,number);
        }
        
        free(keysTypeRef);
    }
}


@implementation NSObject (HeapInspector)

+ (void)swizzle
{
    swizzleActive = true;
    
    if (!refcountDict) {
        refcountDict = CFDictionaryCreateMutable(NULL, 0, NULL, NULL);
    }
//    SwizzleClassMethod([self class], NSSelectorFromString(@"alloc"), @selector(tw_alloc));
    SwizzleInstanceMethod(self, NSSelectorFromString(@"retain"), @selector(tw_retain));
//    SwizzleInstanceMethod(self, NSSelectorFromString(@"release"), @selector(tw_release));
//    SwizzleInstanceMethod(self, NSSelectorFromString(@"autorelease"), @selector(tw_autorelease));
//    SwizzleInstanceMethod(self, NSSelectorFromString(@"retainCount"), @selector(tw_retainCount));
}

- (void)tw_dealloc
{
    // THANKS: http://stackoverflow.com/questions/14635024/using-objc-msgsendsuper-to-invoke-a-class-method
    Class class = [self superclass];
    struct objc_super mySuper = {
        .receiver = self,
        .super_class = class_isMetaClass(object_getClass(self)) //check if we are an instance or Class
        ? object_getClass(class)                //if we are a Class, we need to send our metaclass (our Class's Class)
        : class                                 //if we are an instance, we need to send our Class (which we already have)
    };
    
    
    objc_msgSendSuper(&mySuper, NSSelectorFromString(@"tw_dealloc"));
}

// TODO: sometimes alloc swizzle does lead to crashes with autoreleasepools
+ (id)tw_alloc
{
    if (canRecordObject([self class])) {
        const char *className = class_getName(self);
        printf("malloc %s\n",className);
    }
    
    return [[self class] tw_alloc];
}

- (id)tw_retain
{
    [self addRunLoopObserver];
    if (canRecordObject([self class])) {
        IncrementRefcount((__bridge void *)(self));
        const char *className = class_getName(object_getClass(self));
        printf("retain +1 %s <%p>\n",className, self);
    }
    return objc_msgSend(self, NSSelectorFromString(@"tw_retain"));
}

- (oneway void)tw_release
{
    if (canRecordObject([self class])) {
        DecrementRefcount((__bridge void *)(self));
        const char *className = class_getName(object_getClass(self));
        printf("released %s <%p>\n",className, self);
    }
    objc_msgSend(self, NSSelectorFromString(@"tw_release"));
}

- (oneway void)tw_autorelease
{
    if (canRecordObject([self class])) {
 //       DecrementRefcount((__bridge void *)(self));
        const char *className = class_getName(object_getClass(self));
        printf("autorelease %s <%p>\n",className, self);
    }
    objc_msgSend(self, NSSelectorFromString(@"tw_autorelease"));
}

- (NSUInteger)tw_retainCount
{
    return GetRefcount((__bridge void *)(self));
}

- (void)addRunLoopObserver
{
    static CFRunLoopObserverRef runLoopObserver;
    if (runLoopObserver == nil) {
        runLoopObserver = CFRunLoopObserverCreateWithHandler(kCFAllocatorDefault,
                                                             kCFRunLoopAllActivities,
                                                             YES,
                                                             0,
                                                             ^(CFRunLoopObserverRef observer, CFRunLoopActivity activity)
                                                             {
                                                                 runLoopActivity(observer, activity);
                                                             });
        //CFStringRef currentMode = CFRunLoopCopyCurrentMode(CFRunLoopGetMain());
        CFRunLoopAddObserver(CFRunLoopGetMain(), runLoopObserver, kCFRunLoopDefaultMode);
    }
}

#pragma mark - Public methods
+ (void)beginSnapshot
{
    [[self class] beginSnapshotWithClassPrefix:nil];
}

+ (void)beginSnapshotWithClassPrefix:(NSString*)prefix
{
    isRecording = true;
    cleanup();
    
    if (prefix) {
        recordClassPrefix = [prefix UTF8String];;
    }
    
    if (!swizzleActive) {
        [[self class] swizzle];
    }
}

+ (void)endSnapshot
{
    isRecording = false;
    [self shouldPrintLivingReferences];
}

+ (void)resumeSnapshot
{
    isRecording = true;
}

+ (void)printLivingReferences
{
    [self shouldPrintLivingReferences];
}

+ (void)shouldPrintLivingReferences
{
    shouldPrintLivingReferences = YES;
    CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.1, true);
}

@end

//@implementation UIViewController (HeapInspector)
//
//+ (void)initialize
//{
////    SwizzleClassMethod([self class], NSSelectorFromString(@"alloc"), @selector(tw_alloc));
//    SwizzleInstanceMethod(self, NSSelectorFromString(@"retain"), @selector(tw_retain));
//}
//
//- (id)tw_retain
//{
//    if (canRecordObject([self class])) {
//        IncrementRefcount((__bridge void *)(self));
//        const char *className = class_getName(object_getClass(self));
//        printf("retain +1 %s <%p>\n",className, self);
//    }
//    return objc_msgSend(self, sel_getUid("tw_retain"));
//}
//@end
