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
        HINSPDebug.addSwiftModulesToRecord(["SwiftExample", "SwiftExampleTests"])
    }
    
    override func tearDown() {
        HINSPDebug.stop()
        super.tearDown()
    }
    
    func testDetailViewController() {
        let detailViewController = DetailViewController()
        let recordedObjects = HINSPHeapStackInspector.recordedHeapStack()
        XCTAssertTrue((recordedObjects.count == 2), "Recorded objects must be two")
        XCTAssertNotNil(detailViewController, "Just to suppres the warning")
    }
}
