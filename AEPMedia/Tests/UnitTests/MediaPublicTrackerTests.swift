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
    static let testConfig: [String: Any] = ["test": "value"]
    static let metadata: [String: String] = ["key": "value"]
    static let validMediaInfo: [String: Any] = [
        MediaConstants.MediaInfo.ID: "testId",
        MediaConstants.MediaInfo.NAME: "testName",
        MediaConstants.MediaInfo.LENGTH: 10.0,
        MediaConstants.MediaInfo.STREAM_TYPE: "aod",
        MediaConstants.MediaInfo.MEDIA_TYPE: "audio",
        MediaConstants.MediaInfo.RESUMED: true,
        MediaConstants.MediaInfo.PREROLL_TRACKING_WAITING_TIME: 2000.0, // 2000 milliseconds
        MediaConstants.MediaInfo.GRANULAR_AD_TRACKING: true
    ]

    static let validQoeInfo: [String: Any] = [
        MediaConstants.QoEInfo.BITRATE: 1.1,
        MediaConstants.QoEInfo.DROPPED_FRAMES: 2.2,
        MediaConstants.QoEInfo.FPS: 3.3,
        MediaConstants.QoEInfo.STARTUP_TIME: 4.4
    ]

    static let validAdBreakInfo: [String: Any] = [
        MediaConstants.AdBreakInfo.NAME: "testAdBreakName",
        MediaConstants.AdBreakInfo.POSITION: 2,
        MediaConstants.AdBreakInfo.START_TIME: 1.1
    ]

    static let validAdInfo: [String: Any] = [
        MediaConstants.AdInfo.ID: "testAdId",
        MediaConstants.AdInfo.NAME: "testAdName",
        MediaConstants.AdInfo.POSITION: 1,
        MediaConstants.AdInfo.LENGTH: 16.0
    ]

    static let validChapterInfo: [String: Any] = [
        MediaConstants.ChapterInfo.NAME: "testChapterName",
        MediaConstants.ChapterInfo.POSITION: 1,
        MediaConstants.ChapterInfo.START_TIME: 0.2,
        MediaConstants.ChapterInfo.LENGTH: 30.0
    ]

    static let validStateInfo: [String: Any] = [
        MediaConstants.StateInfo.STATE_NAME_KEY: "testStateName"
    ]

    func isEqual(map1: [String: Any]?, map2: [String: Any]?) -> Bool {
        if map1 == nil && map2 == nil {
            return true
        }

        guard let map1 = map1, let map2 = map2 else {
            return false
        }

        guard map1.count == map2.count else {
            return false
        }

        for (k1, v1) in map1 {
            guard let v2 = map2[k1] else { return false }
            switch (v1, v2) {
            case (let v1 as Double, let v2 as Double): if !v1.isAlmostEqual(v2) {return false}
            case (let v1 as Int, let v2 as Int): if v1 != v2 { return false }
            case (let v1 as String, let v2 as String): if v1 != v2 { return false }
            case (let v1 as Bool, let v2 as Bool): if v1 != v2 { return false }
            default: return false
            }
        }
        return true
    }

    func assertTrackEvent(event: Event?, expectedEventName: String, expectedParam: [String: Any] = [:], expectedMetadata: [String: Any] = [:], expectedTimestamp: Int64 = 0, expectedEventInternal: Bool = false) {

        guard let event = event else {
            XCTFail()
            return
        }

        XCTAssertEqual(event.source, MediaConstants.Media.EVENT_SOURCE_TRACK_MEDIA)
        XCTAssertEqual(event.type, MediaConstants.Media.EVENT_TYPE)

        let actualEventName = event.data?[MediaConstants.Tracker.EVENT_NAME] as? String ?? ""
        XCTAssertEqual(actualEventName, expectedEventName)

        let actualParam = event.data?[MediaConstants.Tracker.EVENT_PARAM] as? [String: Any] ?? [:]
        XCTAssertTrue(isEqual(map1: actualParam, map2: expectedParam))

        let actualMetadata = event.data?[MediaConstants.Tracker.EVENT_METADATA] as? [String: Any] ?? [:]
        XCTAssertTrue(isEqual(map1: actualMetadata, map2: expectedMetadata))

        let actualTimestamp = event.data?[MediaConstants.Tracker.EVENT_TIMESTAMP] as? Int64 ?? 0
        XCTAssertEqual(actualTimestamp, expectedTimestamp)

        let actualEventInternal = event.data?[MediaConstants.Tracker.EVENT_INTERNAL] as? Bool ?? false
        XCTAssertEqual(actualEventInternal, expectedEventInternal)

        XCTAssertFalse((event.data?[MediaConstants.Tracker.ID] as? String ?? "").isEmpty)
        XCTAssertFalse((event.data?[MediaConstants.Tracker.SESSION_ID] as? String ?? "").isEmpty)
    }

    // MARK: MediaTracker Unit Tests
    // ==========================================================================
    // create
    // ==========================================================================
    func testCreateTracker() {
        var capturedEvent: Event?
        _ = MediaPublicTracker(dispatch: {(event: Event) in
            capturedEvent = event
        }, config: nil)

        XCTAssertEqual(MediaConstants.Media.EVENT_SOURCE_TRACKER_REQUEST, capturedEvent?.source)
        XCTAssertEqual(MediaConstants.Media.EVENT_TYPE, capturedEvent?.type)

        let data = capturedEvent?.data
        XCTAssertFalse((data?[MediaConstants.Tracker.ID] as? String ?? "").isEmpty)

        let actualParam = data?[MediaConstants.Tracker.EVENT_PARAM] as? [String: Any] ?? [:]
        XCTAssertTrue(isEqual(map1: actualParam, map2: [:]))
    }

    func testCreateTrackerWithConfig() {
        var capturedEvent: Event?
        _ = MediaPublicTracker(dispatch: {(event: Event) in
            capturedEvent = event
        }, config: Self.testConfig)

        XCTAssertEqual(MediaConstants.Media.EVENT_SOURCE_TRACKER_REQUEST, capturedEvent?.source)
        XCTAssertEqual(MediaConstants.Media.EVENT_TYPE, capturedEvent?.type)

        let data = capturedEvent?.data
        XCTAssertFalse((data?[MediaConstants.Tracker.ID] as? String ?? "").isEmpty)

        let actualParam = data?[MediaConstants.Tracker.EVENT_PARAM] as? [String: Any] ?? [:]
        XCTAssertTrue(isEqual(map1: actualParam, map2: Self.testConfig))
    }

    // ==========================================================================
    // Event extension for Media
    // ==========================================================================

    func testEventExtension_TrackerIdAndConfig() {
        var capturedEvent: Event?
        _ = MediaPublicTracker(dispatch: {(event: Event) in
            capturedEvent = event
        }, config: Self.testConfig)

        XCTAssertEqual(MediaConstants.Media.EVENT_SOURCE_TRACKER_REQUEST, capturedEvent?.source)
        XCTAssertEqual(MediaConstants.Media.EVENT_TYPE, capturedEvent?.type)

        let trackerId = capturedEvent?.trackerId
        XCTAssertFalse((trackerId ?? "").isEmpty)

        let trackerConfig = capturedEvent?.trackerConfig
        XCTAssertTrue(isEqual(map1: trackerConfig, map2: Self.testConfig))
    }

    func testEventExtension_MissingTrackerIdAndConfig() {
        let event = Event(name: "newEvent", type: EventType.custom, source: EventSource.none, data: nil)

        let trackerId = event.trackerId
        XCTAssertNil(trackerId)

        let trackerConfig = event.trackerConfig
        XCTAssertNil(trackerConfig)
    }

    // ==========================================================================
    // trackAPIs
    // ==========================================================================
    func test_trackSessionStart() {
        let tracker = MediaEventGenerator()
        tracker.trackSessionStart(info: Self.validMediaInfo)

        assertTrackEvent(event: tracker.dispatchedEvent, expectedEventName: MediaConstants.EventName.SESSION_START, expectedParam: Self.validMediaInfo)
    }

    func test_trackSessionStartWithMetadata() {
        let tracker = MediaEventGenerator()
        tracker.trackSessionStart(info: Self.validMediaInfo, metadata: Self.metadata)

        assertTrackEvent(event: tracker.dispatchedEvent, expectedEventName: MediaConstants.EventName.SESSION_START, expectedParam: Self.validMediaInfo, expectedMetadata: Self.metadata)
    }

    func test_trackComplete() {
        let tracker = MediaEventGenerator()
        tracker.setTimeStamp(value: 100)
        tracker.trackComplete()

        assertTrackEvent(event: tracker.dispatchedEvent, expectedEventName: MediaConstants.EventName.COMPLETE, expectedTimestamp: 100)
    }

    func test_trackSessionEnd() {
        let tracker = MediaEventGenerator()
        tracker.setTimeStamp(value: 100)
        tracker.trackSessionEnd()

        assertTrackEvent(event: tracker.dispatchedEvent, expectedEventName: MediaConstants.EventName.SESSION_END, expectedTimestamp: 100)
    }

    func test_trackPlay() {
        let tracker = MediaEventGenerator()
        tracker.trackPlay()

        assertTrackEvent(event: tracker.dispatchedEvent, expectedEventName: MediaConstants.EventName.PLAY )
    }

    func test_trackPause() {
        let tracker = MediaEventGenerator()
        tracker.trackPause()

        assertTrackEvent(event: tracker.dispatchedEvent, expectedEventName: MediaConstants.EventName.PAUSE )
    }

    func test_trackError() {
        let tracker = MediaEventGenerator()
        tracker.trackError(errorId: "testError")

        assertTrackEvent(event: tracker.dispatchedEvent, expectedEventName: MediaConstants.EventName.ERROR, expectedParam: [
            MediaConstants.ErrorInfo.ID: "testError"
        ])
    }

    func test_updateCurrentPlayhead() {
        let tracker = MediaEventGenerator()
        tracker.updateCurrentPlayhead(time: 1.23)

        assertTrackEvent(event: tracker.dispatchedEvent, expectedEventName: MediaConstants.EventName.PLAYHEAD_UPDATE, expectedParam: [
            MediaConstants.Tracker.PLAYHEAD: 1.23
        ])
    }

    func test_updateQoEObject() {
        let tracker = MediaEventGenerator()
        tracker.updateQoEObject(qoe: Self.validQoeInfo)
        assertTrackEvent(event: tracker.dispatchedEvent, expectedEventName: MediaConstants.EventName.QOE_UPDATE, expectedParam: Self.validQoeInfo)
    }

    func test_trackAdBreak() {
        let tracker = MediaEventGenerator()

        tracker.trackEvent(event: MediaEvent.AdBreakStart, info: Self.validAdBreakInfo, metadata: Self.metadata)
        assertTrackEvent(event: tracker.dispatchedEvent, expectedEventName: MediaConstants.EventName.ADBREAK_START, expectedParam: Self.validAdBreakInfo, expectedMetadata: Self.metadata)

        tracker.trackEvent(event: MediaEvent.AdBreakComplete)
        assertTrackEvent(event: tracker.dispatchedEvent, expectedEventName: MediaConstants.EventName.ADBREAK_COMPLETE)
    }

    func test_trackAd() {
        let tracker = MediaEventGenerator()

        tracker.trackEvent(event: MediaEvent.AdStart, info: Self.validAdInfo, metadata: Self.metadata)
        assertTrackEvent(event: tracker.dispatchedEvent, expectedEventName: MediaConstants.EventName.AD_START, expectedParam: Self.validAdInfo, expectedMetadata: Self.metadata)

        tracker.trackEvent(event: MediaEvent.AdComplete)
        assertTrackEvent(event: tracker.dispatchedEvent, expectedEventName: MediaConstants.EventName.AD_COMPLETE)

        tracker.trackEvent(event: MediaEvent.AdSkip)
        assertTrackEvent(event: tracker.dispatchedEvent, expectedEventName: MediaConstants.EventName.AD_SKIP)
    }

    func test_trackChapter() {
        let tracker = MediaEventGenerator()

        tracker.trackEvent(event: MediaEvent.ChapterStart, info: Self.validChapterInfo, metadata: Self.metadata)
        assertTrackEvent(event: tracker.dispatchedEvent, expectedEventName: MediaConstants.EventName.CHAPTER_START, expectedParam: Self.validChapterInfo, expectedMetadata: Self.metadata)

        tracker.trackEvent(event: MediaEvent.ChapterComplete)
        assertTrackEvent(event: tracker.dispatchedEvent, expectedEventName: MediaConstants.EventName.CHAPTER_COMPLETE)

        tracker.trackEvent(event: MediaEvent.ChapterSkip)
        assertTrackEvent(event: tracker.dispatchedEvent, expectedEventName: MediaConstants.EventName.CHAPTER_SKIP)
    }

    func test_trackState() {
        let tracker = MediaEventGenerator()
        tracker.trackEvent(event: MediaEvent.StateStart, info: Self.validStateInfo)
        assertTrackEvent(event: tracker.dispatchedEvent, expectedEventName: MediaConstants.EventName.STATE_START, expectedParam: Self.validStateInfo)

        tracker.trackEvent(event: MediaEvent.StateEnd, info: Self.validStateInfo)
        assertTrackEvent(event: tracker.dispatchedEvent, expectedEventName: MediaConstants.EventName.STATE_END, expectedParam: Self.validStateInfo)
    }

    func test_trackEvents() {
        let tracker = MediaEventGenerator()

        tracker.trackEvent(event: MediaEvent.BufferStart)
        assertTrackEvent(event: tracker.dispatchedEvent, expectedEventName: MediaConstants.EventName.BUFFER_START)

        tracker.trackEvent(event: MediaEvent.BufferComplete)
        assertTrackEvent(event: tracker.dispatchedEvent, expectedEventName: MediaConstants.EventName.BUFFER_COMPLETE)

        tracker.trackEvent(event: MediaEvent.SeekStart)
        assertTrackEvent(event: tracker.dispatchedEvent, expectedEventName: MediaConstants.EventName.SEEK_START)

        tracker.trackEvent(event: MediaEvent.SeekComplete)
        assertTrackEvent(event: tracker.dispatchedEvent, expectedEventName: MediaConstants.EventName.SEEK_COMPLETE)

        tracker.trackEvent(event: MediaEvent.BitrateChange)
        assertTrackEvent(event: tracker.dispatchedEvent, expectedEventName: MediaConstants.EventName.BITRATE_CHANGE)
    }
}
