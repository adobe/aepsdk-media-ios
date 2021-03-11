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
@testable import AEPCore
@testable import AEPMedia

class MediaCoreTrackerTests: XCTestCase {
    // Disable preroll logic for tests
    static let media = MediaInfo(id: "id", name: "name", streamType: "aod", mediaType: MediaType.Audio, length: 60, resumed: false, prerollWaitingTime: 0, granularAdTracking: false)

    // Default preroll wait time
    static let mediaDefaultPrerollWait = MediaInfo(id: "id", name: "name", streamType: "aod", mediaType: MediaType.Audio, length: 60)

    // Custom preroll wait time
    static let mediaCustomPrerollWait = MediaInfo(id: "id", name: "name", streamType: "aod", mediaType: MediaType.Audio, length: 60, resumed: false, prerollWaitingTime: 5000, granularAdTracking: false)

    static let metadata = [
        "k1":"v1"
    ]

    static let denyListMetadata = [
        "vAlid_keY.12": "valid_value.@$%!2",
        "inv@lidKey": "validValue123",
        "":"valid_@_Value",
        "invalidKey!": "valid_value",
        "valid_key": ""
    ]
    
    static let cleanMetadata = [
        "vAlid_keY.12": "valid_value.@$%!2",
        "valid_key": ""
    ]
    
    static let KEY_INFO = "key_info"
    static let KEY_METADATA = "key_metadata"
    static let  KEY_EVENT_TS = "key_eventts"
    
    static let adbreak1 = AdBreakInfo(name: "adbreak1", position: 1, startTime: 10.0)
    static let adbreak2 = AdBreakInfo(name: "adbreak2", position: 2, startTime: 20.0)
    
    static let ad1 = AdInfo(id: "ad1", name: "adname1", position: 1, length: 15.0)
    static let ad2 = AdInfo(id: "ad2", name: "adname2", position: 2, length: 15.0)
    
    static let chapter1 = ChapterInfo(name: "chapter1", position: 1, startTime: 10.0, length: 30.0)
    static let chapter2 = ChapterInfo(name: "chapter2", position: 2, startTime: 30.0, length: 30.0)
    
    static let qoe = QoEInfo(bitrate: 1.1, droppedFrames: 2.2, fps: 3.3, startupTime: 4.4)
    
    static let stateMute = StateInfo(stateName: "mute")

    static let config: [String:Any] = [:]
    var fakeMediaProcessor: MediaProcessor?
    var mediaTracker: MediaCoreTracker?
    var eventGenerator: MediaPublicTracker?
    var capturedEvents: [Event] = []
    var ts = TimeInterval()
    
    func dispatch(event: Event) {
        capturedEvents.append(event)
    }
    
    func handleTrackAPI(incrementTS: Double? = 0) -> Bool {
        let ms: Double = 1000
        usleep(useconds_t(500 * ms))
        
        ts = ts + (incrementTS ?? 0)
        let eventSize = capturedEvents.count
        if(eventSize == 0 || mediaTracker == nil) {
            return false
        }
        let event = capturedEvents[eventSize-1]
        var eventData = event.data
        eventData?[MediaConstants.Tracker.EVENT_TIMESTAMP] = ts
        return mediaTracker!.track(eventData: eventData)
    }
    
    func compareRuleNames(list1: [(name: Int, context: [String: Any])], list2:[(name: Int, context: [String: Any])]) -> Bool {
        if list1.count != list2.count {
            return false
        }
        
        for i in 0...list1.count-1 {
            let a = list1[i]
            let b = list2[i]
            
            if a.name != b.name {
                return false
            }
        }
        
        return true
    }
    
    override func setUp() {
        EventHub.reset()
        MockExtension.reset()
        EventHub.shared.start()
        registerMockExtension(MockExtension.self)
        
        eventGenerator = MediaPublicTracker(dispatch: dispatch(event:), config: Self.config)
        fakeMediaProcessor = FakeMediaProcessor()
        mediaTracker = MediaCoreTracker(hitProcessor: fakeMediaProcessor!, config: Self.config)
    }

    private func registerMockExtension<T: Extension> (_ type: T.Type) {
        let semaphore = DispatchSemaphore(value: 0)
        EventHub.shared.registerExtension(type) { (error) in
            semaphore.signal()
        }

        semaphore.wait()
    }
    
    
    //MARK: MediaCoreTracker Unit Tests
    func testTrackeventHandleAbsentEventData() {
        XCTAssertFalse(mediaTracker!.track(eventData: nil))
    }
    
    func testTrackeventHandleAbsentEventName() {
        eventGenerator?.trackSessionStart(info: Self.media!.toMap(), metadata: Self.metadata)
        
        let event = capturedEvents[0]
        var eventData = event.data
        eventData?.removeValue(forKey: MediaConstants.Tracker.EVENT_NAME)
        
        XCTAssertFalse(mediaTracker!.track(eventData: eventData))
    }
    
    func testTrackeventHandleIncorrectEventName() {
        eventGenerator?.trackSessionStart(info: Self.media!.toMap(), metadata: Self.metadata)
        
        let event = capturedEvents[0]
        var eventData = event.data
        eventData?[MediaConstants.Tracker.EVENT_NAME] = "incorrect"
        
        XCTAssertFalse(mediaTracker!.track(eventData: eventData))
    }
    
    func testTrackeventHandleAbsentEventTimeStamp() {
        eventGenerator?.trackSessionStart(info: Self.media!.toMap(), metadata: Self.metadata)
        
        let event = capturedEvents[0]
        var eventData = event.data
        eventData?.removeValue(forKey: MediaConstants.Tracker.EVENT_TIMESTAMP)
        
        XCTAssertFalse(mediaTracker!.track(eventData: eventData))
    }
    
    func testTrackSessionStartFailOtherAPIsBeforeStart() {
        eventGenerator?.trackPlay()
        XCTAssertFalse(handleTrackAPI())

        eventGenerator?.trackPause()
        XCTAssertFalse(handleTrackAPI())

        eventGenerator?.trackComplete()
        XCTAssertFalse(handleTrackAPI())
        
        eventGenerator?.trackSessionEnd()
        XCTAssertFalse(handleTrackAPI())
        
        eventGenerator?.trackError(errorId: "error")
        XCTAssertFalse(handleTrackAPI())

        eventGenerator?.trackEvent(event: MediaConstants.EventName.BITRATE_CHANGE)
        XCTAssertFalse(handleTrackAPI())

        eventGenerator?.updateCurrentPlayhead(time: 1.0)
        XCTAssertFalse(handleTrackAPI())

        eventGenerator?.updateQoEObject(qoe: Self.qoe!.toMap())
        XCTAssertFalse(handleTrackAPI())
    }
    
    func testTrackSessionStartPass() {
        eventGenerator?.trackSessionStart(info: Self.media!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
    }
    
    func testTrackSessionStartWithDenyListMetadataPass() {
        eventGenerator?.trackSessionStart(info: Self.media!.toMap(), metadata: Self.denyListMetadata)
        XCTAssertTrue(handleTrackAPI())
        let actualMetadata = mediaTracker!.mediaContext!.getMetadata()
        XCTAssertEqual(Self.cleanMetadata, actualMetadata)
    }
    
    func testTrackSessionStartAlreadyInSessionStartFail() {
        eventGenerator?.trackSessionStart(info: Self.media!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        eventGenerator?.trackSessionStart(info: Self.media!.toMap(), metadata: Self.metadata)
        XCTAssertFalse(handleTrackAPI())
    }
    
    func testTrackSessionStartInvalidMediaInfo() {
        eventGenerator?.trackSessionStart(info: [:], metadata: Self.metadata)
        XCTAssertFalse(handleTrackAPI())
    }
    
    func testTrackSessionEndPass() {
        eventGenerator?.trackSessionStart(info: Self.media!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackSessionEnd()
        XCTAssertTrue(handleTrackAPI())
    }
    
    func testTrackSessionEndFailOtherCallsAfterEnd() {
        eventGenerator?.trackSessionStart(info: Self.media!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackSessionEnd()
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackPlay()
        XCTAssertFalse(handleTrackAPI())

        eventGenerator?.trackPause()
        XCTAssertFalse(handleTrackAPI())

        eventGenerator?.trackComplete()
        XCTAssertFalse(handleTrackAPI())
        
        eventGenerator?.trackSessionEnd()
        XCTAssertFalse(handleTrackAPI())
        
        eventGenerator?.trackError(errorId: "error")
        XCTAssertFalse(handleTrackAPI())

        eventGenerator?.trackEvent(event: MediaConstants.EventName.BITRATE_CHANGE)
        XCTAssertFalse(handleTrackAPI())

        eventGenerator?.updateCurrentPlayhead(time: 1.0)
        XCTAssertFalse(handleTrackAPI())

        eventGenerator?.updateQoEObject(qoe: Self.qoe!.toMap())
        XCTAssertFalse(handleTrackAPI())
    }
    
    func testTrackCompletePass() {
        eventGenerator?.trackSessionStart(info: Self.media!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackSessionEnd()
        XCTAssertTrue(handleTrackAPI())
    }
    
    func testTrackCompleteFailOtherCallsAfterComplete() {
        eventGenerator?.trackSessionStart(info: Self.media!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackComplete()
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackPlay()
        XCTAssertFalse(handleTrackAPI())

        eventGenerator?.trackPause()
        XCTAssertFalse(handleTrackAPI())

        eventGenerator?.trackComplete()
        XCTAssertFalse(handleTrackAPI())
        
        eventGenerator?.trackSessionEnd()
        XCTAssertFalse(handleTrackAPI())
        
        eventGenerator?.trackError(errorId: "error")
        XCTAssertFalse(handleTrackAPI())

        eventGenerator?.trackEvent(event: MediaConstants.EventName.BITRATE_CHANGE)
        XCTAssertFalse(handleTrackAPI())

        eventGenerator?.updateCurrentPlayhead(time: 1.0)
        XCTAssertFalse(handleTrackAPI())

        eventGenerator?.updateQoEObject(qoe: Self.qoe!.toMap())
        XCTAssertFalse(handleTrackAPI())
    }
    
    func testTrackErrorPass() {
        eventGenerator?.trackSessionStart(info: Self.media!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackError(errorId: "error")
        XCTAssertTrue(handleTrackAPI())
    }
    
    func testTrackBitrateChangePass() {
        eventGenerator?.trackSessionStart(info: Self.media!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.BITRATE_CHANGE)
        XCTAssertTrue(handleTrackAPI())
    }

    func testTrackPlayPass() {
        eventGenerator?.trackSessionStart(info: Self.media!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackPlay()
        XCTAssertTrue(handleTrackAPI())
    }
    
    func testTrackPlayInBufferingPass() {
        eventGenerator?.trackSessionStart(info: Self.media!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.BUFFER_START)
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackPlay()
        XCTAssertTrue(handleTrackAPI())
    }
    
    func testTrackPlayInSeekingPass() {
        eventGenerator?.trackSessionStart(info: Self.media!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.SEEK_START)
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackPlay()
        XCTAssertTrue(handleTrackAPI())
    }
    
    func testTrackPausePass() {
        eventGenerator?.trackSessionStart(info: Self.media!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackPause()
        XCTAssertTrue(handleTrackAPI())
    }
    
    func testTrackPauseInBufferingPass() {
        eventGenerator?.trackSessionStart(info: Self.media!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.BUFFER_START)
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackPause()
        XCTAssertFalse(handleTrackAPI())
    }
    
    func testTrackPauseInSeekingPass() {
        eventGenerator?.trackSessionStart(info: Self.media!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.SEEK_START)
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackPause()
        XCTAssertFalse(handleTrackAPI())
    }
    
    func testTrackBufferStartPass() {
        eventGenerator?.trackSessionStart(info: Self.media!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.BUFFER_START)
        XCTAssertTrue(handleTrackAPI())
    }
    
    func testTrackBufferStartInBufferingFail() {
        eventGenerator?.trackSessionStart(info: Self.media!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.BUFFER_START)
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.BUFFER_START)
        XCTAssertFalse(handleTrackAPI())
    }
    
    func testTrackBufferStartInSeekingFail() {
        eventGenerator?.trackSessionStart(info: Self.media!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.SEEK_START)
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.BUFFER_START)
        XCTAssertFalse(handleTrackAPI())
    }
    
    func testTrackBufferCompletePass() {
        eventGenerator?.trackSessionStart(info: Self.media!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.BUFFER_START)
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.BUFFER_COMPLETE)
        XCTAssertTrue(handleTrackAPI())
    }
    
    func testTrackBufferCompleteNotBufferingFail() {
        eventGenerator?.trackSessionStart(info: Self.media!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.BUFFER_COMPLETE)
        XCTAssertFalse(handleTrackAPI())
    }
    
    func testTrackSeekStartPass() {
        eventGenerator?.trackSessionStart(info: Self.media!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.SEEK_START)
        XCTAssertTrue(handleTrackAPI())
    }
    
    func testTrackSeekStartInBufferingFail() {
        eventGenerator?.trackSessionStart(info: Self.media!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.BUFFER_START)
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.SEEK_START)
        XCTAssertFalse(handleTrackAPI())
    }
    
    func testTrackSeekStartInSeekingFail() {
        eventGenerator?.trackSessionStart(info: Self.media!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.SEEK_START)
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.SEEK_START)
        XCTAssertFalse(handleTrackAPI())
    }
    
    func testTrackSeekCompletePass() {
        eventGenerator?.trackSessionStart(info: Self.media!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.SEEK_START)
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.SEEK_COMPLETE)
        XCTAssertTrue(handleTrackAPI())
    }
    
    func testTrackSeekCompleteNotSeekingFail() {
        eventGenerator?.trackSessionStart(info: Self.media!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.SEEK_COMPLETE)
        XCTAssertFalse(handleTrackAPI())
    }
    
    func testTrackAdBreakStartPass() {
        eventGenerator?.trackSessionStart(info: Self.media!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.ADBREAK_START, info: Self.adbreak1!.toMap())
        XCTAssertTrue(handleTrackAPI())
        
        let actualAdBreak = mediaTracker!.mediaContext!.getAdBreakInfo()
        XCTAssertEqual(Self.adbreak1, actualAdBreak)
    }
    
    func testTrackAdBreakStartInvalidInfoFail() {
        eventGenerator?.trackSessionStart(info: Self.media!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.ADBREAK_START)
        XCTAssertFalse(handleTrackAPI())
        
        let actualAdBreak = mediaTracker!.mediaContext!.getAdBreakInfo()
        XCTAssertNil(actualAdBreak)
    }
    
    func testTrackAdBreakStartDuplicateInfoFail() {
        eventGenerator?.trackSessionStart(info: Self.media!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.ADBREAK_START, info: Self.adbreak1!.toMap())
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.ADBREAK_START, info: Self.adbreak1!.toMap())
        XCTAssertFalse(handleTrackAPI())
    }
    
    func testTrackAdBreakStartRepalceAdBreakNotInAdPass() {
        eventGenerator?.trackSessionStart(info: Self.media!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.ADBREAK_START, info: Self.adbreak1!.toMap())
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.ADBREAK_START, info: Self.adbreak2!.toMap())
        XCTAssertTrue(handleTrackAPI())
    }
    
    func testTrackAdBreakStartReplaceAdBreakInAdPass() {
        eventGenerator?.trackSessionStart(info: Self.media!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.ADBREAK_START, info: Self.adbreak1!.toMap())
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.AD_START, info: Self.ad1!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.ADBREAK_START, info: Self.adbreak2!.toMap())
        XCTAssertTrue(handleTrackAPI())
        
        let actualAdBreak = mediaTracker!.mediaContext!.getAdBreakInfo()
        XCTAssertEqual(Self.adbreak2, actualAdBreak)
    }
    
    func testTrackAdBreakCompleteWithoutAdBreakStartFail() {
        eventGenerator?.trackSessionStart(info: Self.media!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.ADBREAK_COMPLETE)
        XCTAssertFalse(handleTrackAPI())
    }
    
    func testTrackAdBreakCompleteNotInAdPass() {
        eventGenerator?.trackSessionStart(info: Self.media!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.ADBREAK_START, info: Self.adbreak1!.toMap())
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.ADBREAK_COMPLETE)
        XCTAssertTrue(handleTrackAPI())
        
        let actualAdBreak = mediaTracker!.mediaContext!.getAdBreakInfo()
        XCTAssertNil(actualAdBreak)
    }
    
    func testTrackAdBreakCompleteInAdPass() {
        eventGenerator?.trackSessionStart(info: Self.media!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.ADBREAK_START, info: Self.adbreak1!.toMap())
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.AD_START, info: Self.ad1!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.ADBREAK_COMPLETE)
        XCTAssertTrue(handleTrackAPI())
        
        let actualAdBreak = mediaTracker!.mediaContext!.getAdBreakInfo()
        XCTAssertNil(actualAdBreak)
        
        let actualAd = mediaTracker!.mediaContext!.getAdInfo()
        XCTAssertNil(actualAd)
    }
    
    func testTrackAdStartPass() {
        eventGenerator?.trackSessionStart(info: Self.media!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.ADBREAK_START, info: Self.adbreak1!.toMap())
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.AD_START, info: Self.ad1!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        
        let actualAd = mediaTracker!.mediaContext!.getAdInfo()
        XCTAssertEqual(Self.ad1, actualAd)
    }
    
    func testTrackAdStartWithDenyListMetadataPass() {
        eventGenerator?.trackSessionStart(info: Self.media!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.ADBREAK_START, info: Self.adbreak1!.toMap())
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.AD_START, info: Self.ad1!.toMap(), metadata: Self.denyListMetadata)
        XCTAssertTrue(handleTrackAPI())
        
        let actualMetadata = mediaTracker!.mediaContext!.getAdMetadata()
        XCTAssertEqual(Self.cleanMetadata, actualMetadata)
    }
    
    func testTrackAdStartInvalidInfoFail() {
        eventGenerator?.trackSessionStart(info: Self.media!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.ADBREAK_START)
        XCTAssertFalse(handleTrackAPI())
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.AD_START)
        XCTAssertFalse(handleTrackAPI())
    }
    
    func testTrackAdStartDuplicateInfoFail() {
        eventGenerator?.trackSessionStart(info: Self.media!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.ADBREAK_START, info: Self.adbreak1!.toMap())
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.AD_START, info: Self.ad1!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.AD_START, info: Self.ad1!.toMap(), metadata: Self.metadata)
        XCTAssertFalse(handleTrackAPI())
    }
    
    func testTrackAdStartNotInAdBreakFail() {
        eventGenerator?.trackSessionStart(info: Self.media!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.AD_START, info: Self.ad1!.toMap(), metadata: Self.metadata)
        XCTAssertFalse(handleTrackAPI())
    }
    
    func testTrackAdStartReplaceAd() {
        eventGenerator?.trackSessionStart(info: Self.media!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.ADBREAK_START, info: Self.adbreak1!.toMap())
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.AD_START, info: Self.ad1!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.AD_START, info: Self.ad2!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        
        let actualAd = mediaTracker!.mediaContext!.getAdInfo()
        XCTAssertEqual(Self.ad2, actualAd)
    }

    func testTrackAdCompleteNoAdBreakFail() {
        eventGenerator?.trackSessionStart(info: Self.media!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.AD_COMPLETE)
        XCTAssertFalse(handleTrackAPI())
    }
    
    func testTrackAdCompleteNoAdStartFail() {
        eventGenerator?.trackSessionStart(info: Self.media!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.ADBREAK_START, info: Self.adbreak1!.toMap())
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.AD_COMPLETE)
        XCTAssertFalse(handleTrackAPI())
    }
    
    func testTrackAdCompletePass() {
        eventGenerator?.trackSessionStart(info: Self.media!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.ADBREAK_START, info: Self.adbreak1!.toMap())
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.AD_START, info: Self.ad1!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.AD_COMPLETE)
        XCTAssertTrue(handleTrackAPI())
        
        let actualAd = mediaTracker!.mediaContext!.getAdInfo()
        XCTAssertNil(actualAd)
    }
    
    func testAdSkipNoAdBreakFail() {
        eventGenerator?.trackSessionStart(info: Self.media!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.AD_COMPLETE)
        XCTAssertFalse(handleTrackAPI())
        
    }
    
    func testAdSkipNoAdFail() {
        eventGenerator?.trackSessionStart(info: Self.media!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.ADBREAK_START, info: Self.adbreak1!.toMap())
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.AD_SKIP)
        XCTAssertFalse(handleTrackAPI())
        
    }
    
    func testAdSkipPass() {
        eventGenerator?.trackSessionStart(info: Self.media!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.ADBREAK_START, info: Self.adbreak1!.toMap())
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.AD_START, info: Self.ad1!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.AD_SKIP)
        XCTAssertTrue(handleTrackAPI())
        
        let actualAd = mediaTracker!.mediaContext!.getAdInfo()
        XCTAssertNil(actualAd)
        
    }
    
    func testChapterStartPass() {
        eventGenerator?.trackSessionStart(info: Self.media!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.CHAPTER_START, info: Self.chapter1!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        
        let actualChapter = mediaTracker!.mediaContext!.getChapterInfo()
        XCTAssertEqual(Self.chapter1, actualChapter)
    }
    
    func testChapterStartInvalidInfoFail() {
        eventGenerator?.trackSessionStart(info: Self.media!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.CHAPTER_START)
        XCTAssertFalse(handleTrackAPI())
    }
    
    func testChapterStartDuplicateInfoFail() {
        eventGenerator?.trackSessionStart(info: Self.media!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.CHAPTER_START, info: Self.chapter1!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.CHAPTER_START, info: Self.chapter1!.toMap(), metadata: Self.metadata)
        XCTAssertFalse(handleTrackAPI())
    }
    
    func testChapterStartReplaceChapterPass() {
        eventGenerator?.trackSessionStart(info: Self.media!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.CHAPTER_START, info: Self.chapter1!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.CHAPTER_START, info: Self.chapter2!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        
        let actualChapter = mediaTracker!.mediaContext!.getChapterInfo()
        XCTAssertEqual(Self.chapter2, actualChapter)
    }
    
    func testChapterCompleteNoChapterStartFail() {
        eventGenerator?.trackSessionStart(info: Self.media!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.CHAPTER_COMPLETE)
        XCTAssertFalse(handleTrackAPI())
    }
    
    func testChapterCompletePass() {
        eventGenerator?.trackSessionStart(info: Self.media!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.CHAPTER_START, info: Self.chapter1!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.CHAPTER_SKIP)
        XCTAssertTrue(handleTrackAPI())
        
        let actualChapter = mediaTracker!.mediaContext!.getChapterInfo()
        XCTAssertNil(actualChapter)
    }
    
    func testChapterSkipNoChapterSkipFail() {
        eventGenerator?.trackSessionStart(info: Self.media!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.CHAPTER_COMPLETE)
        XCTAssertFalse(handleTrackAPI())
    }
    
    func testChapterSkipPass() {
        eventGenerator?.trackSessionStart(info: Self.media!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.CHAPTER_START, info: Self.chapter1!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.CHAPTER_SKIP)
        XCTAssertTrue(handleTrackAPI())
        
        let actualChapter = mediaTracker!.mediaContext!.getChapterInfo()
        XCTAssertNil(actualChapter)
    }
    
    func testUpdatePlayheadPass() {
        eventGenerator?.trackSessionStart(info: Self.media!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.updateCurrentPlayhead(time: 1.1)
        XCTAssertTrue(handleTrackAPI())
        
        let actualPlayhead = mediaTracker!.mediaContext!.getPlayhead()
        XCTAssertEqual(1.1, actualPlayhead)
    }
    
    func testUpdateQoEPass() {
        eventGenerator?.trackSessionStart(info: Self.media!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.updateQoEObject(qoe: Self.qoe!.toMap())
        XCTAssertTrue(handleTrackAPI())
        
        let actualQoE = mediaTracker!.mediaContext!.getQoEInfo()
        XCTAssertEqual(Self.qoe, actualQoE)
    }
    
    func testUpdateQoEFail() {
        eventGenerator?.trackSessionStart(info: Self.media!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.updateQoEObject(qoe: [:])
        XCTAssertFalse(handleTrackAPI())
    }

    func testStateStartPass() {
        eventGenerator?.trackSessionStart(info: Self.media!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.STATE_START, info: Self.stateMute!.toMap())
        XCTAssertTrue(handleTrackAPI())
    }
    
    func testStateStartInvalidInfoFail() {
        eventGenerator?.trackSessionStart(info: Self.media!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.STATE_START)
        XCTAssertFalse(handleTrackAPI())
    }
    
    func testStateStartSameStateFail() {
        eventGenerator?.trackSessionStart(info: Self.media!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.STATE_START, info: Self.stateMute!.toMap())
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.STATE_START, info: Self.stateMute!.toMap())
        XCTAssertFalse(handleTrackAPI())
    }
    
    func testStateStartMaxStateLimitReachedFail() {
        eventGenerator?.trackSessionStart(info: Self.media!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        for i in 0...9 {
            let state = StateInfo(stateName: "state\(i)")
            eventGenerator?.trackEvent(event: MediaConstants.EventName.STATE_START, info: state!.toMap())
            XCTAssertTrue(handleTrackAPI())
        }
        eventGenerator?.trackEvent(event: MediaConstants.EventName.STATE_START, info: Self.stateMute!.toMap())
        XCTAssertFalse(handleTrackAPI())
    }
    
    // Track 10 states, track 11th fail, end all 10 states, start all 10 states again
    func testStateStartMaxStateLimitReachedAndRetrackPass() {
        eventGenerator?.trackSessionStart(info: Self.media!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        for i in 0...9 {
            let state = StateInfo(stateName: "state\(i)")
            eventGenerator?.trackEvent(event: MediaConstants.EventName.STATE_START, info: state!.toMap())
            XCTAssertTrue(handleTrackAPI())
        }
        eventGenerator?.trackEvent(event: MediaConstants.EventName.STATE_START, info: Self.stateMute!.toMap())
        XCTAssertFalse(handleTrackAPI())
        
        for i in 0...9 {
            let state = StateInfo(stateName: "state\(i)")
            eventGenerator?.trackEvent(event: MediaConstants.EventName.STATE_END, info: state!.toMap())
            XCTAssertTrue(handleTrackAPI())
            
            eventGenerator?.trackEvent(event: MediaConstants.EventName.STATE_START, info: state!.toMap())
            XCTAssertTrue(handleTrackAPI())
        }
    }
    
    func testStateEndPass() {
        eventGenerator?.trackSessionStart(info: Self.media!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.STATE_START, info: Self.stateMute!.toMap())
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.STATE_END, info: Self.stateMute!.toMap())
        XCTAssertTrue(handleTrackAPI())
    }
    
    func testStateEndInvalidInfoFail() {
        eventGenerator?.trackSessionStart(info: Self.media!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.STATE_START, info: Self.stateMute!.toMap())
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.STATE_END)
        XCTAssertFalse(handleTrackAPI())
    }
    
    func testStateEndWithoutStateStartFail() {
        eventGenerator?.trackSessionStart(info: Self.media!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.STATE_END, info: Self.stateMute!.toMap())
        XCTAssertFalse(handleTrackAPI())
    }
    
    func testStateTogglePass() {
        eventGenerator?.trackSessionStart(info: Self.media!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.STATE_START, info: Self.stateMute!.toMap())
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.STATE_END, info: Self.stateMute!.toMap())
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.STATE_START, info: Self.stateMute!.toMap())
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.STATE_END, info: Self.stateMute!.toMap())
        XCTAssertTrue(handleTrackAPI())
    }
    
    func testStateNewSession() {
        eventGenerator?.trackSessionStart(info: Self.media!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        
        for i in 0...9 {
            let state = StateInfo(stateName: "state\(i)")
            eventGenerator?.trackEvent(event: MediaConstants.EventName.STATE_START, info: state!.toMap())
            XCTAssertTrue(handleTrackAPI())
        }
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.STATE_START, info: Self.stateMute!.toMap())
        XCTAssertFalse(handleTrackAPI())
        
        eventGenerator?.trackSessionEnd()
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackSessionStart(info: Self.media!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        
        for i in 0...9 {
            let state = StateInfo(stateName: "newstate\(i)")
            
            eventGenerator?.trackEvent(event: MediaConstants.EventName.STATE_START, info: state!.toMap())
            XCTAssertTrue(handleTrackAPI())
        }
    }
    
    func testStateIdleExitReTrackStates() {
        eventGenerator?.trackSessionStart(info: Self.media!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackPlay()
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.STATE_START, info: Self.stateMute!.toMap())
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.SEEK_START)
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.updateCurrentPlayhead(time: 1)
        XCTAssertTrue(handleTrackAPI(incrementTS: (31*60*1000)))
        
        XCTAssertTrue(mediaTracker!.trackerIdle)
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.SEEK_COMPLETE)
        XCTAssertTrue(handleTrackAPI())
        
        XCTAssertFalse(mediaTracker!.trackerIdle)
    }
    
    // Preroll unit tests
    
    func testPrerollDisabled() {
        eventGenerator?.trackSessionStart(info: Self.media!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        
        XCTAssertFalse(mediaTracker!.inPrerollInterval)
    }
    
    func testPrerollEnabledDefaultInterval() {
        eventGenerator?.trackSessionStart(info: Self.mediaDefaultPrerollWait!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        
        XCTAssertTrue(mediaTracker!.inPrerollInterval)
    }
    
    func testPrerollEnabledCustomInterval() {
        eventGenerator?.trackSessionStart(info: Self.mediaCustomPrerollWait!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        
        XCTAssertTrue(mediaTracker!.inPrerollInterval)
    }
    
    func testPrerollEnabledExceedDefaultInterval() {
        eventGenerator?.trackSessionStart(info: Self.mediaDefaultPrerollWait!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        
        XCTAssertTrue(mediaTracker!.inPrerollInterval)
        
        eventGenerator?.updateCurrentPlayhead(time: 0.2)
        XCTAssertTrue(handleTrackAPI(incrementTS: 200))
        
        XCTAssertTrue(mediaTracker!.inPrerollInterval)
        
        eventGenerator?.updateCurrentPlayhead(time: 0.4)
        XCTAssertTrue(handleTrackAPI(incrementTS: 200))
        
        XCTAssertFalse(mediaTracker!.inPrerollInterval)
    }
    
    func testPrerollEnabledExceedCustomInterval() {
        eventGenerator?.trackSessionStart(info: Self.mediaCustomPrerollWait!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        
        XCTAssertTrue(mediaTracker!.inPrerollInterval)
        
        eventGenerator?.updateCurrentPlayhead(time: 2)
        XCTAssertTrue(handleTrackAPI(incrementTS: 2000))
        
        XCTAssertTrue(mediaTracker!.inPrerollInterval)
        
        eventGenerator?.updateCurrentPlayhead(time: 5)
        XCTAssertTrue(handleTrackAPI(incrementTS: 3001))
        
        XCTAssertFalse(mediaTracker!.inPrerollInterval)
    }
    
    func testPrerollTrackSessionEnd() {
        eventGenerator?.trackSessionStart(info: Self.mediaDefaultPrerollWait!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        
        XCTAssertTrue(mediaTracker!.inPrerollInterval)
        
        eventGenerator?.trackSessionEnd()
        XCTAssertTrue(handleTrackAPI())
        
        XCTAssertFalse(mediaTracker!.inPrerollInterval)
    }
    
    func testPrerollTrackComplete() {
        eventGenerator?.trackSessionStart(info: Self.mediaDefaultPrerollWait!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        
        XCTAssertTrue(mediaTracker!.inPrerollInterval)
        
        eventGenerator?.trackComplete()
        XCTAssertTrue(handleTrackAPI())
        
        XCTAssertFalse(mediaTracker!.inPrerollInterval)
    }
    
    func testPrerollTrackEventAdBreakStart() {
        eventGenerator?.trackSessionStart(info: Self.mediaDefaultPrerollWait!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        
        XCTAssertTrue(mediaTracker!.inPrerollInterval)
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.ADBREAK_START, info: Self.adbreak1!.toMap())
        XCTAssertTrue(handleTrackAPI())
        
        XCTAssertFalse(mediaTracker!.inPrerollInterval)
    }
    
    func testPrerollReorderNoAdBreak() {
        let rules: [(name: Int, context: [String: Any])] = [
            (name: MediaCoreTracker.RuleName.Play.rawValue, context: [:]),
            (name: MediaCoreTracker.RuleName.Pause.rawValue, context: [:]),
            (name: MediaCoreTracker.RuleName.ChapterStart.rawValue, context: [:])
        ]
        
        let reorderedRules = mediaTracker!.prerollReorderRules(rules: rules)
        
        XCTAssertTrue(compareRuleNames(list1: rules, list2: reorderedRules))
    }
    
    func testPrerollReorderNoPlay() {
        let rules: [(name: Int, context: [String: Any])] = [
            (name: MediaCoreTracker.RuleName.Pause.rawValue, context: [:]),
            (name: MediaCoreTracker.RuleName.AdBreakStart.rawValue, context: [:]),
            (name: MediaCoreTracker.RuleName.AdStart.rawValue, context: [:])
        ]
        
        let reorderedRules = mediaTracker!.prerollReorderRules(rules: rules)
        
        XCTAssertTrue(compareRuleNames(list1: rules, list2: reorderedRules))
    }
    
    func testPrerollReorderPlayBeforeAdBreak() {
        let rules: [(name: Int, context: [String: Any])] = [
            (name: MediaCoreTracker.RuleName.Play.rawValue, context: [:]),
            (name: MediaCoreTracker.RuleName.AdBreakStart.rawValue, context: [:]),
            (name: MediaCoreTracker.RuleName.AdStart.rawValue, context: [:])
        ]
        
        let expectedReorderedRules: [(name: Int, context: [String: Any])] = [
            (name: MediaCoreTracker.RuleName.AdBreakStart.rawValue, context: [:]),
            (name: MediaCoreTracker.RuleName.AdStart.rawValue, context: [:])
        ]
        
        let reorderedRules = mediaTracker!.prerollReorderRules(rules: rules)
        
        XCTAssertTrue(compareRuleNames(list1: expectedReorderedRules, list2: reorderedRules))
    }
    
    func testIdleEnter() {
        eventGenerator?.trackSessionStart(info: Self.mediaDefaultPrerollWait!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackPause()
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackPause()
        XCTAssertTrue(handleTrackAPI(incrementTS: (31*60*1000)))
        
        XCTAssertTrue(mediaTracker!.trackerIdle)
    }
    
    func testIdleExit() {
        eventGenerator?.trackSessionStart(info: Self.mediaDefaultPrerollWait!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackPlay()
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.SEEK_START)
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.updateCurrentPlayhead(time: 1)
        XCTAssertTrue(handleTrackAPI(incrementTS: (31*60*1000))) // 31 minutes
        
        XCTAssertTrue(mediaTracker!.trackerIdle)
        
        eventGenerator?.trackEvent(event: MediaConstants.EventName.SEEK_COMPLETE)
        XCTAssertTrue(handleTrackAPI())
        
        XCTAssertFalse(mediaTracker!.trackerIdle)
    }
    
    func testSessionTimeout() {
        eventGenerator?.trackSessionStart(info: Self.mediaDefaultPrerollWait!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackPlay()
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.updateCurrentPlayhead(time: 1)
        XCTAssertTrue(handleTrackAPI(incrementTS: (24*60*60*1000))) //24 hours
        
        // Tracker is not idle after Media Session Restarted after MediaSessionTimeout(24hrs)
        XCTAssertFalse(mediaTracker!.trackerIdle)
        
        eventGenerator?.trackPause()
        XCTAssertTrue(handleTrackAPI())
    }
    
    func testTrackerIdleSessionTimeoutFail() {
        eventGenerator?.trackSessionStart(info: Self.mediaDefaultPrerollWait!.toMap(), metadata: Self.metadata)
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.trackPause()
        XCTAssertTrue(handleTrackAPI())
        
        eventGenerator?.updateCurrentPlayhead(time: 1)
        XCTAssertTrue(handleTrackAPI(incrementTS: (24*60*60*1000))) //24 hours
        
        XCTAssertTrue(mediaTracker!.trackerIdle)
    }
    
    func testHelperGetMetadata() {
        var context: [String:Any] = [:]
        
        XCTAssertNil(mediaTracker!.getMetadata(context: context))
        
        context[Self.KEY_METADATA] = nil
        XCTAssertNil(mediaTracker!.getMetadata(context: context))
        
        context[Self.KEY_METADATA] = ""
        XCTAssertNil(mediaTracker!.getMetadata(context: context))
        
        context[Self.KEY_METADATA] = ["k1":"v1"]
        XCTAssertEqual(["k1":"v1"], mediaTracker!.getMetadata(context: context))
    }
    
    func testHelperGetPlayhead() {
        var context: [String:Any] = [:]
        
        XCTAssertNil(mediaTracker!.getPlayhead(context: context))
        
        context[Self.KEY_INFO] = nil
        XCTAssertNil(mediaTracker!.getPlayhead(context: context))
        
        context[Self.KEY_INFO] = ""
        XCTAssertNil(mediaTracker!.getPlayhead(context: context))
        
        context[Self.KEY_INFO] = [MediaConstants.Tracker.PLAYHEAD:nil]
        XCTAssertNil(mediaTracker!.getPlayhead(context: context))
        
        context[Self.KEY_INFO] = [MediaConstants.Tracker.PLAYHEAD:""]
        XCTAssertNil(mediaTracker!.getPlayhead(context: context))
        
        context[Self.KEY_INFO] = [MediaConstants.Tracker.PLAYHEAD:1.0]
        XCTAssertEqual(1.0, mediaTracker!.getPlayhead(context: context))
    }
    
    func testHelperGetRefTS() {
        var context: [String:Any] = [:]
        
        XCTAssertNil(mediaTracker!.getRefTS(context: context))
        
        context[Self.KEY_EVENT_TS] = nil
        XCTAssertNil(mediaTracker!.getRefTS(context: context))
        
        context[Self.KEY_EVENT_TS] = ""
        XCTAssertNil(mediaTracker!.getRefTS(context: context))
        
        context[Self.KEY_EVENT_TS] = 100.0
        XCTAssertEqual(100, mediaTracker!.getRefTS(context: context))
    }
    
    func testHelperGetError() {
        var context: [String:Any] = [:]
        
        XCTAssertNil(mediaTracker!.getError(context: context))
        
        context[Self.KEY_INFO] = nil
        XCTAssertNil(mediaTracker!.getError(context: context))
        
        context[Self.KEY_INFO] = ""
        XCTAssertNil(mediaTracker!.getError(context: context))
        
        context[Self.KEY_INFO] = [MediaConstants.ErrorInfo.ID:nil]
        XCTAssertNil(mediaTracker!.getError(context: context))
        
        context[Self.KEY_INFO] = [MediaConstants.ErrorInfo.ID:1.0]
        XCTAssertNil(mediaTracker!.getError(context: context))
        
        context[Self.KEY_INFO] = [MediaConstants.ErrorInfo.ID:"error"]
        XCTAssertEqual("error", mediaTracker!.getError(context: context))
    }
}
