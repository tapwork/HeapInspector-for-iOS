//
//  RMDebug.m
//
//
//  Created by Christian Menschel on 16.08.14.
//  Copyright (c) 2014 tapwork. All rights reserved.
//

#import "RMDebug.h"
#import "RMDebugWindow.h"
#import "NSObject+HeapInspector.h"
#import <objc/objc.h>
#import <objc/runtime.h>
#import "RMHeapStackInspector.h"
#import "RMHeapStackTableViewController.h"


@implementation RMDebug
{
    RMDebugWindow *_window;
    NSString *_classPrefix;
    UIViewController *_rootViewController;
}

#pragma mark - View Life Cycle

- (instancetype)initWithClassPrefix:(NSString*)classPrefix
{
    self = [super init];
    if (self) {
        _classPrefix = classPrefix;
        [RMHeapStackInspector setClassPrefix:classPrefix];
        CGRect rect = [UIScreen mainScreen].bounds;
        RMDebugWindow *window = [[RMDebugWindow alloc] initWithFrame:rect];
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
    NSUInteger count = [[RMHeapStackInspector recordedHeapStack] count];
    NSString *text = [NSString stringWithFormat:@"Objects recorded: %lu",
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
    if ([[RMHeapStackInspector heapStack] count] > 0) {
        NSArray *stack = [[RMHeapStackInspector heapStack] allObjects];
        RMHeapStackTableViewController *controller = [self heapStackControllerWithHeapStack:stack];
        controller.title = @"Heap";
    }
}

- (void)tappedRecordedHeapButton:(id)sender
{
    if ([[RMHeapStackInspector recordedHeapStack] count] > 0) {
        NSArray *stack = [[RMHeapStackInspector recordedHeapStack] allObjects];
        RMHeapStackTableViewController *controller = [self heapStackControllerWithHeapStack:stack];
        controller.title = @"Recorded Heap";
    }
}

- (RMHeapStackTableViewController *)heapStackControllerWithHeapStack:(NSArray *)stack
{
    RMHeapStackTableViewController *tv = [[RMHeapStackTableViewController alloc] init];
    tv.dataSource = stack;
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:tv];
    [_rootViewController presentViewController:navController animated:YES completion:nil];
    
    return tv;
}

- (void)recordButtonTapped:(id)sender
{
    if (!_window.recordButton.isRecording) {
        [self showInfoLabel];
    } else {
        [self resetInfoLabel];
        [NSObject beginSnapshotWithClassPrefix:_classPrefix];
        [RMHeapStackInspector performHeapShot];
    }
}

+ (void)startWithClassPrefix:(NSString*)classPrefix {
    static dispatch_once_t onceToken;
    static RMDebug *twDebug = nil;
    dispatch_once(&onceToken, ^{
        twDebug = [[RMDebug alloc] initWithClassPrefix:classPrefix];
    });
}

@end
