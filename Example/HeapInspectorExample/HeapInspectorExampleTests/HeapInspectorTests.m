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
#import <HeapInspector/NSObject+HeapInspector.h>
#import "RMGalleryWrongViewCotroller.h"
#import <HeapInspector/HINSPHeapStackInspector.h>
#import <HeapInspector/HINSPDebug.h>

@interface HINSPDebug (TestOverridden)
- (void)beginRecord;
@end

@interface HeapInspectorTests : XCTestCase

@property (nonatomic) UITableView *tableView;
@property (nonatomic) UIViewController *controller;

@end

@implementation HeapInspectorTests

- (void)setUp {
    [super setUp];
    [HINSPDebug start];
    [HINSPDebug recordBacktraces:NO];
}

- (void)tearDown
{
    [HINSPDebug stop];
    [super tearDown];
}

- (void)testRecordAll
{
    [HINSPDebug addClassPrefixesToRecord:@[@"UI"]];
    [[HINSPDebug new] beginRecord];
    self.tableView = [[UITableView alloc] init];
    NSArray *recordedObjects = [[HINSPHeapStackInspector recordedHeap] allObjects];
    XCTAssertTrue(([recordedObjects count] > 1), @"Recorded objects must be greater than one");
}

- (void)testRecordBacktrace
{
    [HINSPDebug addClassPrefixesToRecord:@[@"UITableView"]];
    [[HINSPDebug new] beginRecord];
    [HINSPDebug recordBacktraces:YES];
    self.tableView = [[UITableView alloc] init];
    NSArray *refHistory = [NSObject referenceHistoryForObject:self.tableView];
    XCTAssertTrue(([refHistory count] > 1), @"Backtrace objects must be greater than one");
}

- (void)testRecordSpecificClass
{
    [HINSPDebug addClassPrefixesToRecord:@[@"RM"]];
    [[HINSPDebug new] beginRecord];
    self.controller = [[RMGalleryWrongViewCotroller alloc] init];
    NSArray *recordedObjects = [[HINSPHeapStackInspector recordedHeap] allObjects];
    XCTAssertTrue(([recordedObjects count] == 1), @"Recorded objects must be one");
}

- (void)testRecordMultiplePrefixes
{
    [HINSPDebug addClassPrefixesToRecord:@[@"UITableViewWrapperView", @"RM"]];
    [[HINSPDebug new] beginRecord];
    self.controller = [[RMGalleryWrongViewCotroller alloc] init];
    self.tableView = [[UITableView alloc] init];
    NSArray *recordedObjects = [[HINSPHeapStackInspector recordedHeap] allObjects];
    XCTAssertTrue(([recordedObjects count] == 2), @"Recorded objects must be 2");
}

- (void)testAddRecordMultiplePrefixesAfter
{
    [HINSPDebug addClassPrefixesToRecord:@[@"RM"]];
    [[HINSPDebug new] beginRecord];
    [HINSPDebug addClassPrefixesToRecord:@[@"UITableViewWrapperView"]];
    self.controller = [[RMGalleryWrongViewCotroller alloc] init];
    self.tableView = [[UITableView alloc] init];
    NSArray *recordedObjects = [[HINSPHeapStackInspector recordedHeap] allObjects];
    XCTAssertTrue(([recordedObjects count] == 2), @"Recorded objects must be 2");
}

@end
