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

class MediaExtensionTests: MediaTestBase {
    
    override func setUp() {
        super.setupBase()
    }

    override func tearDown() {

    }
    
    // MARK: readyForEvent tests
    func testReadyForEventHappyPath() {
        // setup
        dispatchDefaultConfigAndSharedStates()
        let eventData: [String: Any] = [
            MediaConstants.Tracker.ID: "testTracker",
            MediaConstants.Tracker.EVENT_PARAM: ["test":"value"]
        ]
        let createTrackerEvent = Event(name: MediaConstants.Media.EVENT_NAME_CREATE_TRACKER, type: MediaConstants.Media.EVENT_TYPE, source: MediaConstants.Media.EVENT_SOURCE_TRACKER_REQUEST, data: eventData)
        // test
        mockRuntime.simulateComingEvent(event: createTrackerEvent)
        waitForProcessing()
        let readyForEvent = media.readyForEvent(createTrackerEvent)
        // verify
        XCTAssertTrue(readyForEvent)
    }
    
    func testReadyForEventWhenConfigAndIdentitySharedStateNotReady() {
        // setup
        let eventData: [String: Any] = [
            MediaConstants.Tracker.ID: "testTracker",
            MediaConstants.Tracker.EVENT_PARAM: ["test":"value"]
        ]
        let createTrackerEvent = Event(name: MediaConstants.Media.EVENT_NAME_CREATE_TRACKER, type: MediaConstants.Media.EVENT_TYPE, source: MediaConstants.Media.EVENT_SOURCE_TRACKER_REQUEST, data: eventData)
        // test
        mockRuntime.simulateComingEvent(event: createTrackerEvent)
        waitForProcessing()
        let readyForEvent = media.readyForEvent(createTrackerEvent)
        // verify
        XCTAssertFalse(readyForEvent)
    }
    
    // MARK: handleMediaTrackerRequest tests
    func testCreateTrackerHappyPath() {
        // setup
        dispatchDefaultConfigAndSharedStates()
        let eventData: [String: Any] = [
            MediaConstants.Tracker.ID: "testTracker",
            MediaConstants.Tracker.EVENT_PARAM: ["test":"value"]
        ]
        let createTrackerEvent = Event(name: MediaConstants.Media.EVENT_NAME_CREATE_TRACKER, type: MediaConstants.Media.EVENT_TYPE, source: MediaConstants.Media.EVENT_SOURCE_TRACKER_REQUEST, data: eventData)
        // test
        mockRuntime.simulateComingEvent(event: createTrackerEvent)
        waitForProcessing()
        // verify
        XCTAssertEqual(media.sessionIdToTrackerIdMapping.count, 1)
        let sessionId = media.sessionIdToTrackerIdMapping["testTracker"]
        XCTAssertEqual(sessionId?.count, 36)
    }
    
    func testCreateTrackerWithEmptyConfig() {
        // setup
        dispatchDefaultConfigAndSharedStates()
        let eventData: [String: Any] = [
            MediaConstants.Tracker.ID: "testTracker",
            MediaConstants.Tracker.EVENT_PARAM: [:]
        ]
        let createTrackerEvent = Event(name: MediaConstants.Media.EVENT_NAME_CREATE_TRACKER, type: MediaConstants.Media.EVENT_TYPE, source: MediaConstants.Media.EVENT_SOURCE_TRACKER_REQUEST, data: eventData)
        // test
        mockRuntime.simulateComingEvent(event: createTrackerEvent)
        waitForProcessing()
        // verify
        XCTAssertEqual(media.sessionIdToTrackerIdMapping.count, 1)
        let sessionId = media.sessionIdToTrackerIdMapping["testTracker"]
        XCTAssertEqual(sessionId?.count, 36)
    }
    
    func testCreateTrackerWithInvalidTrackerId() {
        // setup
        dispatchDefaultConfigAndSharedStates()
        let eventData: [String: Any] = [
            MediaConstants.Tracker.ID: "",
            MediaConstants.Tracker.EVENT_PARAM: [:]
        ]
        let createTrackerEvent = Event(name: MediaConstants.Media.EVENT_NAME_CREATE_TRACKER, type: MediaConstants.Media.EVENT_TYPE, source: MediaConstants.Media.EVENT_SOURCE_TRACKER_REQUEST, data: eventData)
        // test
        mockRuntime.simulateComingEvent(event: createTrackerEvent)
        waitForProcessing()
        // verify
        XCTAssertEqual(media.sessionIdToTrackerIdMapping.count, 0)
    }
    
    func testCreateTrackerWithInvalidEvent() {
        // setup
        dispatchDefaultConfigAndSharedStates()
        let createTrackerEvent = Event(name: MediaConstants.Media.EVENT_NAME_CREATE_TRACKER, type: MediaConstants.Media.EVENT_TYPE, source: MediaConstants.Media.EVENT_SOURCE_TRACKER_REQUEST, data: nil)
        // test
        mockRuntime.simulateComingEvent(event: createTrackerEvent)
        waitForProcessing()
        // verify
        XCTAssertEqual(media.sessionIdToTrackerIdMapping.count, 0)
    }
    
    func testCreateMultipleTrackers() {
        // setup
        dispatchDefaultConfigAndSharedStates()
        let eventData: [String: Any] = [
            MediaConstants.Tracker.ID: "testTracker1",
            MediaConstants.Tracker.EVENT_PARAM: ["test":"value"]
        ]
        let createTrackerEvent = Event(name: MediaConstants.Media.EVENT_NAME_CREATE_TRACKER, type: MediaConstants.Media.EVENT_TYPE, source: MediaConstants.Media.EVENT_SOURCE_TRACKER_REQUEST, data: eventData)
        let eventData2: [String: Any] = [
            MediaConstants.Tracker.ID: "testTracker2",
            MediaConstants.Tracker.EVENT_PARAM: ["test":"value"]
        ]
        let createTrackerEvent2 = Event(name: MediaConstants.Media.EVENT_NAME_CREATE_TRACKER, type: MediaConstants.Media.EVENT_TYPE, source: MediaConstants.Media.EVENT_SOURCE_TRACKER_REQUEST, data: eventData2)
        // test
        mockRuntime.simulateComingEvent(event: createTrackerEvent)
        waitForProcessing()
        mockRuntime.simulateComingEvent(event: createTrackerEvent2)
        waitForProcessing()
        // verify
        XCTAssertEqual(media.sessionIdToTrackerIdMapping.count, 2)
        let sessionId = media.sessionIdToTrackerIdMapping["testTracker1"]
        let sessionId2 = media.sessionIdToTrackerIdMapping["testTracker2"]
        XCTAssertEqual(sessionId?.count, 36)
        XCTAssertEqual(sessionId2?.count, 36)
    }
    
    func testCreateTrackerThenPrivacyOptedOut() {
        // setup
        dispatchDefaultConfigAndSharedStates()
        let eventData: [String: Any] = [
            MediaConstants.Tracker.ID: "testTracker",
            MediaConstants.Tracker.EVENT_PARAM: ["test":"value"]
        ]
        let createTrackerEvent = Event(name: MediaConstants.Media.EVENT_NAME_CREATE_TRACKER, type: MediaConstants.Media.EVENT_TYPE, source: MediaConstants.Media.EVENT_SOURCE_TRACKER_REQUEST, data: eventData)
        // test
        mockRuntime.simulateComingEvent(event: createTrackerEvent)
        waitForProcessing()
        // verify
        XCTAssertEqual(media.sessionIdToTrackerIdMapping.count, 1)
        let sessionId = media.sessionIdToTrackerIdMapping["testTracker"]
        XCTAssertEqual(sessionId?.count, 36)
        // set privacy to opt out
        dispatchDefaultConfigAndSharedStates(configData: ["global.privacy" : "optedout"])
        waitForProcessing()
        // verify session id to tracker id mapping is cleared
        XCTAssertEqual(media.sessionIdToTrackerIdMapping.count, 0)
    }
    
    // MARK: handleMediaTrack tests
    func testHandleMediaTrackHappyPath() {
        // setup
        let sessionId = UUID().uuidString
        media.sessionIdToTrackerIdMapping["testTracker"] = sessionId
        dispatchDefaultConfigAndSharedStates()
        let eventData: [String: Any] = [
            MediaConstants.Tracker.ID: "testTracker",
            MediaConstants.Tracker.SESSION_ID : sessionId,
            MediaConstants.Tracker.EVENT_NAME : MediaConstants.EventName.PLAY,
            MediaConstants.Tracker.EVENT_INTERNAL : false
        ]
        let mediaTrackEvent = Event(name: MediaConstants.Media.EVENT_NAME_TRACK_MEDIA, type: MediaConstants.Media.EVENT_TYPE, source: MediaConstants.Media.EVENT_SOURCE_TRACK_MEDIA, data: eventData)
        // test
        mockRuntime.simulateComingEvent(event: mediaTrackEvent)
        waitForProcessing()
        // verify
        XCTAssertTrue(media.trackerCalled)
    }
    
    func testHandleMediaTrackNonMatchingTrackerId() {
        // setup
        let sessionId = UUID().uuidString
        media.sessionIdToTrackerIdMapping["testTracker"] = sessionId
        dispatchDefaultConfigAndSharedStates()
        let eventData: [String: Any] = [
            MediaConstants.Tracker.ID: "differentTrackerId",
            MediaConstants.Tracker.SESSION_ID : sessionId,
            MediaConstants.Tracker.EVENT_NAME : MediaConstants.EventName.PLAY,
            MediaConstants.Tracker.EVENT_INTERNAL : false
        ]
        let mediaTrackEvent = Event(name: MediaConstants.Media.EVENT_NAME_TRACK_MEDIA, type: MediaConstants.Media.EVENT_TYPE, source: MediaConstants.Media.EVENT_SOURCE_TRACK_MEDIA, data: eventData)
        // test
        mockRuntime.simulateComingEvent(event: mediaTrackEvent)
        waitForProcessing()
        // verify
        XCTAssertFalse(media.trackerCalled)
    }
    
    func testHandleMediaTrackEmptyTrackerId() {
        // setup
        let sessionId = UUID().uuidString
        media.sessionIdToTrackerIdMapping["testTracker"] = sessionId
        dispatchDefaultConfigAndSharedStates()
        let eventData: [String: Any] = [
            MediaConstants.Tracker.ID: "",
            MediaConstants.Tracker.SESSION_ID : sessionId,
            MediaConstants.Tracker.EVENT_NAME : MediaConstants.EventName.PLAY,
            MediaConstants.Tracker.EVENT_INTERNAL : false
        ]
        let mediaTrackEvent = Event(name: MediaConstants.Media.EVENT_NAME_TRACK_MEDIA, type: MediaConstants.Media.EVENT_TYPE, source: MediaConstants.Media.EVENT_SOURCE_TRACK_MEDIA, data: eventData)
        // test
        mockRuntime.simulateComingEvent(event: mediaTrackEvent)
        waitForProcessing()
        // verify
        XCTAssertFalse(media.trackerCalled)
    }
    
    func testHandleMediaTrackWithInvalidEvent() {
        // setup
        let sessionId = UUID().uuidString
        media.sessionIdToTrackerIdMapping["testTracker"] = sessionId
        dispatchDefaultConfigAndSharedStates()
        let mediaTrackEvent = Event(name: MediaConstants.Media.EVENT_NAME_TRACK_MEDIA, type: MediaConstants.Media.EVENT_TYPE, source: MediaConstants.Media.EVENT_SOURCE_TRACK_MEDIA, data: nil)
        // test
        mockRuntime.simulateComingEvent(event: mediaTrackEvent)
        waitForProcessing()
        // verify
        XCTAssertFalse(media.trackerCalled)
    }
}
