//
//  SwiftExampleTests.swift
//  SwiftExampleTests
//
//  Created by Christian Menschel on 09/03/16.
//  Copyright © 2016 tapwork. All rights reserved.
//

import XCTest
import HeapInspector

class SwiftExampleTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        HINSPDebug.start()
        HINSPDebug.addSwiftModules(toRecord: ["SwiftExampleTests"])
    }
    
    override func tearDown() {
        HINSPDebug.stop()
        super.tearDown()
    }
    
    func testDetailViewController() {
        let debug = HINSPDebug()
        debug.perform(NSSelectorFromString("beginRecord"))
        let detailViewController = ViewController()
        let recordedObjects = HINSPHeapStackInspector.recordedHeap() as NSSet
        XCTAssertTrue((recordedObjects.count == 1), "Recorded objects must be one")
        XCTAssertNotNil(detailViewController, "Just to suppres the warning")
    }
}
