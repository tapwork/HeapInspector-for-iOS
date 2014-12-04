//
//  HeapInspectorExampleTests.m
//  HeapInspectorExampleTests
//
//  Created by Christian Menschel on 20.08.14.
//  Copyright (c) 2014 tapwork. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <HeapInspector/HINSPDebug.h>
#import <HeapInspector/HINSPHeapStackInspector.h>
#import "RMGalleryWrongViewCotroller.h"

@interface HeapInspectorTests : XCTestCase

@property (nonatomic) UIViewController *controller;

@end

@implementation HeapInspectorTests

- (void)testRecordAll
{
    [HINSPDebug startWithClassPrefixes:nil];
    self.controller = [[UIViewController alloc] init];
    [HINSPDebug stop];
    NSArray *recordedObjects = [[HINSPHeapStackInspector recordedHeapStack] allObjects];
    XCTAssertTrue(([recordedObjects count] > 1), @"Recorded objects must be greater than one");
}

- (void)testRecordSpecificClass
{
    [HINSPDebug startWithClassPrefixes:[NSSet setWithObject:@"RM"]];
    self.controller = [[RMGalleryWrongViewCotroller alloc] init];
    [HINSPDebug stop];
    NSArray *recordedObjects = [[HINSPHeapStackInspector recordedHeapStack] allObjects];
    XCTAssertTrue(([recordedObjects count] == 3), @"Recorded objects must be three");   
}

@end
