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
#include <dlfcn.h>
#include <unistd.h>

static NSCache *kPointerSymbolCache = nil;
static bool kRecordBacktrace = false;
static CFMutableDictionaryRef backtraceDict = NULL;
static CFMutableSetRef ignoreObjectsForRecord = NULL;
static OSSpinLock backtraceDictLock;
static OSSpinLock ignoreObjectRecordingDictLock;
static bool isRecording;
static CFArrayRef recordClassPrefixes = NULL;
static inline void recordAndRegisterIfPossible(id obj, char *name);
static inline void setObjectIgnoringRecord(id obj);
static inline bool isObjectIgnoringRecord(id obj);

static inline void SwizzleInstanceMethod(Class c, SEL origSEL, SEL newSEL)
{
    Method origMethod = class_getInstanceMethod(c, origSEL);
    Method newMethod = class_getInstanceMethod(c, newSEL);
    
    if (class_addMethod(c, origSEL, method_getImplementation(newMethod), method_getTypeEncoding(origMethod))) {
        class_replaceMethod(c, newSEL, method_getImplementation(origMethod), method_getTypeEncoding(newMethod));
    } else {
        method_exchangeImplementations(origMethod, newMethod);
    }
}

static inline void SwizzleClassMethod(Class c, SEL origSEL, SEL newSEL)
{
    Method origMethod = class_getClassMethod(c, origSEL);
    Method newMethod = class_getClassMethod(c, newSEL);
    
    if (class_addMethod(c, origSEL, method_getImplementation(newMethod), method_getTypeEncoding(origMethod))) {
        class_replaceMethod(c, newSEL, method_getImplementation(origMethod), method_getTypeEncoding(newMethod));
    } else {
        method_exchangeImplementations(origMethod, newMethod);
    }
}

static inline CFStringRef createCFString(const char *cStr)
{
    return CFStringCreateWithCString(NULL, cStr, kCFStringEncodingUTF8);
}

static inline void* createBacktrace()
{
    CFMutableArrayRef stack = CFArrayCreateMutable(NULL, 0, &kCFTypeArrayCallBacks);
    if (kRecordBacktrace) {
        void *frames[1024];
        int bt_size;
        bt_size = backtrace(frames, sizeof(frames));
        for (int i = 4; i < bt_size; i++) {
            void *pointer = frames[i];
            if (pointer) {
                NSValue *bytes = [NSValue valueWithPointer:pointer];
                setObjectIgnoringRecord(bytes);
                CFArrayAppendValue(stack, bytes);
            }
        }
    }

    return stack;
}

static inline void registerBacktraceForObject(void *obj, char *type)
{
    OSSpinLockLock(&backtraceDictLock);

    char key[255];
    sprintf(key,"%p",obj);
    CFStringRef cfKey = createCFString(key);
    CFStringRef cfType = createCFString(type);
    if (!backtraceDict) {
        backtraceDict = CFDictionaryCreateMutable(NULL,
                                                  0,
                                                  &kCFTypeDictionaryKeyCallBacks,
                                                  &kCFTypeDictionaryValueCallBacks);
    }
    CFMutableArrayRef storedHistory = (CFMutableArrayRef)CFDictionaryGetValue(backtraceDict, cfKey);
    CFMutableArrayRef history = NULL;
    if (!storedHistory) {
        history = CFArrayCreateMutable(NULL, 0, &kCFTypeArrayCallBacks);
    } else {
        history = CFArrayCreateMutableCopy(NULL, CFArrayGetCount(storedHistory), storedHistory);
    }
    CFMutableDictionaryRef item = CFDictionaryCreateMutable(NULL,
                                                            0,
                                                            &kCFTypeDictionaryKeyCallBacks,
                                                            &kCFTypeDictionaryValueCallBacks);
    CFDictionarySetValue(item, CFSTR("type"), cfType);
    CFArrayRef backtraceStack = createBacktrace();
    if (CFArrayGetCount(backtraceStack) > 0) {
        CFDictionarySetValue(item, CFSTR("last_frame"), CFArrayGetValueAtIndex(backtraceStack, 0));
        CFDictionarySetValue(item, CFSTR("all_frames"), backtraceStack);
    }
    CFRelease(backtraceStack);
    CFArrayAppendValue(history, item);

    CFRelease(item);
    CFDictionarySetValue(backtraceDict, cfKey, history);
    CFRelease(history);
    CFRelease(cfKey);
    CFRelease(cfType);
    OSSpinLockUnlock(&backtraceDictLock);
}

static inline void cleanup()
{
    OSSpinLockLock(&backtraceDictLock);
    if (backtraceDict) {
        CFDictionaryRemoveAllValues(backtraceDict);
    }
    [kPointerSymbolCache removeAllObjects];
    OSSpinLockUnlock(&backtraceDictLock);
}

bool canRecordObject(id obj)
{
    if ([obj isProxy]) {
        // NSProxy sub classes will cause crash when calling class_getName on its class
        return false;
    }

    Class cls = object_getClass(obj);
    bool ignoreRecord = isObjectIgnoringRecord(obj);
    if (ignoreRecord) {
        return false;
    }
    
    bool canRecord = true;
    CFStringRef className = createCFString(class_getName(cls));
    if (!className) {
        return false;
    }
    
    if (CFStringCompare(className, CFSTR("NSAutoreleasePool"), kCFCompareBackwards) == kCFCompareEqualTo) {
        return false;
    }

    if (recordClassPrefixes) {
        for (int i = 0; i < CFArrayGetCount(recordClassPrefixes); i++) {
            CFStringRef prefix = CFArrayGetValueAtIndex(recordClassPrefixes, i);
            canRecord = CFStringHasPrefix(className, prefix);
            if (canRecord) {
                break;
            }
        }
    }

    return canRecord;
}

static inline void recordAndRegisterIfPossible(id obj, char *name)
{
    if (isRecording && canRecordObject(obj)) {
        registerBacktraceForObject(obj, name);
    }
}

static inline bool isObjectIgnoringRecord(id obj)
{
    OSSpinLockLock(&ignoreObjectRecordingDictLock);
    bool ignore = false;
    if (obj && ignoreObjectsForRecord) {
        ignore = CFSetContainsValue(ignoreObjectsForRecord, obj);
    }
    
    OSSpinLockUnlock(&ignoreObjectRecordingDictLock);

    return ignore;
}

static inline void setObjectIgnoringRecord(id obj)
{
    OSSpinLockLock(&ignoreObjectRecordingDictLock);

    if (!ignoreObjectsForRecord) {
        ignoreObjectsForRecord = CFSetCreateMutable(NULL, 0, NULL);
    }
    CFSetAddValue(ignoreObjectsForRecord, obj);
    
    OSSpinLockUnlock(&ignoreObjectRecordingDictLock);
}

#pragma mark - Overriding ARC

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

#pragma mark - NSObject Category

@implementation NSObject (HeapInspector)

+ (id)tw_alloc
{
    bool canRec = (isRecording && canRecordObject(self));
    id obj = [self tw_alloc];
    if (canRec) {
        registerBacktraceForObject(obj, "alloc");
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

#pragma mark - NSObject generated properties


#pragma mark - Public methods

+ (void)addClassPrefixesToRecord:(NSArray *)prefixes
{
    @synchronized(self) {
        if ([prefixes count] > 0) {
            if (recordClassPrefixes) {
                NSMutableSet *existing = [NSMutableSet setWithArray:(__bridge NSArray*)recordClassPrefixes];
                [existing addObjectsFromArray:prefixes];
                recordClassPrefixes = (__bridge CFArrayRef)[[existing allObjects] copy];
            } else {
                recordClassPrefixes = (__bridge CFArrayRef)[prefixes copy];
            }
        }
    }
}

+ (void)removeAllClassPrefixesToRecord
{
    recordClassPrefixes = NULL;
}

+ (void)setRecordBacktrace:(BOOL)recordBacktrace
{
    if (recordBacktrace) {
        kRecordBacktrace = true;
    } else {
        kRecordBacktrace = false;
    }
}

+ (void)beginSnapshot
{
    isRecording = true;
    cleanup();
}

+ (void)endSnapshot
{
    ignoreObjectsForRecord = nil;
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
    OSSpinLockLock(&backtraceDictLock);
    if (obj && backtraceDict) {
        char key[255];
        sprintf(key,"%p",(void *)obj);
        CFStringRef cfKey = createCFString(key);
        CFArrayRef cfHistory = CFDictionaryGetValue(backtraceDict, cfKey);
        history = (__bridge NSArray*)cfHistory;
        CFRelease(cfKey);
    }
    OSSpinLockUnlock(&backtraceDictLock);

    return history;
}

+ (NSString *)symbolForPointerValue:(NSValue *)pointerValue
{
    if (pointerValue == NULL) {
        return nil;
    }
    void *pointer = [pointerValue pointerValue];
    if ([kPointerSymbolCache objectForKey:pointerValue]) {
        return [kPointerSymbolCache objectForKey:pointerValue];
    }
    if (!kPointerSymbolCache) {
        kPointerSymbolCache = [[NSCache alloc] init];
    }
    Dl_info sub_info;
    dladdr(pointer, &sub_info);
    NSString *symbol = [NSString stringWithUTF8String:sub_info.dli_sname];

    if (symbol) {
        [kPointerSymbolCache setObject:symbol forKey:pointerValue];
    }

    return symbol;
}

+ (void)startSwizzle
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SwizzleClassMethod([self class], NSSelectorFromString(@"alloc"), @selector(tw_alloc));
        SwizzleInstanceMethod([self class], NSSelectorFromString(@"dealloc"), @selector(tw_dealloc));
        SwizzleInstanceMethod([self class], NSSelectorFromString(@"retain"), @selector(tw_retain));
        SwizzleInstanceMethod(self, NSSelectorFromString(@"release"), @selector(tw_release));
        
        SwizzleInstanceMethod([UIView class], NSSelectorFromString(@"retain"), @selector(tw_retain));
        SwizzleInstanceMethod([UIView class], NSSelectorFromString(@"release"), @selector(tw_release));
        SwizzleInstanceMethod([UIViewController class], NSSelectorFromString(@"retain"), @selector(tw_retain));
        SwizzleInstanceMethod([UIViewController class], NSSelectorFromString(@"release"), @selector(tw_release));
    });
}

@end

#pragma mark - UIResponder categories & Swizzling

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
