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


@implementation HINSPDebug
{
    HINSPDebugWindow *_window;
    NSString *_classPrefix;
    UIViewController *_rootViewController;
}

#pragma mark - View Life Cycle

- (instancetype)initWithClassPrefix:(NSString*)classPrefix
{
    self = [super init];
    if (self) {
        _classPrefix = classPrefix;
        [HINSPHeapStackInspector setClassPrefix:classPrefix];
        CGRect rect = [UIScreen mainScreen].bounds;
        HINSPDebugWindow *window = [[HINSPDebugWindow alloc] initWithFrame:rect];
        [window setHidden:NO];
      //  window.windowLevel = UIWindowLevelAlert - 1; // Show appear under any alerts
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
    HINSPHeapStackTableViewController *tv = [[HINSPHeapStackTableViewController alloc] init];
    tv.dataSource = stack;
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:tv];
    [_rootViewController presentViewController:navController animated:YES completion:nil];
    
    return tv;
}

- (void)recordButtonTapped:(id)sender
{
    if ([NSObject isSnapshotRecording]) {
        [self showInfoLabel];
        [NSObject endSnapshot];
    } else {
        [self resetInfoLabel];
        [NSObject beginSnapshotWithClassPrefix:_classPrefix];
        [HINSPHeapStackInspector performHeapShot];
    }
}

+ (void)startWithClassPrefix:(NSString*)classPrefix {
    static dispatch_once_t onceToken;
    static HINSPDebug *twDebug = nil;
    dispatch_once(&onceToken, ^{
        twDebug = [[HINSPDebug alloc] initWithClassPrefix:classPrefix];
    });
}

@end
