//
//  NSObject+HeapInspector.m
//
//  Created by Christian Menschel on 06.08.14.
//  Copyright (c) 2014 tapwork. All rights reserved.
//
#import <UIKit/UIKit.h>
#import <libkern/OSAtomic.h>
#import <pthread.h>
#import <Foundation/Foundation.h>
#import "NSObject+HeapInspector.h"
#import <objc/runtime.h>
#include <execinfo.h>

static bool kRecordBacktrace = false;
static CFMutableDictionaryRef backtraceDict;
static OSSpinLock backtraceDictLock;
static bool isRecording;
static const char *recordClassPrefix;
static inline void recordAndRegisterIfPossible(id obj, char *name);
static inline bool canRecordObject(id obj);

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

static CFStringRef createCFString(char *charValue)
{
    return CFStringCreateWithCString(NULL, charValue, kCFStringEncodingUTF8);
}

static CFStringRef createCleanStackValue(char *stack)
{
    CFStringRef cString = createCFString(stack);
    CFMutableStringRef returnValue = NULL;
    
    CFStringRef sep = CFSTR("+[");
    CFArrayRef parts = CFStringCreateArrayBySeparatingStrings(NULL, cString, sep);
    if (CFArrayGetCount(parts) <= 1) {
        // If "+" class method didnt work. try "-" instance method
        sep = CFSTR("-[");
        CFRelease(parts);
        parts = CFStringCreateArrayBySeparatingStrings(NULL, cString, sep);
    }
    
    if (CFArrayGetCount(parts) > 1) {
        CFStringRef preVal = (CFStringRef)CFArrayGetValueAtIndex(parts, 1);
        // Removes the line number (which does not fit to the source file
        CFArrayRef parts2 = CFStringCreateArrayBySeparatingStrings(NULL, preVal, CFSTR(" + "));
        if (CFArrayGetCount(parts2) > 0) {
            CFStringRef stackVal = (CFStringRef)CFArrayGetValueAtIndex(parts2, 0);
            returnValue = CFStringCreateMutableCopy(NULL, 255, sep);
            CFStringAppend(returnValue, stackVal);
            CFStringFindAndReplace(returnValue,
                                   CFSTR("tw_alloc"),
                                   CFSTR("alloc"),
                                   CFRangeMake(0, CFStringGetLength(returnValue)),
                                   kCFCompareNonliteral);
        }
        CFRelease(parts2);
    }
    CFRelease(parts);
    CFRelease(cString);
    
    return returnValue;
}

static bool canRegisterBacktrace(char *stack)
{
    CFStringRef cString = createCFString(stack);
    
    // Exclude the HINSP Class Prefix (that's ourself)
    CFRange range = CFStringFind(cString, CFSTR("HINSP"), kCFCompareCaseInsensitive);
    CFRelease(cString);
    if (range.location != kCFNotFound) {
        return false;
    }
    
    return true;
}

static CFArrayRef createBacktrace()
{
    if (!kRecordBacktrace) {
        return NULL;
    }

    CFMutableArrayRef stack = CFArrayCreateMutable(NULL, 0, &kCFTypeArrayCallBacks);
    void *bt[1024];
    int bt_size;
    char **bt_syms;
    bt_size = backtrace(bt, 1024);
    bt_syms = backtrace_symbols(bt, bt_size);
    for (int i = 0; i < bt_size; i++) {
        CFStringRef cString = createCleanStackValue(bt_syms[i]);
        if (cString) {
            if (canRegisterBacktrace(bt_syms[i]) == true) {
                CFArrayAppendValue(stack, cString);
            } else {
                stack = NULL;
                break;
            }
            CFRelease(cString);
        }
    }
    free(bt_syms);
    
    return stack;
}

static bool registerBacktraceForObject(void *obj, char *type)
{
    OSSpinLockLock(&backtraceDictLock);
    
    CFArrayRef backtrace = createBacktrace();
    bool success = false;
    
    char key[255];
    sprintf(key,"%p",obj);
    CFStringRef cfKey = createCFString(key);
    CFStringRef cfType = createCFString(type);
    if (cfKey) {
        if (!backtraceDict) {
            backtraceDict = CFDictionaryCreateMutable(NULL,
                                                      0,
                                                      &kCFTypeDictionaryKeyCallBacks,
                                                      &kCFTypeDictionaryValueCallBacks);
        }
        CFMutableArrayRef storedHistory = (CFMutableArrayRef)CFDictionaryGetValue(backtraceDict, cfKey);
        CFMutableArrayRef history = NULL;
        if (!history) {
            history = CFArrayCreateMutable(NULL, 0, &kCFTypeArrayCallBacks);
        } else {
            history = CFArrayCreateMutableCopy(NULL, CFArrayGetCount(storedHistory), storedHistory);
        }
        CFMutableDictionaryRef item = CFDictionaryCreateMutable(NULL,
                                                                0,
                                                                &kCFTypeDictionaryKeyCallBacks,
                                                                &kCFTypeDictionaryValueCallBacks);
        CFDictionarySetValue(item, CFSTR("type"), cfType);
        if (backtrace && CFArrayGetCount(backtrace) > 0) {
            CFDictionarySetValue(item, CFSTR("last_trace"), CFArrayGetValueAtIndex(backtrace, 0));
            CFDictionarySetValue(item, CFSTR("all_traces"), backtrace);
        }
        CFArrayAppendValue(history, item);
        CFRelease(item);
        CFDictionarySetValue(backtraceDict, cfKey, history);
        CFRelease(history);
        success = true;
    }
    OSSpinLockUnlock(&backtraceDictLock);
    CFRelease(cfKey);
    CFRelease(cfType);
    CFRelease(backtrace);
    
    return success;
}

// SEE more http://clang.llvm.org/docs/AutomaticReferenceCounting.html
// or http://clang.llvm.org/doxygen/structclang_1_1CodeGen_1_1ARCEntrypoints.html
id objc_retain(id value)
{
    [value retain];
    
    return value;
}

id objc_storeStrong(id *object, id value)
{
    if (value) {
        recordAndRegisterIfPossible(value,"storeStrong");
    }
    value = [value retain];
    id oldValue = *object;
    *object = value;
    [oldValue release];
    return value;
}

id objc_retainBlock(id value)
{
    if (value) {
        recordAndRegisterIfPossible(value,"retainBlock");
    }
    return [value copy];
}

id objc_release(id value)
{
    [value release];
    
    return value;
}

id objc_retainAutorelease(id value)
{
    if (value) {
        recordAndRegisterIfPossible(value,"retainAutorelease");
    }
    [value retain];
    [value autorelease];
    
    return value;
}

static inline void cleanup()
{
    if (backtraceDict) {
        OSSpinLockLock(&backtraceDictLock);
        CFDictionaryRemoveAllValues(backtraceDict);
        OSSpinLockUnlock(&backtraceDictLock);
    }
}

static inline bool canRecordObject(id obj)
{
    if ([obj isProxy]) {
        // NSProxy sub classes will cause crash when calling class_getName on its class
        return false;
    }
    Class cls = object_getClass(obj);
    bool canRecord = true;
    const char *name = class_getName(cls);
    if (recordClassPrefix && name) {
        canRecord = (strncmp(name, recordClassPrefix, strlen(recordClassPrefix)) == 0);
    }
    
    if (isRecording == false) {
        canRecord = false;
    }
    
    return canRecord;
}

static inline void recordAndRegisterIfPossible(id obj, char *name)
{
    if (canRecordObject(obj)) {
        if (registerBacktraceForObject(obj, name)) {
#if TARGET_IPHONE_SIMULATOR
//            printf("%s %s\n",name, object_getClassName(obj));
#endif
        }
    }
}

static inline void runLoopActivity(CFRunLoopObserverRef observer, CFRunLoopActivity activity)
{
    if (activity & kCFRunLoopExit) {
        // nothing yet
    }
}


@implementation NSObject (HeapInspector)

+ (void)load
{
    SwizzleClassMethod([self class], NSSelectorFromString(@"alloc"), @selector(tw_alloc));
    SwizzleInstanceMethod([self class], NSSelectorFromString(@"dealloc"), @selector(tw_dealloc));
    SwizzleInstanceMethod([self class], NSSelectorFromString(@"retain"), @selector(tw_retain));
    SwizzleInstanceMethod([self class], NSSelectorFromString(@"release"), @selector(tw_release));
    
    SwizzleInstanceMethod([UIView class], NSSelectorFromString(@"retain"), @selector(tw_retain));
    SwizzleInstanceMethod([UIView class], NSSelectorFromString(@"release"), @selector(tw_release));
    SwizzleInstanceMethod([UIViewController class], NSSelectorFromString(@"retain"), @selector(tw_retain));
    SwizzleInstanceMethod([UIViewController class], NSSelectorFromString(@"release"), @selector(tw_release));
}

+ (id)tw_alloc
{
    bool canRec = canRecordObject(self);
    id obj = [[self class] tw_alloc];
    if (canRec) {
        if (registerBacktraceForObject(obj, "alloc")) {
#if TARGET_IPHONE_SIMULATOR
//            printf("alloc %s\n",class_getName(self));
#endif
        }
    }

    return obj;
}

- (void)tw_dealloc
{
    recordAndRegisterIfPossible(self,"dealloc");
    [self tw_dealloc];
}

- (id)tw_retain
{
    recordAndRegisterIfPossible(self,"retain");
    return [self tw_retain];
}

- (oneway void)tw_release
{
    recordAndRegisterIfPossible(self,"release");
    [self tw_release];
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

+ (void)setRecordBacktrace:(BOOL)recordBacktrace
{
    kRecordBacktrace = recordBacktrace;
}

+ (void)beginSnapshotWithClassPrefix:(NSString*)prefix
{
    isRecording = true;
    cleanup();
    
    if (prefix) {
        recordClassPrefix = [prefix UTF8String];
    }
}

+ (void)endSnapshot
{
    isRecording = false;
}

+ (BOOL)isSnapshotRecording
{
    return isRecording;
}

+ (void)resumeSnapshot
{
    isRecording = true;
}

+ (NSArray *)referenceHistoryForObject:(id)obj
{
    NSArray *history = nil;
    if (obj && backtraceDict) {
        char key[255];
        sprintf(key,"%p",(void *)obj);
        CFStringRef cfKey = createCFString(key);
        CFArrayRef cfHistory = CFDictionaryGetValue(backtraceDict, cfKey);
        history = [(NSArray *)cfHistory copy];
        CFRelease(cfKey);
    }
    
    return history;
}

@end


//
// Weird that we have to swizzle UIView and UIViewController explictly
// UIResponder runs without any special handling
//
@implementation UIView (HeapInspector)

- (id)tw_retain
{
    recordAndRegisterIfPossible(self,"retain");
    return [self tw_retain];
}

- (oneway void)tw_release
{
    recordAndRegisterIfPossible(self,"release");
    [self tw_release];
}

@end

@implementation UIViewController (HeapInspector)

- (id)tw_retain
{
    recordAndRegisterIfPossible(self,"retain");
    return [self tw_retain];
}

- (oneway void)tw_release
{
    recordAndRegisterIfPossible(self,"release");
    [self tw_release];
}

@end
