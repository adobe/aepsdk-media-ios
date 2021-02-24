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

class MediaPublicTrackerTests: XCTestCase {
    static let testConfig: [String: Any] = ["test":"value"]
    static let metadata: [String: String] = ["key": "value"]
    static let validMediaInfo : [String : Any] = [
        MediaConstants.MediaInfo.ID : "testId",
        MediaConstants.MediaInfo.NAME : "testName",
        MediaConstants.MediaInfo.LENGTH : 10.0,
        MediaConstants.MediaInfo.STREAM_TYPE : "aod",
        MediaConstants.MediaInfo.MEDIA_TYPE : "audio",
        MediaConstants.MediaInfo.RESUMED :true,
        MediaConstants.MediaInfo.PREROLL_TRACKING_WAITING_TIME : 2000.0, //2000 milliseconds
        MediaConstants.MediaInfo.GRANULAR_AD_TRACKING : true
    ]
    
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
    
    func isEqualMediaInfo(map1: [String:Any], map2: [String:Any]) -> Bool {
        let mediaObject1 = MediaInfo(info: map1)
        let mediaObject2 = MediaInfo(info: map2)
        
        if(mediaObject1 == nil || mediaObject2 == nil) {
            return false
        }
        
        return mediaObject1 == mediaObject2
    }
    
    //MARK: MediaTracker Unit Tests
    // ==========================================================================
    // create
    // ==========================================================================
    func testCreateTracker() {
        let tracker = MediaPublicTracker(dispatch: dispatch(event:), config: nil)
        
        XCTAssertNotNil(tracker)
        XCTAssertEqual(MediaConstants.Media.EVENT_SOURCE_TRACKER_REQUEST, capturedEvent?.source)
        XCTAssertEqual(MediaConstants.Media.EVENT_TYPE, capturedEvent?.type)
        
        let data = capturedEvent?.data
        XCTAssertFalse((data?[MediaConstants.Tracker.ID] as? String ?? "").isEmpty)
        XCTAssertTrue((data?[MediaConstants.Tracker.EVENT_PARAM] as? [String:Any] ?? [:]).isEmpty)
    }
    
    func testCreateTrackerWithConfig() {
        let tracker = MediaPublicTracker(dispatch: dispatch(event:), config: Self.testConfig)
        
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
        let tracker = MediaPublicTracker(dispatch: dispatch(event:), config: Self.testConfig)
        tracker.trackSessionStart(info: Self.validMediaInfo)
        
        sleep(1)
        
        let data = capturedEvent?.data
        let actualInfo = data?[MediaConstants.Tracker.EVENT_PARAM] as? [String:Any] ?? [:]
        let actualEventMetadata = data?[MediaConstants.Tracker.EVENT_METADATA] as? [String:String] ?? [:]
        let actualEventName = data?[MediaConstants.Tracker.EVENT_NAME] as? String ?? ""
        let actualEventInternal = data?[MediaConstants.Tracker.EVENT_INTERNAL] as? Bool ?? true
        
        XCTAssertFalse((data?[MediaConstants.Tracker.ID] as? String ?? "").isEmpty)
        XCTAssertFalse((data?[MediaConstants.Tracker.SESSION_ID] as? String ?? "").isEmpty)
        
        XCTAssertEqual(MediaConstants.EventName.SESSION_START, actualEventName)
        XCTAssertTrue(isEqualMediaInfo(map1: Self.validMediaInfo, map2: actualInfo))
        XCTAssertEqual([:], actualEventMetadata)
        XCTAssertEqual(false, actualEventInternal)
        
    }
    
    func testSessionStartWithMetadata() {
        let tracker = MediaPublicTracker(dispatch: dispatch(event:), config: Self.testConfig)
        tracker.trackSessionStart(info: Self.validMediaInfo, metadata: Self.metadata)
        
        sleep(1)
        
        let data = capturedEvent?.data
        let actualInfo = data?[MediaConstants.Tracker.EVENT_PARAM] as? [String:Any] ?? [:]
        let actualEventMetadata = data?[MediaConstants.Tracker.EVENT_METADATA] as? [String:String] ?? [:]
        let actualEventName = data?[MediaConstants.Tracker.EVENT_NAME] as? String ?? ""
        let actualEventInternal = data?[MediaConstants.Tracker.EVENT_INTERNAL] as? Bool ?? true
        
        XCTAssertFalse((data?[MediaConstants.Tracker.ID] as? String ?? "").isEmpty)
        XCTAssertFalse((data?[MediaConstants.Tracker.SESSION_ID] as? String ?? "").isEmpty)
        
        XCTAssertEqual(MediaConstants.EventName.SESSION_START, actualEventName)
        XCTAssertTrue(isEqualMediaInfo(map1: Self.validMediaInfo, map2: actualInfo))
        XCTAssertEqual(Self.metadata, actualEventMetadata)
        XCTAssertEqual(false, actualEventInternal)
    }
    
    // ==========================================================================
    // sessionComplete
    // ==========================================================================
    func testComplete() {
        let tracker = MediaPublicTracker(dispatch: dispatch(event:), config: Self.testConfig)
        tracker.trackComplete()
        
        sleep(1)
        
        let data = capturedEvent?.data
        let actualInfo = data?[MediaConstants.Tracker.EVENT_PARAM] as? [String:Any]
        let actualEventMetadata = data?[MediaConstants.Tracker.EVENT_METADATA] as? [String:String]
        let actualEventName = data?[MediaConstants.Tracker.EVENT_NAME] as? String ?? ""
        let actualEventInternal = data?[MediaConstants.Tracker.EVENT_INTERNAL] as? Bool ?? true
        
        XCTAssertFalse((data?[MediaConstants.Tracker.ID] as? String ?? "").isEmpty)
        XCTAssertFalse((data?[MediaConstants.Tracker.SESSION_ID] as? String ?? "").isEmpty)
        
        XCTAssertEqual(MediaConstants.EventName.COMPLETE, actualEventName)
        XCTAssertNil(actualInfo)
        XCTAssertNil(actualEventMetadata)
        XCTAssertEqual(false, actualEventInternal)
    }
    
    // ==========================================================================
    // sessionEnd
    // ==========================================================================
    func testSessionEnd() {
        let tracker = MediaPublicTracker(dispatch: dispatch(event:), config: Self.testConfig)
        tracker.trackSessionEnd()
        
        sleep(1)
        
        let data = capturedEvent?.data
        let actualInfo = data?[MediaConstants.Tracker.EVENT_PARAM] as? [String:Any]
        let actualEventMetadata = data?[MediaConstants.Tracker.EVENT_METADATA] as? [String:String]
        let actualEventName = data?[MediaConstants.Tracker.EVENT_NAME] as? String ?? ""
        let actualEventInternal = data?[MediaConstants.Tracker.EVENT_INTERNAL] as? Bool ?? true
        
        XCTAssertFalse((data?[MediaConstants.Tracker.ID] as? String ?? "").isEmpty)
        XCTAssertFalse((data?[MediaConstants.Tracker.SESSION_ID] as? String ?? "").isEmpty)
        
        XCTAssertEqual(MediaConstants.EventName.SESSION_END, actualEventName)
        XCTAssertNil(actualInfo)
        XCTAssertNil(actualEventMetadata)
        XCTAssertEqual(false, actualEventInternal)
    }
    
}
