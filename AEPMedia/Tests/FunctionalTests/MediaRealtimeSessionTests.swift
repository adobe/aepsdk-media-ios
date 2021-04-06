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

    override func setUp() {
        super.setupBase()
        tracker = MediaEventGenerator(config: Self.config, dispatch: mockRuntime.dispatch(event:))
        waitForProcessing(interval: 1)
    }

    func testRealtimeContentSession() {
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
        let timestamp = Date().timeIntervalSince1970
        tracker.setTimeStamp(value: timestamp)
        tracker.trackSessionStart(info: mediaInfo, metadata: metadata)
        tracker.updateQoEObject(qoe: qoeInfo)
        tracker.updateCurrentPlayhead(time: 1)
        tracker.trackPlay()
        usleep(2000)
        tracker.updateCurrentPlayhead(time: 5)
        tracker.updateQoEObject(qoe: qoeInfo2)
        tracker.trackPause()
        usleep(11000)
        tracker.trackPlay()
        tracker.updateCurrentPlayhead(time: 10)
        tracker.trackComplete()
        waitForProcessing()
        // verify
        XCTAssertEqual(mockNetworkService?.calledNetworkRequests.count, 5)
        let sessionStart = mockNetworkService?.calledNetworkRequests[0]
        let sessionStartPayload = convertToDictionary(jsonString: sessionStart?.connectPayload)
        verifyEvent(eventName: "sessionStart", payload: sessionStartPayload, expectedInfo: mediaInfo, expectedMetadata: metadata, playhead: 0, ts: timestamp)
        let play = mockNetworkService?.calledNetworkRequests[1]
        let playPayload = convertToDictionary(jsonString: play?.connectPayload)
        verifyEvent(eventName: "play", payload: playPayload, expectedInfo: mediaInfo, expectedMetadata: metadata, expectedQoe: qoeInfo, playhead: 1, ts: timestamp)
        let pause = mockNetworkService?.calledNetworkRequests[2]
        let pausePayload = convertToDictionary(jsonString: pause?.connectPayload)
        verifyEvent(eventName: "pauseStart", payload: pausePayload, expectedInfo: mediaInfo, expectedMetadata: metadata, expectedQoe: qoeInfo2, playhead: 5, ts: timestamp)
        let play2 = mockNetworkService?.calledNetworkRequests[3]
        let play2Payload = convertToDictionary(jsonString:play2?.connectPayload)
        verifyEvent(eventName: "play", payload: play2Payload, expectedInfo: mediaInfo, expectedMetadata: metadata, playhead: 5, ts: timestamp)
        let sessionComplete = mockNetworkService?.calledNetworkRequests[4]
        let sessionCompletePayload = convertToDictionary(jsonString:sessionComplete?.connectPayload)
        verifyEvent(eventName: "sessionComplete", payload: sessionCompletePayload, expectedInfo: mediaInfo, expectedMetadata: metadata, playhead: 10, ts: timestamp)
    }
}
