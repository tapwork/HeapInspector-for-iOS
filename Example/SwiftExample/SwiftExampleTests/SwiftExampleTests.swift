//
//  SwiftExampleTests.swift
//  SwiftExampleTests
//
//  Created by Christian Menschel on 07/03/16.
//  Copyright © 2016 TAPWORK. All rights reserved.
//

import XCTest
import HeapInspector

class SwiftExampleTests: XCTestCase {

    override func setUp() {
        super.setUp()
        HINSPDebug.start()
        HINSPDebug.addSwiftModulesToRecord(["SwiftExampleTests"])
    }
    
    override func tearDown() {
        HINSPDebug.stop()
        super.tearDown()
    }
    
    func testDetailViewController() {
        let debug = HINSPDebug()
        debug.performSelector(NSSelectorFromString("beginRecord"))
        let detailViewController = DetailViewController()
        let recordedObjects = HINSPHeapStackInspector.recordedHeapStack() as NSSet
        XCTAssertTrue((recordedObjects.count == 1), "Recorded objects must be one")
        XCTAssertNotNil(detailViewController, "Just to suppres the warning")
    }
}
