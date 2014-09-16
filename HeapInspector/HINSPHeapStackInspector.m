//
//  RMHeapEnumerator.m
//  HeapInspectorExample
//
//  Created by Christian Menschel on 22.08.14.
//  Copyright (c) 2014 tapwork. All rights reserved.
//

#import "HINSPHeapStackInspector.h"
#import <malloc/malloc.h>
#import <mach/mach.h>
#import <objc/runtime.h>

static CFMutableSetRef registeredClasses;
static NSSet *heapShotLiveObjects;
const char *recordClassPrefix;

// Mimics the objective-c object stucture for checking if a range of memory is an object.
typedef struct {
    Class isa;
} rm_maybe_object_t;

@implementation HINSPHeapStackInspector

static kern_return_t memory_reader(task_t task, vm_address_t remote_address, vm_size_t size, void **local_memory)
{
    *local_memory = (void *)remote_address;
    return KERN_SUCCESS;
}

static void range_callback(task_t task, void *context, unsigned type, vm_range_t *ranges, unsigned rangeCount)
{
    RMHeapEnumeratorBlock block = (__bridge RMHeapEnumeratorBlock)context;
    if (!block) {
        return;
    }
    
    for (unsigned int i = 0; i < rangeCount; i++) {
        vm_range_t range = ranges[i];
        rm_maybe_object_t *tryObject = (rm_maybe_object_t *)range.address;
        Class tryClass = NULL;
#ifdef __arm64__
        // See http://www.sealiesoftware.com/blog/archive/2013/09/24/objc_explain_Non-pointer_isa.html
        extern uint64_t objc_debug_isa_class_mask WEAK_IMPORT_ATTRIBUTE;
        tryClass = (__bridge Class)((void *)((uint64_t)tryObject->isa & objc_debug_isa_class_mask));
#else
        tryClass = tryObject->isa;
#endif
        // If the class pointer matches one in our set of class pointers from the runtime, then we should have an object.
        if (CFSetContainsValue(registeredClasses, (__bridge const void *)(tryClass))) {
            // Also check if we can record this object
            const char *name = object_getClassName((__bridge id)tryObject);
            if (canRecordObject(name)) {
                 block((__bridge id)tryObject, tryClass);
            }
        }
    }
}

static inline bool canRecordObject(const char* className)
{
    bool canRecord = true;
    if (recordClassPrefix && className) {
        canRecord = (strncmp(className, recordClassPrefix, strlen(recordClassPrefix)) == 0);
    }
    
    if (strcasecmp(className, "NSAutoreleasePool") == 0) {
        canRecord = NO;
    }
    
    return canRecord;
}

+ (void)enumerateLiveObjectsUsingBlock:(RMHeapEnumeratorBlock)block
{
    if (!block) {
        return;
    }
    
    // Refresh the class list on every call in case classes are added to the runtime.
    [self updateRegisteredClasses];
    
    // For another exmple of enumerating through malloc ranges (which helped my understanding of the api) see:
    // http://llvm.org/svn/llvm-project/lldb/tags/RELEASE_34/final/examples/darwin/heap_find/heap/heap_find.cpp
    // Also https://gist.github.com/samdmarshall/17f4e66b5e2e579fd396
    vm_address_t *zones = NULL;
    unsigned int zoneCount = 0;
    kern_return_t result = malloc_get_all_zones(mach_task_self(), &memory_reader, &zones, &zoneCount);
    if (result == KERN_SUCCESS) {
        for (unsigned int i = 0; i < zoneCount; i++) {
            malloc_zone_t *zone = (malloc_zone_t *)zones[i];
            if (zone->introspect && zone->introspect->enumerator) {
                zone->introspect->enumerator(mach_task_self(), (__bridge void *)(block), MALLOC_PTR_IN_USE_RANGE_TYPE, zones[i], &memory_reader, &range_callback);
            }
        }
    }
}

+ (void)updateRegisteredClasses
{
    if (!registeredClasses) {
        registeredClasses = CFSetCreateMutable(NULL, 0, NULL);
    } else {
        CFSetRemoveAllValues(registeredClasses);
    }
    unsigned int count = 0;
    Class *classes = objc_copyClassList(&count);
    for (unsigned int i = 0; i < count; i++) {
        CFSetAddValue(registeredClasses, (__bridge const void *)(classes[i]));
    }
    free(classes);
}

#pragma mark - Public

+ (void)setClassPrefix:(NSString *)classPrefix
{
    recordClassPrefix = [classPrefix UTF8String];
}

+ (void)performHeapShot
{
    heapShotLiveObjects = [[self class] heapStack];
}

+ (NSSet *)recordedHeapStack
{
    NSMutableSet *endLiveObjects = [[[self class] heapStack] mutableCopy];
    [endLiveObjects minusSet:heapShotLiveObjects];
    NSSet *recordedObjects = [NSSet setWithSet:endLiveObjects];
    
    return recordedObjects;
}

+ (NSSet *)heapStack
{
    NSMutableSet *objects = [NSMutableSet set];
    [HINSPHeapStackInspector enumerateLiveObjectsUsingBlock:^(__unsafe_unretained id object,
                                                           __unsafe_unretained Class actualClass) {
        // We cannot store the object itself -  We want to avoid any retain calls.
        // We store the class name + pointer
        NSString *string = [NSString stringWithFormat:@"%s: %p",
                            object_getClassName(object),
                            object];
        [objects addObject:string];
    }];
    
    return objects;
}

+ (NSString *)classPrefix
{
    return [NSString stringWithUTF8String:recordClassPrefix];
}

+ (id)objectForPointer:(NSString *)pointer
{
    id __block foundObject = nil;
    [HINSPHeapStackInspector enumerateLiveObjectsUsingBlock:^(__unsafe_unretained id object,
                                                           __unsafe_unretained Class actualClass) {
       
        if ([pointer isEqualToString:[NSString stringWithFormat:@"%p",object]]) {
            foundObject = object;
        }
    }];
    
    return foundObject;
}


@end
