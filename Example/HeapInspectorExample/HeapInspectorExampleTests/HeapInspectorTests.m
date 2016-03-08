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


@interface HeapInspectorTests : XCTestCase

@property (nonatomic) UITableView *tableView;
@property (nonatomic) UIViewController *controller;

@end

@implementation HeapInspectorTests

- (void)setUp {
    [super setUp];
    [HINSPDebug start];
}

- (void)tearDown
{
    [HINSPDebug stop];
    [super tearDown];
}

- (void)testRecordAll
{
    [HINSPDebug addClassPrefixesToRecord:@[@"UI"]];
    self.tableView = [[UITableView alloc] init];
    NSArray *recordedObjects = [[HINSPHeapStackInspector recordedHeapStack] allObjects];
    XCTAssertTrue(([recordedObjects count] > 1), @"Recorded objects must be greater than one");
}

- (void)testRecordBacktrace
{
    [HINSPDebug addClassPrefixesToRecord:@[@"UITableView"]];
    [HINSPDebug recordBacktraces:YES];
    [NSObject beginSnapshot];
    self.tableView = [[UITableView alloc] init];
    NSArray *refHistory = [NSObject referenceHistoryForObject:self.tableView];
    XCTAssertTrue(([refHistory count] > 1), @"Backtrace objects must be greater than one");
}

- (void)testRecordSpecificClass
{
    [HINSPDebug addClassPrefixesToRecord:@[@"RM"]];
    self.controller = [[RMGalleryWrongViewCotroller alloc] init];
    NSArray *recordedObjects = [[HINSPHeapStackInspector recordedHeapStack] allObjects];
    XCTAssertTrue(([recordedObjects count] == 1), @"Recorded objects must be one");
}

- (void)testRecordMultiplePrefixes
{
    [HINSPDebug addClassPrefixesToRecord:@[@"UITableViewWrapperView", @"RM"]];
    self.controller = [[RMGalleryWrongViewCotroller alloc] init];
    self.tableView = [[UITableView alloc] init];
    NSArray *recordedObjects = [[HINSPHeapStackInspector recordedHeapStack] allObjects];
    XCTAssertTrue(([recordedObjects count] == 2), @"Recorded objects must be 4");
}

@end
