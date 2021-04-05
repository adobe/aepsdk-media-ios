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

class MediaOfflineTrackingTests: MediaFunctionalTestBase {

    static let config: [String: Any] = [MediaConstants.TrackerConfig.DOWNLOADED_CONTENT: true]
    var tracker: MediaEventGenerator!
    var fakeMediaHitProcessor: FakeMediaHitProcessor!

    override func setUp() {
        super.setupBase()
        fakeMediaHitProcessor = FakeMediaHitProcessor()
        tracker = MediaEventGenerator(config: Self.config, dispatch: mockRuntime.dispatch(event:))
        waitForProcessing(interval: 1)
    }

    func testdownloadedContentSession() {
        // setup
        dispatchDefaultConfigAndSharedStates()
        let mediaInfo: [String: Any] = [
            MediaConstants.MediaInfo.ID: "videoId",
            MediaConstants.MediaInfo.NAME: "video",
            MediaConstants.MediaInfo.LENGTH: 30,
            MediaConstants.MediaInfo.STREAM_TYPE: "vod",
            MediaConstants.MediaInfo.MEDIA_TYPE: "video",
            MediaConstants.MediaInfo.RESUMED: true,
            MediaConstants.MediaInfo.PREROLL_TRACKING_WAITING_TIME: 2000.0,
            MediaConstants.MediaInfo.GRANULAR_AD_TRACKING: true
        ]
        let metadata = ["SampleContextData": "SampleValue", "a.media.show": "show"]
        let qoeInfo = [MediaConstants.QoEInfo.BITRATE: 1000, MediaConstants.QoEInfo.DROPPED_FRAMES: 6, MediaConstants.QoEInfo.FPS: 14, MediaConstants.QoEInfo.STARTUP_TIME: 2]
        let qoeInfo2 = [MediaConstants.QoEInfo.BITRATE: 2000, MediaConstants.QoEInfo.DROPPED_FRAMES: 33, MediaConstants.QoEInfo.FPS: 24, MediaConstants.QoEInfo.STARTUP_TIME: 4]
        
        let trackerId = tracker.getTrackerId()
        if let internalTracker = media.trackers[trackerId] as? MediaEventTracker {
            internalTracker.hitProcessor = fakeMediaHitProcessor
        }
        // test
        tracker.trackSessionStart(info: mediaInfo, metadata: metadata)
        let sessionStartTs = Date().getUnixTimeInSeconds()
        tracker.updateQoEObject(qoe: qoeInfo)
        tracker.trackPlay()
        tracker.updateCurrentPlayhead(time: 1)
        sleep(2)
        tracker.updateCurrentPlayhead(time: 5)
        tracker.updateQoEObject(qoe: qoeInfo2)
        tracker.trackPause()
		sleep(1)
        tracker.trackPlay()
        tracker.updateCurrentPlayhead(time: 10)
        tracker.trackComplete()
        // verify
        XCTAssertEqual(1, fakeMediaHitProcessor.getHitCountFromActiveSession())
    }
}
