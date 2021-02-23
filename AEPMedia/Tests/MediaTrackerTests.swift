/*
 Copyright 2021 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0
 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

import XCTest
import AEPCore
@testable import AEPMedia

class MediaTrackerTests: XCTestCase {
    let testConfig: [String: Any] = ["test":"value"]
    var capturedEvent: Event?
   
    
    override func setUp() {
    }

    override func tearDown() {
        reset()
    }
    
    func reset() {
        capturedEvent = nil
    }
    
    func dispatch(event: Event) {
        capturedEvent = event
    }
    
    //MARK: MediaTracker Unit Tests
    // ==========================================================================
    // create
    // ==========================================================================
    func testCreateTracker() {
        let tracker = MediaTracker(dispatch: dispatch(event:), config: nil)
        
        XCTAssertNotNil(tracker)
        XCTAssertEqual(MediaConstants.Media.EVENT_SOURCE_TRACKER_REQUEST, capturedEvent?.source)
        XCTAssertEqual(MediaConstants.Media.EVENT_TYPE, capturedEvent?.type)
        
        let data = capturedEvent?.data
        XCTAssertFalse((data?[MediaConstants.Tracker.ID] as? String ?? "").isEmpty)
        XCTAssertTrue((data?[MediaConstants.Tracker.EVENT_PARAM] as? [String:Any] ?? [:]).isEmpty)
    }
    
    func testCreateTrackerWithConfig() {
        let tracker = MediaTracker(dispatch: dispatch(event:), config: testConfig)
        
        XCTAssertNotNil(tracker)
        XCTAssertEqual(MediaConstants.Media.EVENT_SOURCE_TRACKER_REQUEST, capturedEvent?.source)
        
        let data = capturedEvent?.data
        XCTAssertFalse((data?[MediaConstants.Tracker.ID] as? String ?? "").isEmpty)
        let configData = data?[MediaConstants.Tracker.EVENT_PARAM] as? [String:Any] ?? [:]
        XCTAssertEqual("value", configData["test"] as? String)
    }
    
    
    // ==========================================================================
    // sessionStart
    // ==========================================================================
    func testSessionStart() {
        
    }
}
