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
}

#pragma mark - View Life Cycle

- (instancetype)init
{
    self = [super init];
    if (self) {
        [NSObject startSwizzle];
        [HINSPHeapStackInspector performHeapShot];

        CGRect rect = [UIScreen mainScreen].bounds;
        HINSPDebugWindow *window = [[HINSPDebugWindow alloc] initWithFrame:rect];
        [window setHidden:NO];
        window.windowLevel = UIWindowLevelStatusBar + 50;
        [window.recordButton addTarget:self
                                action:@selector(recordButtonTapped:)
                      forControlEvents:UIControlEventTouchUpInside];
        [window.recordedButton addTarget:self
                              action:@selector(tappedRecordedHeapButton:)
                    forControlEvents:UIControlEventTouchUpInside];
        
        [window.activeButton addTarget:self
                                action:@selector(tappedActiveHeapButton:)
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
    NSUInteger count = [[HINSPHeapStackInspector recordedHeapStack] count];
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

- (void)tappedActiveHeapButton:(id)sender
{
    if ([[HINSPHeapStackInspector heapStack] count] > 0) {
        NSArray *stack = [[HINSPHeapStackInspector heapStack] allObjects];
        HINSPHeapStackTableViewController *controller = [self heapStackControllerWithHeapStack:stack];
        controller.title = @"Heap";
    }
}

- (void)tappedRecordedHeapButton:(id)sender
{
    if ([[HINSPHeapStackInspector recordedHeapStack] count] > 0) {
        [NSObject endSnapshot];
        NSArray *stack = [[HINSPHeapStackInspector recordedHeapStack] allObjects];
        HINSPHeapStackTableViewController *controller = [self heapStackControllerWithHeapStack:stack];
        controller.title = @"Recorded Heap";
    }
}

- (HINSPHeapStackTableViewController *)heapStackControllerWithHeapStack:(NSArray *)stack
{
    HINSPHeapStackTableViewController *tv = [[HINSPHeapStackTableViewController alloc] initWithDataSource:stack];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:tv];
    [_rootViewController presentViewController:navController animated:YES completion:nil];
    
    return tv;
}

- (void)recordButtonTapped:(id)sender
{
    if ([NSObject isSnapshotRecording]) {
        [self stopRecord];
    } else {
        [self beginRecord];
    }
}

- (void)stopRecord
{
    [self showInfoLabel];
    [NSObject endSnapshot];
}

- (void)beginRecord
{
    [self resetInfoLabel];
    [NSObject beginSnapshot];
    [HINSPHeapStackInspector performHeapShot];
}

+ (void)start
{
    [[self class] startWithClassPrefixes:nil];
}

+ (void)startWithClassPrefixes:(NSArray *)classPrefixes {
    twDebug = [[HINSPDebug alloc] init];
}

+ (void)addClassPrefixesToRecord:(NSArray *)classPrefixes
{
     [NSObject addClassPrefixesToRecord:classPrefixes];
}

+ (void)addSwiftModulesToRecord:(NSArray *)swiftModules
{
    NSMutableArray *modulesWithPrefix = [NSMutableArray array];
    for (NSString *swiftModule in swiftModules) {
        NSString *prefixed = [NSString stringWithFormat:@"%@.",swiftModule];
        [modulesWithPrefix addObject:prefixed];
    }
    [NSObject addClassPrefixesToRecord:[modulesWithPrefix copy]];
}

+ (void)stop
{
    [NSObject endSnapshot];
    [NSObject removeAllClassPrefixesToRecord];
    twDebug = nil;
}

+ (void)recordBacktraces:(BOOL)recordBacktraces
{
    [NSObject setRecordBacktrace:recordBacktraces];
}

@end
