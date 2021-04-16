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

class MediaRealtimeTrackingTests: MediaFunctionalTestBase {

    static let config: [String: Any] = [MediaConstants.TrackerConfig.DOWNLOADED_CONTENT: false]
    var tracker: MediaEventGenerator!
    let semaphore = DispatchSemaphore(value: 0)

    override func setUp() {
        super.setupBase()
        tracker = MediaEventGenerator(config: Self.config, dispatch: mockRuntime.dispatch(event:))
    }

    func ignoretestRealtimeContentSession() {
        // setup
        dispatchDefaultConfigAndSharedStates()
        guard let mediaInfo = Media.createMediaObjectWith(name: "video", id: "videoId", length: 30.0, streamType: "vod", mediaType: MediaType.Video) else {
            XCTFail("failed to create media info")
            return
        }
        let metadata = ["SampleContextData": "SampleValue", "a.media.show": "show"]
        guard let qoeInfo = Media.createQoEObjectWith(bitrate: 1000, startupTime: 2, fps: 14, droppedFrames: 6), let qoeInfo2 = Media.createQoEObjectWith(bitrate: 2000, startupTime: 4, fps: 24, droppedFrames: 33) else {
            XCTFail("failed to create qoe info objects")
            return
        }

        // test
        let sessionStartTs = Int64(0)
        tracker.setTimeStamp(value: sessionStartTs)
        tracker.trackSessionStart(info: mediaInfo, metadata: metadata)
        tracker.updateQoEObject(qoe: qoeInfo)
        tracker.trackPlay()
        tracker.updateCurrentPlayhead(time: 1)
        waitFor(2, updatePlayhead: true, tracker: tracker, semaphore: semaphore)
        semaphore.wait()
        tracker.updateCurrentPlayhead(time: 5)
        tracker.updateQoEObject(qoe: qoeInfo2)
        tracker.trackPause()
        waitFor(11, updatePlayhead: false, tracker: tracker, semaphore: semaphore)
        semaphore.wait()
        tracker.trackPlay()
        tracker.updateCurrentPlayhead(time: 10)
        tracker.trackComplete()
        waitForProcessing()
        // verify
        XCTAssertEqual(mockNetworkService?.calledNetworkRequests.count, 7)
        let sessionStart = mockNetworkService?.calledNetworkRequests[0]
        let sessionStartPayload = convertToDictionary(jsonString: sessionStart?.connectPayload)
        verifyEvent(eventName: "sessionStart", payload: sessionStartPayload, expectedInfo: mediaInfo, expectedMetadata: metadata, playhead: 0, ts: sessionStartTs, isDownloadedSession: false)
        let play = mockNetworkService?.calledNetworkRequests[1]
        let playPayload = convertToDictionary(jsonString: play?.connectPayload)
        verifyEvent(eventName: "play", payload: playPayload, expectedInfo: mediaInfo, expectedMetadata: metadata, expectedQoe: qoeInfo, playhead: 0, ts: sessionStartTs, isDownloadedSession: true)
        let contentStart = mockNetworkService?.calledNetworkRequests[2]
        let contentStartPayload = convertToDictionary(jsonString: contentStart?.connectPayload)
        verifyEvent(eventName: "play", payload: contentStartPayload, expectedInfo: mediaInfo, expectedMetadata: metadata, playhead: 3, ts: sessionStartTs + 3, isDownloadedSession: true)
        let pauseStart = mockNetworkService?.calledNetworkRequests[3]
        let pauseStartPayload = convertToDictionary(jsonString: pauseStart?.connectPayload)
        verifyEvent(eventName: "pauseStart", payload: pauseStartPayload, expectedInfo: mediaInfo, expectedMetadata: metadata, expectedQoe: qoeInfo2, playhead: 5, ts: sessionStartTs + 4, isDownloadedSession: true)
        let ping = mockNetworkService?.calledNetworkRequests[4]
        let pingPayload = convertToDictionary(jsonString: ping?.connectPayload)
        verifyEvent(eventName: "ping", payload: pingPayload, expectedInfo: mediaInfo, expectedMetadata: metadata, playhead: 5, ts: sessionStartTs + 14, isDownloadedSession: false)
        let play2 = mockNetworkService?.calledNetworkRequests[5]
        let play2Payload = convertToDictionary(jsonString: play2?.connectPayload)
        verifyEvent(eventName: "play", payload: play2Payload, expectedInfo: mediaInfo, expectedMetadata: metadata, playhead: 5, ts: sessionStartTs + 15, isDownloadedSession: false)
        let sessionComplete = mockNetworkService?.calledNetworkRequests[6]
        let sessionCompletePayload = convertToDictionary(jsonString: sessionComplete?.connectPayload)
        verifyEvent(eventName: "sessionComplete", payload: sessionCompletePayload, expectedInfo: mediaInfo, expectedMetadata: metadata, playhead: 10, ts: sessionStartTs + 15, isDownloadedSession: false)
    }

    func ignoretestRealtimeContentSessionWhenPrivacyOptedOut() {
        // setup
        dispatchDefaultConfigAndSharedStates(configData: [MediaConstants.Configuration.GLOBAL_CONFIG_PRIVACY: "optedout"])
        guard let mediaInfo = Media.createMediaObjectWith(name: "video", id: "videoId", length: 30.0, streamType: "vod", mediaType: MediaType.Video) else {
            XCTFail("failed to create media info")
            return
        }
        let metadata = ["SampleContextData": "SampleValue", "a.media.show": "show"]

        // test
        let sessionStartTs = Int64(0)
        tracker.setTimeStamp(value: sessionStartTs)
        tracker.trackSessionStart(info: mediaInfo, metadata: metadata)
        tracker.trackComplete()
        waitForProcessing()
        // verify
        XCTAssertEqual(mockNetworkService?.calledNetworkRequests.count, 0)
    }

    func ignoretestRealtimeContentSessionWhenPrivacyUnknown() {
        // setup
        dispatchDefaultConfigAndSharedStates(configData: [MediaConstants.Configuration.GLOBAL_CONFIG_PRIVACY: "unknown"])
        guard let mediaInfo = Media.createMediaObjectWith(name: "video", id: "videoId", length: 30.0, streamType: "vod", mediaType: MediaType.Video) else {
            XCTFail("failed to create media info")
            return
        }
        let metadata = ["SampleContextData": "SampleValue", "a.media.show": "show"]

        // test
        let sessionStartTs = Int64(0)
        tracker.setTimeStamp(value: sessionStartTs)
        tracker.trackSessionStart(info: mediaInfo, metadata: metadata)
        tracker.trackComplete()
        waitForProcessing()
        // verify
        XCTAssertEqual(mockNetworkService?.calledNetworkRequests.count, 0)
    }

    func ignoretestRealtimeContentSessionRequestRetriedWhenInitialNetworkRequestReceivedConnectionError() {
        // setup
        dispatchDefaultConfigAndSharedStates()
        guard let mediaInfo = Media.createMediaObjectWith(name: "video", id: "videoId", length: 30.0, streamType: "vod", mediaType: MediaType.Video) else {
            XCTFail("failed to create media info")
            return
        }
        let metadata = ["SampleContextData": "SampleValue", "a.media.show": "show"]
        // setup mock network to return a connection error
        mockNetworkService?.shouldReturnConnectionError = true

        // test
        let sessionStartTs = Int64(0)
        tracker.setTimeStamp(value: sessionStartTs)
        tracker.trackSessionStart(info: mediaInfo, metadata: metadata)
        waitForProcessing()
        // setup mock network to return a valid connection and wait 33 seconds for retried request
        mockNetworkService?.shouldReturnConnectionError = false
        sleep(33)
        // verify two session start network requests due to initial session start request getting an error response and the request being retried
        XCTAssertEqual(mockNetworkService?.calledNetworkRequests.count, 2)
        let sessionStart = mockNetworkService?.calledNetworkRequests[1]
        let sessionStartPayload = convertToDictionary(jsonString: sessionStart?.connectPayload)
        verifyEvent(eventName: "sessionStart", payload: sessionStartPayload, expectedInfo: mediaInfo, expectedMetadata: metadata, playhead: 0, ts: sessionStartTs, isDownloadedSession: false)
    }
}
