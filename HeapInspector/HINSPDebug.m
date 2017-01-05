//
//  RMDebug.m
//
//
//  Created by Christian Menschel on 16.08.14.
//  Copyright (c) 2014 tapwork. All rights reserved.
//

#import "HINSPDebug.h"
#import "HINSPDebugWindow.h"
#import "NSObject+HeapInspector.h"
#import <objc/objc.h>
#import <objc/runtime.h>
#import "HINSPHeapStackInspector.h"
#import "HINSPHeapStackTableViewController.h"

static HINSPDebug *twDebug = nil;

@implementation HINSPDebug
{
    HINSPDebugWindow *_window;
    UIViewController *_rootViewController;
    NSSet *_recordedHeap;
}

#pragma mark - View Life Cycle

- (instancetype)init
{
    self = [super init];
    if (self) {
        [NSObject startSwizzle];
        [[self class] recordBacktraces:YES];

        CGRect rect = [UIScreen mainScreen].bounds;
        HINSPDebugWindow *window = [[HINSPDebugWindow alloc] initWithFrame:rect];
        [window setHidden:NO];
        window.windowLevel = UIWindowLevelStatusBar + 50;
        [window.recordButton addTarget:self
                                action:@selector(recordButtonTapped:)
                      forControlEvents:UIControlEventTouchUpInside];
        [window.recordedButton addTarget:self
                              action:@selector(recordedHeapButtonTapped:)
                    forControlEvents:UIControlEventTouchUpInside];
        
        [window.activeButton addTarget:self
                                action:@selector(currentHeapButtonTapped:)
                      forControlEvents:UIControlEventTouchUpInside];
        
        _window = window;
        
        // Create a blank rootViewController
        UIViewController *rootViewController = [[UIViewController alloc] init];
        rootViewController.view.alpha = 0.0;
        _rootViewController = rootViewController;
        _window.rootViewController = rootViewController;
    }
    return self;
}

- (void)showInfoLabel
{
    NSUInteger count = [_recordedHeap count];
    NSString *text = [NSString stringWithFormat:@"Objects alive: %lu",
                      (unsigned long)count];
    _window.infoLabel.text = text;
    if (count > 0) {
        _window.recordedButton.hidden = NO;
    }
}

- (void)resetInfoLabel
{
    _window.infoLabel.text = nil;
    _window.recordedButton.hidden = YES;
}

#pragma mark - Actions

- (void)currentHeapButtonTapped:(id)sender
{
    NSArray *stack = [[HINSPHeapStackInspector heap] allObjects];
    if ([stack count] > 0) {
        HINSPHeapStackTableViewController *controller = [self heapStackControllerWithHeapStack:stack];
        controller.title = @"Heap";
    }
}

- (void)recordedHeapButtonTapped:(id)sender
{
    if ([_recordedHeap count] > 0) {
        [NSObject endSnapshot];
        NSArray *stack = [_recordedHeap allObjects];
        HINSPHeapStackTableViewController *controller = [self heapStackControllerWithHeapStack:stack];
        controller.title = @"Recorded Heap";
    }
}

- (void)recordButtonTapped:(id)sender
{
    if ([NSObject isSnapshotRecording]) {
        [self stopRecord];
    } else {
        [self beginRecord];
    }
}

#pragma mark - Private methods

- (HINSPHeapStackTableViewController *)heapStackControllerWithHeapStack:(NSArray *)stack
{
    HINSPHeapStackTableViewController *tv = [[HINSPHeapStackTableViewController alloc] initWithDataSource:stack];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:tv];
    [_rootViewController presentViewController:navController animated:YES completion:nil];
    
    return tv;
}

- (void)stopRecord
{
    _window.recordButton.isRecording = NO;
    _recordedHeap = [HINSPHeapStackInspector recordedHeap];
    [self showInfoLabel];
    [NSObject endSnapshot];
}

- (void)beginRecord
{
    _recordedHeap = nil;
    [self resetInfoLabel];
    [NSObject beginSnapshot];
    _window.recordButton.isRecording = YES;
    [HINSPHeapStackInspector performHeapShot];
}

#pragma mark - Public methods

+ (void)start
{
    twDebug = [[HINSPDebug alloc] init];
}

+ (void)startRecord
{
    if (!twDebug) {
        [self start];
    }
    [twDebug beginRecord];
}

+ (void)stop
{
    [NSObject endSnapshot];
    [NSObject removeAllClassPrefixesToRecord];
    [HINSPHeapStackInspector reset];
    twDebug = nil;
}

+ (void)stopRecord {
    [twDebug stopRecord];
}

+ (void)addClassPrefixesToRecord:(NSArray <NSString *> *)classPrefixes
{
    if (classPrefixes) {
        [NSObject addClassPrefixesToRecord:classPrefixes];
    }
}

+ (void)addSwiftModulesToRecord:(NSArray <NSString *> *)swiftModules
{
    if (swiftModules) {
        NSMutableArray *modulesWithPrefix = [NSMutableArray array];
        for (NSString *swiftModule in swiftModules) {
            NSString *prefixed = [NSString stringWithFormat:@"%@.",swiftModule];
            [modulesWithPrefix addObject:prefixed];
        }
        [NSObject addClassPrefixesToRecord:[modulesWithPrefix copy]];
    }
}

+ (void)recordBacktraces:(BOOL)recordBacktraces
{
    [NSObject setRecordBacktrace:recordBacktraces];
}

@end
