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

- (void)testRecordAll
{
    [HINSPDebug startWithClassPrefix:@"UI"];
    self.tableView = [[UITableView alloc] init];
    [HINSPDebug stop];
    NSArray *recordedObjects = [[HINSPHeapStackInspector recordedHeapStack] allObjects];
    XCTAssertTrue(([recordedObjects count] > 1), @"Recorded objects must be greater than one");
}

- (void)testRecordBacktrace
{
    [HINSPDebug startWithClassPrefix:@"UITableView"];
    [HINSPDebug recordBacktraces:YES];
    [NSObject beginSnapshotWithClassPrefix:@"UITableView"];
    self.tableView = [[UITableView alloc] init];
    [HINSPDebug stop];
    
    NSArray *refHistory = [NSObject referenceHistoryForObject:self.tableView];
    XCTAssertTrue(([refHistory count] > 1), @"Backtrace objects must be greater than one");
}

- (void)testRecordSpecificClass
{
    [HINSPDebug startWithClassPrefix:@"RM"];
    self.controller = [[RMGalleryWrongViewCotroller alloc] init];
    [HINSPDebug stop];
    NSArray *recordedObjects = [[HINSPHeapStackInspector recordedHeapStack] allObjects];
    XCTAssertTrue(([recordedObjects count] == 3), @"Recorded objects must be three");   
}

@end
