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

class MediaPublicTrackerMock: MediaPublicTracker {
    var mockTimeStamp = TimeInterval()

    override init(dispatch: @escaping dispatchFn, config: [String: Any]?) {
        super.init(dispatch: dispatch, config: config)
    }
    
    override func getCurrentTimeStamp() -> TimeInterval {
        return mockTimeStamp;
    }
    
    func setTimeStamp(value: TimeInterval) {
        mockTimeStamp = value
    }
}

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
    
    static let validQoeInfo : [String: Any] = [
        MediaConstants.QoEInfo.BITRATE: 1.1,
        MediaConstants.QoEInfo.DROPPED_FRAMES: 2.2,
        MediaConstants.QoEInfo.FPS: 3.3,
        MediaConstants.QoEInfo.STARTUP_TIME: 4.4
    ]
  
    static let validAdBreakInfo : [String: Any] = [
        MediaConstants.AdBreakInfo.NAME: "testAdBreakName",
        MediaConstants.AdBreakInfo.POSITION: 2,
        MediaConstants.AdBreakInfo.START_TIME: 1.1
    ]
    
    static let validAdInfo : [String: Any] = [
        MediaConstants.AdInfo.ID: "testAdId",
        MediaConstants.AdInfo.NAME: "testAdName",
        MediaConstants.AdInfo.POSITION: 1,
        MediaConstants.AdInfo.LENGTH: 16.0
        
    ]
    
    static let validChapterInfo : [String: Any] = [
        MediaConstants.ChapterInfo.NAME: "testChapterName",
        MediaConstants.ChapterInfo.POSITION: 1,
        MediaConstants.ChapterInfo.START_TIME: 0.2,
        MediaConstants.ChapterInfo.LENGTH: 30.0
    ]
    
    static let validStateInfo : [String: Any] = [
        MediaConstants.StateInfo.STATE_NAME_KEY: "testStateName"
        
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
        let object1 = MediaInfo(info: map1)
        let object2 = MediaInfo(info: map2)
        
        if(object1 == nil || object2 == nil) {
            return false
        }
        
        return object1 == object2
    }
    
    // TODO
//    func isEqualQoEInfo(map1: [String:Any], map2: [String:Any]) -> Bool {
//        let object1 = QoEInfo(info: map1)
//        let object2 = QoEInfo(info: map2)
//
//        if(object1 == nil || object2 == nil) {
//            return false
//        }
//
//        return object1 == object2
//    }
//
//    func isEqualAdBreakInfo(map1: [String:Any], map2: [String:Any]) -> Bool {
//        let object1 = AdBreakInfo(info: map1)
//        let object2 = AdBreakInfo(info: map2)
//
//        if(object1 == nil || object2 == nil) {
//            return false
//        }
//
//        return object1 == object2
//    }
//
//    func isEqualAdInfo(map1: [String:Any], map2: [String:Any]) -> Bool {
//        let object1 = AdInfo(info: map1)
//        let object2 = AdInfo(info: map2)
//
//        if(object1 == nil || object2 == nil) {
//            return false
//        }
//
//        return object1 == object2
//    }
//
//    func isEqualChapterInfo(map1: [String:Any], map2: [String:Any]) -> Bool {
//        let object1 = ChapterInfo(info: map1)
//        let object2 = ChapterInfo(info: map2)
//
//        if(object1 == nil || object2 == nil) {
//            return false
//        }
//
//        return object1 == object2
//    }
//
//    func isEqualStateInfo(map1: [String:Any], map2: [String:Any]) -> Bool {
//        let object1 = StateInfo(info: map1)
//        let object2 = StateInfo(info: map2)
//
//        if(object1 == nil || object2 == nil) {
//            return false
//        }
//
//        return object1 == object2
//    }
    
    //MARK: MediaTracker Unit Tests
    // ==========================================================================
    // create
    // ==========================================================================
    func testCreateTracker() {
        let tracker = MediaPublicTrackerMock(dispatch: dispatch(event:), config: nil)
        
        XCTAssertNotNil(tracker)
        XCTAssertEqual(MediaConstants.Media.EVENT_SOURCE_TRACKER_REQUEST, capturedEvent?.source)
        XCTAssertEqual(MediaConstants.Media.EVENT_TYPE, capturedEvent?.type)
        
        let data = capturedEvent?.data
        XCTAssertFalse((data?[MediaConstants.Tracker.ID] as? String ?? "").isEmpty)
        XCTAssertTrue((data?[MediaConstants.Tracker.EVENT_PARAM] as? [String:Any] ?? [:]).isEmpty)
    }
    
    func testCreateTrackerWithConfig() {
        let tracker = MediaPublicTrackerMock(dispatch: dispatch(event:), config: Self.testConfig)
        
        XCTAssertNotNil(tracker)
        XCTAssertEqual(MediaConstants.Media.EVENT_SOURCE_TRACKER_REQUEST, capturedEvent?.source)
        
        let data = capturedEvent?.data
        XCTAssertFalse((data?[MediaConstants.Tracker.ID] as? String ?? "").isEmpty)
        let configData = data?[MediaConstants.Tracker.EVENT_PARAM] as? [String:Any] ?? [:]
        XCTAssertEqual("value", configData["test"] as? String)
    }
    
    
    // ==========================================================================
    // trackAPIs
    // ==========================================================================
    func test_trackSessionStart() {
        let tracker = MediaPublicTrackerMock(dispatch: dispatch(event:), config: Self.testConfig)
        tracker.trackSessionStart(info: Self.validMediaInfo)
        
        sleep(1)
        
        let data = capturedEvent?.data
        let actualInfo = data?[MediaConstants.Tracker.EVENT_PARAM] as? [String:Any] ?? [:]
        let actualEventMetadata = data?[MediaConstants.Tracker.EVENT_METADATA] as? [String:String] ?? [:]
        let actualEventName = data?[MediaConstants.Tracker.EVENT_NAME] as? String ?? ""
        let actualEventTs = data?[MediaConstants.Tracker.EVENT_TIMESTAMP] as? TimeInterval ?? 1.0
        let actualEventInternal = data?[MediaConstants.Tracker.EVENT_INTERNAL] as? Bool ?? true
        
        XCTAssertFalse((data?[MediaConstants.Tracker.ID] as? String ?? "").isEmpty)
        XCTAssertFalse((data?[MediaConstants.Tracker.SESSION_ID] as? String ?? "").isEmpty)
        
        XCTAssertEqual(MediaConstants.EventName.SESSION_START, actualEventName)
        XCTAssertTrue(isEqualMediaInfo(map1: Self.validMediaInfo, map2: actualInfo))
        XCTAssertEqual([:], actualEventMetadata)
        XCTAssertEqual(tracker.mockTimeStamp, actualEventTs)
        XCTAssertEqual(false, actualEventInternal)
        
    }
    
    func test_trackSessionStartWithMetadata() {
        let tracker = MediaPublicTrackerMock(dispatch: dispatch(event:), config: Self.testConfig)
        tracker.trackSessionStart(info: Self.validMediaInfo, metadata: Self.metadata)
        
        sleep(1)
        
        let data = capturedEvent?.data
        let actualInfo = data?[MediaConstants.Tracker.EVENT_PARAM] as? [String:Any] ?? [:]
        let actualEventMetadata = data?[MediaConstants.Tracker.EVENT_METADATA] as? [String:String] ?? [:]
        let actualEventName = data?[MediaConstants.Tracker.EVENT_NAME] as? String ?? ""
        let actualEventTs = data?[MediaConstants.Tracker.EVENT_TIMESTAMP] as? TimeInterval ?? 1.0
        let actualEventInternal = data?[MediaConstants.Tracker.EVENT_INTERNAL] as? Bool ?? true
        
        XCTAssertFalse((data?[MediaConstants.Tracker.ID] as? String ?? "").isEmpty)
        XCTAssertFalse((data?[MediaConstants.Tracker.SESSION_ID] as? String ?? "").isEmpty)
        
        XCTAssertEqual(MediaConstants.EventName.SESSION_START, actualEventName)
        XCTAssertTrue(isEqualMediaInfo(map1: Self.validMediaInfo, map2: actualInfo))
        XCTAssertEqual(Self.metadata, actualEventMetadata)
        XCTAssertEqual(tracker.mockTimeStamp, actualEventTs)
        XCTAssertEqual(false, actualEventInternal)
    }
    
    func test_trackComplete() {
        let tracker = MediaPublicTrackerMock(dispatch: dispatch(event:), config: Self.testConfig)
        tracker.setTimeStamp(value: 100.0)
        tracker.trackComplete()
        
        sleep(1)
        
        let data = capturedEvent?.data
        let actualInfo = data?[MediaConstants.Tracker.EVENT_PARAM] as? [String:Any]
        let actualEventMetadata = data?[MediaConstants.Tracker.EVENT_METADATA] as? [String:String]
        let actualEventName = data?[MediaConstants.Tracker.EVENT_NAME] as? String ?? ""
        let actualEventTs = data?[MediaConstants.Tracker.EVENT_TIMESTAMP] as? TimeInterval ?? 1.0
        let actualEventInternal = data?[MediaConstants.Tracker.EVENT_INTERNAL] as? Bool ?? true
        
        XCTAssertFalse((data?[MediaConstants.Tracker.ID] as? String ?? "").isEmpty)
        XCTAssertFalse((data?[MediaConstants.Tracker.SESSION_ID] as? String ?? "").isEmpty)
        
        XCTAssertEqual(MediaConstants.EventName.COMPLETE, actualEventName)
        XCTAssertNil(actualInfo)
        XCTAssertNil(actualEventMetadata)
        XCTAssertEqual(tracker.mockTimeStamp, actualEventTs)
        XCTAssertEqual(false, actualEventInternal)
    }
    
    func test_trackSessionEnd() {
        let tracker = MediaPublicTrackerMock(dispatch: dispatch(event:), config: Self.testConfig)
        tracker.trackSessionEnd()
        
        sleep(1)
        
        let data = capturedEvent?.data
        let actualInfo = data?[MediaConstants.Tracker.EVENT_PARAM] as? [String:Any]
        let actualEventMetadata = data?[MediaConstants.Tracker.EVENT_METADATA] as? [String:String]
        let actualEventName = data?[MediaConstants.Tracker.EVENT_NAME] as? String ?? ""
        let actualEventTs = data?[MediaConstants.Tracker.EVENT_TIMESTAMP] as? TimeInterval ?? 1.0
        let actualEventInternal = data?[MediaConstants.Tracker.EVENT_INTERNAL] as? Bool ?? true
        
        XCTAssertFalse((data?[MediaConstants.Tracker.ID] as? String ?? "").isEmpty)
        XCTAssertFalse((data?[MediaConstants.Tracker.SESSION_ID] as? String ?? "").isEmpty)
        
        XCTAssertEqual(MediaConstants.EventName.SESSION_END, actualEventName)
        XCTAssertNil(actualInfo)
        XCTAssertNil(actualEventMetadata)
        XCTAssertEqual(tracker.mockTimeStamp, actualEventTs)
        XCTAssertEqual(false, actualEventInternal)
    }

    func test_trackPlay() {
        let tracker = MediaPublicTrackerMock(dispatch: dispatch(event:), config: Self.testConfig)
        tracker.trackPlay()
        
        sleep(1)
        
        let data = capturedEvent?.data
        let actualInfo = data?[MediaConstants.Tracker.EVENT_PARAM] as? [String:Any]
        let actualEventMetadata = data?[MediaConstants.Tracker.EVENT_METADATA] as? [String:String]
        let actualEventName = data?[MediaConstants.Tracker.EVENT_NAME] as? String ?? ""
        let actualEventTs = data?[MediaConstants.Tracker.EVENT_TIMESTAMP] as? TimeInterval ?? 1.0
        let actualEventInternal = data?[MediaConstants.Tracker.EVENT_INTERNAL] as? Bool ?? true
        
        XCTAssertFalse((data?[MediaConstants.Tracker.ID] as? String ?? "").isEmpty)
        XCTAssertFalse((data?[MediaConstants.Tracker.SESSION_ID] as? String ?? "").isEmpty)
        
        XCTAssertEqual(MediaConstants.EventName.PLAY, actualEventName)
        XCTAssertNil(actualInfo)
        XCTAssertNil(actualEventMetadata)
        XCTAssertEqual(tracker.mockTimeStamp, actualEventTs)
        XCTAssertEqual(false, actualEventInternal)
    }

    func test_trackPause() {
        let tracker = MediaPublicTrackerMock(dispatch: dispatch(event:), config: Self.testConfig)
        tracker.trackPause()
        
        sleep(1)
        
        let data = capturedEvent?.data
        let actualInfo = data?[MediaConstants.Tracker.EVENT_PARAM] as? [String:Any]
        let actualEventMetadata = data?[MediaConstants.Tracker.EVENT_METADATA] as? [String:String]
        let actualEventName = data?[MediaConstants.Tracker.EVENT_NAME] as? String ?? ""
        let actualEventTs = data?[MediaConstants.Tracker.EVENT_TIMESTAMP] as? TimeInterval ?? 1.0
        let actualEventInternal = data?[MediaConstants.Tracker.EVENT_INTERNAL] as? Bool ?? true
        
        XCTAssertFalse((data?[MediaConstants.Tracker.ID] as? String ?? "").isEmpty)
        XCTAssertFalse((data?[MediaConstants.Tracker.SESSION_ID] as? String ?? "").isEmpty)
        
        XCTAssertEqual(MediaConstants.EventName.PAUSE, actualEventName)
        XCTAssertNil(actualInfo)
        XCTAssertNil(actualEventMetadata)
        XCTAssertEqual(tracker.mockTimeStamp, actualEventTs)
        XCTAssertEqual(false, actualEventInternal)
    }
    
    func test_trackError() {
        let tracker = MediaPublicTrackerMock(dispatch: dispatch(event:), config: Self.testConfig)
        tracker.trackError(errorId: "testError")
        
        sleep(1)
        
        let data = capturedEvent?.data
        let actualInfo = data?[MediaConstants.Tracker.EVENT_PARAM] as? [String:Any]
        let actualEventMetadata = data?[MediaConstants.Tracker.EVENT_METADATA] as? [String:String]
        let actualEventName = data?[MediaConstants.Tracker.EVENT_NAME] as? String ?? ""
        let actualEventTs = data?[MediaConstants.Tracker.EVENT_TIMESTAMP] as? TimeInterval ?? 1.0
        let actualEventInternal = data?[MediaConstants.Tracker.EVENT_INTERNAL] as? Bool ?? true
        
        XCTAssertFalse((data?[MediaConstants.Tracker.ID] as? String ?? "").isEmpty)
        XCTAssertFalse((data?[MediaConstants.Tracker.SESSION_ID] as? String ?? "").isEmpty)
        
        XCTAssertEqual(MediaConstants.EventName.ERROR, actualEventName)
        XCTAssertNotNil(actualInfo)
        XCTAssertEqual("testError", actualInfo?[MediaConstants.ErrorInfo.ID] as? String ?? "")
        XCTAssertNil(actualEventMetadata)
        XCTAssertEqual(tracker.mockTimeStamp, actualEventTs)
        XCTAssertEqual(false, actualEventInternal)
    }
    
    func test_updateCurrentPlayhead() {
        let tracker = MediaPublicTrackerMock(dispatch: dispatch(event:), config: Self.testConfig)
        tracker.updateCurrentPlayhead(time: 1.23)
        
        sleep(1)
        
        let data = capturedEvent?.data
        let actualInfo = data?[MediaConstants.Tracker.EVENT_PARAM] as? [String:Any]
        let actualEventMetadata = data?[MediaConstants.Tracker.EVENT_METADATA] as? [String:String]
        let actualEventName = data?[MediaConstants.Tracker.EVENT_NAME] as? String ?? ""
        let actualEventTs = data?[MediaConstants.Tracker.EVENT_TIMESTAMP] as? TimeInterval ?? 1.0
        let actualEventInternal = data?[MediaConstants.Tracker.EVENT_INTERNAL] as? Bool ?? true
        
        XCTAssertFalse((data?[MediaConstants.Tracker.ID] as? String ?? "").isEmpty)
        XCTAssertFalse((data?[MediaConstants.Tracker.SESSION_ID] as? String ?? "").isEmpty)
        
        XCTAssertEqual(MediaConstants.EventName.PLAYHEAD_UPDATE, actualEventName)
        XCTAssertNotNil(actualInfo)
        XCTAssertEqual(1.23, actualInfo?[MediaConstants.Tracker.PLAYHEAD] as? Double ?? 0.0)
        XCTAssertNil(actualEventMetadata)
        XCTAssertEqual(tracker.mockTimeStamp, actualEventTs)
        XCTAssertEqual(false, actualEventInternal)
    }
    
    func test_updateQoEObject() {
        let tracker = MediaPublicTrackerMock(dispatch: dispatch(event:), config: Self.testConfig)
        tracker.updateQoEObject(qoe: Self.validQoeInfo)
        
        sleep(1)
        
        let data = capturedEvent?.data
        let actualInfo = data?[MediaConstants.Tracker.EVENT_PARAM] as? [String:Any]
        let actualEventMetadata = data?[MediaConstants.Tracker.EVENT_METADATA] as? [String:String]
        let actualEventName = data?[MediaConstants.Tracker.EVENT_NAME] as? String ?? ""
        let actualEventTs = data?[MediaConstants.Tracker.EVENT_TIMESTAMP] as? TimeInterval ?? 1.0
        let actualEventInternal = data?[MediaConstants.Tracker.EVENT_INTERNAL] as? Bool ?? true
        
        XCTAssertFalse((data?[MediaConstants.Tracker.ID] as? String ?? "").isEmpty)
        XCTAssertFalse((data?[MediaConstants.Tracker.SESSION_ID] as? String ?? "").isEmpty)
        
        XCTAssertEqual(MediaConstants.EventName.QOE_UPDATE, actualEventName)
        // TODO
        //XCTAssertTrue(isEqualQoEInfo(map1: Self.validQoeInfo, map2: actualInfo))
        XCTAssertNil(actualEventMetadata)
        XCTAssertEqual(tracker.mockTimeStamp, actualEventTs)
        XCTAssertEqual(false, actualEventInternal)
    }
    
    func test_trackEventAdBreakStart() {
        let tracker = MediaPublicTrackerMock(dispatch: dispatch(event:), config: Self.testConfig)
        tracker.trackEvent(event: MediaEvent.AdBreakStart, info: Self.validAdBreakInfo, metadata: Self.metadata)
        
        sleep(1)
        
        let data = capturedEvent?.data
        let actualInfo = data?[MediaConstants.Tracker.EVENT_PARAM] as? [String:Any]
        let actualEventMetadata = data?[MediaConstants.Tracker.EVENT_METADATA] as? [String:String]
        let actualEventName = data?[MediaConstants.Tracker.EVENT_NAME] as? String ?? ""
        let actualEventTs = data?[MediaConstants.Tracker.EVENT_TIMESTAMP] as? TimeInterval ?? 1.0
        let actualEventInternal = data?[MediaConstants.Tracker.EVENT_INTERNAL] as? Bool ?? true
        
        XCTAssertFalse((data?[MediaConstants.Tracker.ID] as? String ?? "").isEmpty)
        XCTAssertFalse((data?[MediaConstants.Tracker.SESSION_ID] as? String ?? "").isEmpty)
        
        XCTAssertEqual(MediaConstants.EventName.ADBREAK_START, actualEventName)
        // TODO
        //XCTAssertTrue(isEqualAdBreakInfo(map1: Self.validAdBreakInfo, map2: actualInfo))
        XCTAssertEqual(Self.metadata, actualEventMetadata)
        XCTAssertEqual(tracker.mockTimeStamp, actualEventTs)
        XCTAssertEqual(false, actualEventInternal)
    }
    
    func test_trackEventAdBreakComplete() {
        let tracker = MediaPublicTrackerMock(dispatch: dispatch(event:), config: Self.testConfig)
        tracker.trackEvent(event: MediaEvent.AdBreakComplete)
        
        sleep(1)
        
        let data = capturedEvent?.data
        let actualInfo = data?[MediaConstants.Tracker.EVENT_PARAM] as? [String:Any] 
        let actualEventMetadata = data?[MediaConstants.Tracker.EVENT_METADATA] as? [String:String]
        let actualEventName = data?[MediaConstants.Tracker.EVENT_NAME] as? String ?? ""
        let actualEventTs = data?[MediaConstants.Tracker.EVENT_TIMESTAMP] as? TimeInterval ?? 1.0
        let actualEventInternal = data?[MediaConstants.Tracker.EVENT_INTERNAL] as? Bool ?? true
        
        XCTAssertFalse((data?[MediaConstants.Tracker.ID] as? String ?? "").isEmpty)
        XCTAssertFalse((data?[MediaConstants.Tracker.SESSION_ID] as? String ?? "").isEmpty)
        
        XCTAssertEqual(MediaConstants.EventName.ADBREAK_COMPLETE, actualEventName)
        XCTAssertNil(actualInfo)
        XCTAssertNil(actualEventMetadata)
        XCTAssertEqual(tracker.mockTimeStamp, actualEventTs)
        XCTAssertEqual(false, actualEventInternal)
    }
    
    func test_trackEventAdStart() {
        let tracker = MediaPublicTrackerMock(dispatch: dispatch(event:), config: Self.testConfig)
        tracker.trackEvent(event: MediaEvent.AdStart, info: Self.validAdInfo, metadata: Self.metadata)
        
        sleep(1)
        
        let data = capturedEvent?.data
        let actualInfo = data?[MediaConstants.Tracker.EVENT_PARAM] as? [String:Any]
        let actualEventMetadata = data?[MediaConstants.Tracker.EVENT_METADATA] as? [String:String]
        let actualEventName = data?[MediaConstants.Tracker.EVENT_NAME] as? String ?? ""
        let actualEventTs = data?[MediaConstants.Tracker.EVENT_TIMESTAMP] as? TimeInterval ?? 1.0
        let actualEventInternal = data?[MediaConstants.Tracker.EVENT_INTERNAL] as? Bool ?? true
        
        XCTAssertFalse((data?[MediaConstants.Tracker.ID] as? String ?? "").isEmpty)
        XCTAssertFalse((data?[MediaConstants.Tracker.SESSION_ID] as? String ?? "").isEmpty)
        
        XCTAssertEqual(MediaConstants.EventName.AD_START, actualEventName)
        // TODO
        //XCTAssertTrue(isEqualAdInfo(map1: Self.validAdInfo, map2: actualInfo))
        XCTAssertEqual(Self.metadata, actualEventMetadata)
        XCTAssertEqual(tracker.mockTimeStamp, actualEventTs)
        XCTAssertEqual(false, actualEventInternal)
    }
    
    func test_trackEventAdComplete() {
        let tracker = MediaPublicTrackerMock(dispatch: dispatch(event:), config: Self.testConfig)
        tracker.trackEvent(event: MediaEvent.AdComplete)
        
        sleep(1)
        
        let data = capturedEvent?.data
        let actualInfo = data?[MediaConstants.Tracker.EVENT_PARAM] as? [String:Any]
        let actualEventMetadata = data?[MediaConstants.Tracker.EVENT_METADATA] as? [String:String]
        let actualEventName = data?[MediaConstants.Tracker.EVENT_NAME] as? String ?? ""
        let actualEventTs = data?[MediaConstants.Tracker.EVENT_TIMESTAMP] as? TimeInterval ?? 1.0
        let actualEventInternal = data?[MediaConstants.Tracker.EVENT_INTERNAL] as? Bool ?? true
        
        XCTAssertFalse((data?[MediaConstants.Tracker.ID] as? String ?? "").isEmpty)
        XCTAssertFalse((data?[MediaConstants.Tracker.SESSION_ID] as? String ?? "").isEmpty)
        
        XCTAssertEqual(MediaConstants.EventName.AD_COMPLETE, actualEventName)
        XCTAssertNil(actualInfo)
        XCTAssertNil(actualEventMetadata)
        XCTAssertEqual(tracker.mockTimeStamp, actualEventTs)
        XCTAssertEqual(false, actualEventInternal)
    }
    
    func test_trackEventAdSkip() {
        let tracker = MediaPublicTrackerMock(dispatch: dispatch(event:), config: Self.testConfig)
        tracker.trackEvent(event: MediaEvent.AdSkip)
        
        sleep(1)
        
        let data = capturedEvent?.data
        let actualInfo = data?[MediaConstants.Tracker.EVENT_PARAM] as? [String:Any]
        let actualEventMetadata = data?[MediaConstants.Tracker.EVENT_METADATA] as? [String:String]
        let actualEventName = data?[MediaConstants.Tracker.EVENT_NAME] as? String ?? ""
        let actualEventTs = data?[MediaConstants.Tracker.EVENT_TIMESTAMP] as? TimeInterval ?? 1.0
        let actualEventInternal = data?[MediaConstants.Tracker.EVENT_INTERNAL] as? Bool ?? true
        
        XCTAssertFalse((data?[MediaConstants.Tracker.ID] as? String ?? "").isEmpty)
        XCTAssertFalse((data?[MediaConstants.Tracker.SESSION_ID] as? String ?? "").isEmpty)
        
        XCTAssertEqual(MediaConstants.EventName.AD_SKIP, actualEventName)
        XCTAssertNil(actualInfo)
        XCTAssertNil(actualEventMetadata)
        XCTAssertEqual(tracker.mockTimeStamp, actualEventTs)
        XCTAssertEqual(false, actualEventInternal)
    }
    
    func test_trackEventChapterStart() {
        let tracker = MediaPublicTrackerMock(dispatch: dispatch(event:), config: Self.testConfig)
        tracker.trackEvent(event: MediaEvent.ChapterStart, info: Self.validChapterInfo, metadata: Self.metadata)
        
        sleep(1)
        
        let data = capturedEvent?.data
        let actualInfo = data?[MediaConstants.Tracker.EVENT_PARAM] as? [String:Any]
        let actualEventMetadata = data?[MediaConstants.Tracker.EVENT_METADATA] as? [String:String]
        let actualEventName = data?[MediaConstants.Tracker.EVENT_NAME] as? String ?? ""
        let actualEventTs = data?[MediaConstants.Tracker.EVENT_TIMESTAMP] as? TimeInterval ?? 1.0
        let actualEventInternal = data?[MediaConstants.Tracker.EVENT_INTERNAL] as? Bool ?? true
        
        XCTAssertFalse((data?[MediaConstants.Tracker.ID] as? String ?? "").isEmpty)
        XCTAssertFalse((data?[MediaConstants.Tracker.SESSION_ID] as? String ?? "").isEmpty)
        
        XCTAssertEqual(MediaConstants.EventName.CHAPTER_START, actualEventName)
        // TODO
        //XCTAssertTrue(isEqualAdInfo(map1: Self.validChapterInfo, map2: actualInfo))
        XCTAssertEqual(Self.metadata, actualEventMetadata)
        XCTAssertEqual(tracker.mockTimeStamp, actualEventTs)
        XCTAssertEqual(false, actualEventInternal)
    }
    
    func test_trackEventChapterCompelete() {
        let tracker = MediaPublicTrackerMock(dispatch: dispatch(event:), config: Self.testConfig)
        tracker.trackEvent(event: MediaEvent.ChapterComplete)
        
        sleep(1)
        
        let data = capturedEvent?.data
        let actualInfo = data?[MediaConstants.Tracker.EVENT_PARAM] as? [String:Any]
        let actualEventMetadata = data?[MediaConstants.Tracker.EVENT_METADATA] as? [String:String]
        let actualEventName = data?[MediaConstants.Tracker.EVENT_NAME] as? String ?? ""
        let actualEventTs = data?[MediaConstants.Tracker.EVENT_TIMESTAMP] as? TimeInterval ?? 1.0
        let actualEventInternal = data?[MediaConstants.Tracker.EVENT_INTERNAL] as? Bool ?? true
        
        XCTAssertFalse((data?[MediaConstants.Tracker.ID] as? String ?? "").isEmpty)
        XCTAssertFalse((data?[MediaConstants.Tracker.SESSION_ID] as? String ?? "").isEmpty)
        
        XCTAssertEqual(MediaConstants.EventName.CHAPTER_COMPLETE, actualEventName)
        XCTAssertNil(actualInfo)
        XCTAssertNil(actualEventMetadata)
        XCTAssertEqual(tracker.mockTimeStamp, actualEventTs)
        XCTAssertEqual(false, actualEventInternal)
    }
    
    func test_trackEventChapterSkip() {
        let tracker = MediaPublicTrackerMock(dispatch: dispatch(event:), config: Self.testConfig)
        tracker.trackEvent(event: MediaEvent.ChapterSkip)
        
        sleep(1)
        
        let data = capturedEvent?.data
        let actualInfo = data?[MediaConstants.Tracker.EVENT_PARAM] as? [String:Any]
        let actualEventMetadata = data?[MediaConstants.Tracker.EVENT_METADATA] as? [String:String]
        let actualEventName = data?[MediaConstants.Tracker.EVENT_NAME] as? String ?? ""
        let actualEventTs = data?[MediaConstants.Tracker.EVENT_TIMESTAMP] as? TimeInterval ?? 1.0
        let actualEventInternal = data?[MediaConstants.Tracker.EVENT_INTERNAL] as? Bool ?? true
        
        XCTAssertFalse((data?[MediaConstants.Tracker.ID] as? String ?? "").isEmpty)
        XCTAssertFalse((data?[MediaConstants.Tracker.SESSION_ID] as? String ?? "").isEmpty)
        
        XCTAssertEqual(MediaConstants.EventName.CHAPTER_SKIP, actualEventName)
        XCTAssertNil(actualInfo)
        XCTAssertNil(actualEventMetadata)
        XCTAssertEqual(tracker.mockTimeStamp, actualEventTs)
        XCTAssertEqual(false, actualEventInternal)
    }
    
    func test_trackEventStateStart() {
        let tracker = MediaPublicTrackerMock(dispatch: dispatch(event:), config: Self.testConfig)
        tracker.trackEvent(event: MediaEvent.StateStart, info: Self.validStateInfo)
        
        sleep(1)
        
        let data = capturedEvent?.data
        let actualInfo = data?[MediaConstants.Tracker.EVENT_PARAM] as? [String:Any]
        let actualEventMetadata = data?[MediaConstants.Tracker.EVENT_METADATA] as? [String:String]
        let actualEventName = data?[MediaConstants.Tracker.EVENT_NAME] as? String ?? ""
        let actualEventTs = data?[MediaConstants.Tracker.EVENT_TIMESTAMP] as? TimeInterval ?? 1.0
        let actualEventInternal = data?[MediaConstants.Tracker.EVENT_INTERNAL] as? Bool ?? true
        
        XCTAssertFalse((data?[MediaConstants.Tracker.ID] as? String ?? "").isEmpty)
        XCTAssertFalse((data?[MediaConstants.Tracker.SESSION_ID] as? String ?? "").isEmpty)
        
        XCTAssertEqual(MediaConstants.EventName.STATE_START, actualEventName)
        // TODO
        //XCTAssertTrue(isEqualQoEInfo(Self.validStateInfo, actualInfo))
        XCTAssertNil(actualEventMetadata)
        XCTAssertEqual(tracker.mockTimeStamp, actualEventTs)
        XCTAssertEqual(false, actualEventInternal)
    }
    
    func test_trackEventStateCompelete() {
        let tracker = MediaPublicTrackerMock(dispatch: dispatch(event:), config: Self.testConfig)
        tracker.trackEvent(event: MediaEvent.StateEnd, info: Self.validStateInfo)
        
        sleep(1)
        
        let data = capturedEvent?.data
        let actualInfo = data?[MediaConstants.Tracker.EVENT_PARAM] as? [String:Any]
        let actualEventMetadata = data?[MediaConstants.Tracker.EVENT_METADATA] as? [String:String]
        let actualEventName = data?[MediaConstants.Tracker.EVENT_NAME] as? String ?? ""
        let actualEventTs = data?[MediaConstants.Tracker.EVENT_TIMESTAMP] as? TimeInterval ?? 1.0
        let actualEventInternal = data?[MediaConstants.Tracker.EVENT_INTERNAL] as? Bool ?? true
        
        XCTAssertFalse((data?[MediaConstants.Tracker.ID] as? String ?? "").isEmpty)
        XCTAssertFalse((data?[MediaConstants.Tracker.SESSION_ID] as? String ?? "").isEmpty)
        
        XCTAssertEqual(MediaConstants.EventName.STATE_END, actualEventName)
        // TODO
        //XCTAssertTrue(isEqualQoEInfo(Self.validStateInfo, actualInfo))
        XCTAssertNil(actualEventMetadata)
        XCTAssertEqual(tracker.mockTimeStamp, actualEventTs)
        XCTAssertEqual(false, actualEventInternal)
    }
    
    func test_trackEventBufferStart() {
        let tracker = MediaPublicTrackerMock(dispatch: dispatch(event:), config: Self.testConfig)
        tracker.trackEvent(event: MediaEvent.BufferStart)
        
        sleep(1)
        
        let data = capturedEvent?.data
        let actualInfo = data?[MediaConstants.Tracker.EVENT_PARAM] as? [String:Any]
        let actualEventMetadata = data?[MediaConstants.Tracker.EVENT_METADATA] as? [String:String]
        let actualEventName = data?[MediaConstants.Tracker.EVENT_NAME] as? String ?? ""
        let actualEventTs = data?[MediaConstants.Tracker.EVENT_TIMESTAMP] as? TimeInterval ?? 1.0
        let actualEventInternal = data?[MediaConstants.Tracker.EVENT_INTERNAL] as? Bool ?? true
        
        XCTAssertFalse((data?[MediaConstants.Tracker.ID] as? String ?? "").isEmpty)
        XCTAssertFalse((data?[MediaConstants.Tracker.SESSION_ID] as? String ?? "").isEmpty)
        
        XCTAssertEqual(MediaConstants.EventName.BUFFER_START, actualEventName)
        XCTAssertNil(actualInfo)
        XCTAssertNil(actualEventMetadata)
        XCTAssertEqual(tracker.mockTimeStamp, actualEventTs)
        XCTAssertEqual(false, actualEventInternal)
    }
    
    func test_trackEventBufferComplete() {
        let tracker = MediaPublicTrackerMock(dispatch: dispatch(event:), config: Self.testConfig)
        tracker.trackEvent(event: MediaEvent.BufferComplete)
        
        sleep(1)
        
        let data = capturedEvent?.data
        let actualInfo = data?[MediaConstants.Tracker.EVENT_PARAM] as? [String:Any]
        let actualEventMetadata = data?[MediaConstants.Tracker.EVENT_METADATA] as? [String:String]
        let actualEventName = data?[MediaConstants.Tracker.EVENT_NAME] as? String ?? ""
        let actualEventTs = data?[MediaConstants.Tracker.EVENT_TIMESTAMP] as? TimeInterval ?? 1.0
        let actualEventInternal = data?[MediaConstants.Tracker.EVENT_INTERNAL] as? Bool ?? true
        
        XCTAssertFalse((data?[MediaConstants.Tracker.ID] as? String ?? "").isEmpty)
        XCTAssertFalse((data?[MediaConstants.Tracker.SESSION_ID] as? String ?? "").isEmpty)
        
        XCTAssertEqual(MediaConstants.EventName.BUFFER_COMPLETE, actualEventName)
        XCTAssertNil(actualInfo)
        XCTAssertNil(actualEventMetadata)
        XCTAssertEqual(tracker.mockTimeStamp, actualEventTs)
        XCTAssertEqual(false, actualEventInternal)
    }
    
    func test_trackEventSeekStart() {
        let tracker = MediaPublicTrackerMock(dispatch: dispatch(event:), config: Self.testConfig)
        tracker.trackEvent(event: MediaEvent.SeekStart)
        
        sleep(1)
        
        let data = capturedEvent?.data
        let actualInfo = data?[MediaConstants.Tracker.EVENT_PARAM] as? [String:Any]
        let actualEventMetadata = data?[MediaConstants.Tracker.EVENT_METADATA] as? [String:String]
        let actualEventName = data?[MediaConstants.Tracker.EVENT_NAME] as? String ?? ""
        let actualEventTs = data?[MediaConstants.Tracker.EVENT_TIMESTAMP] as? TimeInterval ?? 1.0
        let actualEventInternal = data?[MediaConstants.Tracker.EVENT_INTERNAL] as? Bool ?? true
        
        XCTAssertFalse((data?[MediaConstants.Tracker.ID] as? String ?? "").isEmpty)
        XCTAssertFalse((data?[MediaConstants.Tracker.SESSION_ID] as? String ?? "").isEmpty)
        
        XCTAssertEqual(MediaConstants.EventName.SEEK_START, actualEventName)
        XCTAssertNil(actualInfo)
        XCTAssertNil(actualEventMetadata)
        XCTAssertEqual(tracker.mockTimeStamp, actualEventTs)
        XCTAssertEqual(false, actualEventInternal)
    }
    
    func test_trackEventSeekComplete() {
        let tracker = MediaPublicTrackerMock(dispatch: dispatch(event:), config: Self.testConfig)
        tracker.trackEvent(event: MediaEvent.SeekComplete)
        
        sleep(1)
        
        let data = capturedEvent?.data
        let actualInfo = data?[MediaConstants.Tracker.EVENT_PARAM] as? [String:Any]
        let actualEventMetadata = data?[MediaConstants.Tracker.EVENT_METADATA] as? [String:String]
        let actualEventName = data?[MediaConstants.Tracker.EVENT_NAME] as? String ?? ""
        let actualEventTs = data?[MediaConstants.Tracker.EVENT_TIMESTAMP] as? TimeInterval ?? 1.0
        let actualEventInternal = data?[MediaConstants.Tracker.EVENT_INTERNAL] as? Bool ?? true
        
        XCTAssertFalse((data?[MediaConstants.Tracker.ID] as? String ?? "").isEmpty)
        XCTAssertFalse((data?[MediaConstants.Tracker.SESSION_ID] as? String ?? "").isEmpty)
        
        XCTAssertEqual(MediaConstants.EventName.SEEK_COMPLETE, actualEventName)
        XCTAssertNil(actualInfo)
        XCTAssertNil(actualEventMetadata)
        XCTAssertEqual(tracker.mockTimeStamp, actualEventTs)
        XCTAssertEqual(false, actualEventInternal)
    }
    
    func test_trackEventBitrateChange() {
        let tracker = MediaPublicTrackerMock(dispatch: dispatch(event:), config: Self.testConfig)
        tracker.trackEvent(event: MediaEvent.BitrateChange)
        
        sleep(1)
        
        let data = capturedEvent?.data
        let actualInfo = data?[MediaConstants.Tracker.EVENT_PARAM] as? [String:Any]
        let actualEventMetadata = data?[MediaConstants.Tracker.EVENT_METADATA] as? [String:String]
        let actualEventName = data?[MediaConstants.Tracker.EVENT_NAME] as? String ?? ""
        let actualEventTs = data?[MediaConstants.Tracker.EVENT_TIMESTAMP] as? TimeInterval ?? 1.0
        let actualEventInternal = data?[MediaConstants.Tracker.EVENT_INTERNAL] as? Bool ?? true
        
        XCTAssertFalse((data?[MediaConstants.Tracker.ID] as? String ?? "").isEmpty)
        XCTAssertFalse((data?[MediaConstants.Tracker.SESSION_ID] as? String ?? "").isEmpty)
        
        XCTAssertEqual(MediaConstants.EventName.BITRATE_CHANGE, actualEventName)
        XCTAssertNil(actualInfo)
        XCTAssertNil(actualEventMetadata)
        XCTAssertEqual(tracker.mockTimeStamp, actualEventTs)
        XCTAssertEqual(false, actualEventInternal)
    }
}
