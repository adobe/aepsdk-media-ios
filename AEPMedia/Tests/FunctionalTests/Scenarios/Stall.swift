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

class Stall: XCTestCase {
    private typealias EventType = MediaConstants.MediaCollection.EventType
    private typealias Media = MediaConstants.MediaCollection.Media

    var fakeMediaService: FakeMediaHitProcessor!
    var mediaEventTracker: MediaEventTracking!
    var mediaTracker: MediaEventGenerator!

    let mediaInfoWithDefaultPreroll = MediaInfo(id: "mediaID", name: "mediaName", streamType: "vod", mediaType: MediaType.Video, length: 30.0)!
    let mediaMetadata = ["media.show": "sampleshow", "key1": "value1", "key2": "мểŧẳđαţả"]

    let semaphore = DispatchSemaphore(value: 0)

    override func setUp() {
        fakeMediaService = FakeMediaHitProcessor()
        createTracker()
    }

    func createTracker(downloaded: Bool = false) {
        let config = [MediaConstants.TrackerConfig.DOWNLOADED_CONTENT: downloaded]
        mediaEventTracker = MediaEventTracker(hitProcessor: fakeMediaService, config: config)
        mediaTracker = MediaEventGenerator(config: config)
        mediaTracker.connectCoreTracker(tracker: mediaEventTracker)
        mediaTracker.setTimeStamp(value: 0)
    }

    func waitFor(time: Int, updatePlayhead: Bool) {
        for _ in 1...time/1000 {
            mediaTracker.incrementTimeStamp(value: 1000)
            mediaTracker.incrementCurrentPlayhead(time: updatePlayhead ? 1 : 0)
        }
    }

    func checkHits(expectedHits: [MediaHit]) {
        let actualHitsCount = fakeMediaService.getHitCountFromActiveSession()
        XCTAssertEqual(expectedHits.count, actualHitsCount, "No of expected hits (\(expectedHits.count)) not equal to actual hits (\(actualHitsCount))")

        for i in 0...expectedHits.count-1 {
            XCTAssertEqual(expectedHits[i], fakeMediaService.getHitFromActiveSession(index: i))
        }
    }

    // tests
    func testStall_RealTimeTracker() {

        // test
        mediaTracker.trackSessionStart(info: mediaInfoWithDefaultPreroll.toMap(), metadata: mediaMetadata)
        mediaTracker.trackPlay()
        waitFor(time: 50000, updatePlayhead: false)
        mediaTracker.trackComplete()

        let expectedSessionStartParams: [String: Any]  = [
            Media.ID: "mediaID",
            Media.NAME: "mediaName",
            Media.LENGTH: 30.0,
            Media.CONTENT_TYPE: "vod",
            Media.STREAM_TYPE: "video",
            Media.RESUME: false,
            Media.DOWNLOADED: false,
        ]

        let expectedHits: [MediaHit] = [
            MediaHit(eventType: EventType.SESSION_START, playhead: 0, ts: 0, params: expectedSessionStartParams, customMetadata: mediaMetadata),
            MediaHit(eventType: EventType.PLAY, playhead: 0, ts: 0),
            MediaHit(eventType: EventType.PLAY, playhead: 0, ts: 1000),
            MediaHit(eventType: EventType.PING, playhead: 0, ts: 11000),
            MediaHit(eventType: EventType.PING, playhead: 0, ts: 21000),
            MediaHit(eventType: EventType.PING, playhead: 0, ts: 31000),
            MediaHit(eventType: EventType.PING, playhead: 0, ts: 41000),
            MediaHit(eventType: EventType.SESSION_COMPLETE, playhead: 0, ts: 50000)
        ]

        // verify
        checkHits(expectedHits: expectedHits)
    }

    func testStall_DownloadTracker() {
        // setup
        createTracker(downloaded: true)

        // test
        mediaTracker.trackSessionStart(info: mediaInfoWithDefaultPreroll.toMap(), metadata: mediaMetadata)
        mediaTracker.trackPlay()
        waitFor(time: 80000, updatePlayhead: false)
        mediaTracker.trackComplete()

        let expectedSessionStartParams: [String: Any]  = [
            Media.ID: "mediaID",
            Media.NAME: "mediaName",
            Media.LENGTH: 30.0,
            Media.CONTENT_TYPE: "vod",
            Media.STREAM_TYPE: "video",
            Media.RESUME: false,
            Media.DOWNLOADED: true,
        ]

        let expectedHits: [MediaHit] = [
            MediaHit(eventType: EventType.SESSION_START, playhead: 0, ts: 0, params: expectedSessionStartParams, customMetadata: mediaMetadata),
            MediaHit(eventType: EventType.PLAY, playhead: 0, ts: 0),
            MediaHit(eventType: EventType.PLAY, playhead: 0, ts: 1000),
            MediaHit(eventType: EventType.PING, playhead: 0, ts: 51000),
            MediaHit(eventType: EventType.SESSION_COMPLETE, playhead: 0, ts: 80000)
        ]

        // verify
        checkHits(expectedHits: expectedHits)
    }
}

