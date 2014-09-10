//
//  NSObject+HeapInspector.m
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

static inline void SwizzleClassMethod(Class c, SEL orig, SEL new)
{
    Method origMethod = class_getClassMethod(c, orig);
    Method newMethod = class_getClassMethod(c, new);
    method_exchangeImplementations(origMethod, newMethod);
}

static CFStringRef getCFString(char *charValue) {
    return CFStringCreateWithCString(NULL, charValue, kCFStringEncodingUTF8);
}

static CFStringRef cleanStackValue(char *stack) {
    CFStringRef cString = getCFString(stack);
  
    CFStringRef sep = getCFString("+[");
    CFArrayRef parts = CFStringCreateArrayBySeparatingStrings(NULL, cString, sep);
    if (CFArrayGetCount(parts) <= 1) {
        // If "+" class method didnt work. try "-" instance method
        sep = getCFString("-[");
        parts = CFStringCreateArrayBySeparatingStrings(NULL, cString, sep);
    }
    
    if (CFArrayGetCount(parts) > 1) {
        CFStringRef stack = (CFStringRef)CFArrayGetValueAtIndex(parts, 1);
        CFMutableStringRef val = CFStringCreateMutableCopy(NULL, 255, sep);
        CFStringAppend(val, stack);
        CFStringFindAndReplace(val,
                               getCFString("tw_alloc"),
                               getCFString("alloc"),
                               CFRangeMake(0, CFStringGetLength(val)),
                               kCFCompareNonliteral);
        return val;
    }
    
    return NULL;
}


// THANKS: https://github.com/mikeash/refcounting/blob/master/refcounting.m

static CFMutableDictionaryRef backtraceDict;
static OSSpinLock backtraceDictLock;
static bool isRecording;
static bool swizzleActive;
static const char *recordClassPrefix;

static inline void cleanup()
{
    if (backtraceDict) {
        OSSpinLockLock(&backtraceDictLock);
        CFDictionaryRemoveAllValues(backtraceDict);
        OSSpinLockUnlock(&backtraceDictLock);
    }
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
    }
}


@implementation NSObject (HeapInspector)

+ (void)swizzle
{
    swizzleActive = true;
    SwizzleClassMethod([self class], NSSelectorFromString(@"alloc"), @selector(tw_alloc));
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

+ (id)tw_alloc
{
    bool canRec = canRecordObject([self class]);
    if (canRec) {
        const char *className = class_getName(self);
        printf("malloc %s\n",className);
    }
    id obj = [[self class] tw_alloc];
    if (canRec) {
        CFMutableArrayRef stack = CFArrayCreateMutable(NULL, 0, NULL);
        void *bt[1024];
        int bt_size;
        char **bt_syms;
        bt_size = backtrace(bt, 1024);
        bt_syms = backtrace_symbols(bt, bt_size);
        for (int i = 0; i < bt_size; i++) {
            CFStringRef cString = cleanStackValue(bt_syms[i]);
            CFArrayAppendValue(stack, cString);
        }
        OSSpinLockLock(&backtraceDictLock);
        void *key = (__bridge void *)obj;
        if (key && stack) {
            if (!backtraceDict) {
                backtraceDict = CFDictionaryCreateMutable(NULL, 0, NULL, NULL);
            }
            CFDictionarySetValue(backtraceDict, key, stack);
        }
        OSSpinLockUnlock(&backtraceDictLock);
        free(bt_syms);
    }

    return obj;
}

- (id)tw_retain
{
    [self addRunLoopObserver];
    if (canRecordObject([self class])) {
        const char *className = class_getName(object_getClass(self));
        printf("retain +1 %s <%p>\n",className, self);
    }
    return objc_msgSend(self, NSSelectorFromString(@"tw_retain"));
}

- (oneway void)tw_release
{
    if (canRecordObject([self class])) {
        const char *className = class_getName(object_getClass(self));
        printf("released %s <%p>\n",className, self);
    }
    objc_msgSend(self, NSSelectorFromString(@"tw_release"));
}

- (oneway void)tw_autorelease
{
    if (canRecordObject([self class])) {
        const char *className = class_getName(object_getClass(self));
        printf("autorelease %s <%p>\n",className, self);
    }
    objc_msgSend(self, NSSelectorFromString(@"tw_autorelease"));
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
        recordClassPrefix = [prefix UTF8String];
    }
    
    if (!swizzleActive) {
        [[self class] swizzle];
    }
}

+ (void)endSnapshot
{
    isRecording = false;
}

+ (void)resumeSnapshot
{
    isRecording = true;
}

+ (NSArray *)allocBacktraceForObject:(id)obj
{
    CFArrayRef cfBacktraces = CFDictionaryGetValue(backtraceDict, (__bridge const void *)(obj));
    NSArray *backtraces = [(NSArray *)cfBacktraces copy];
    
    return backtraces;
}


@end
