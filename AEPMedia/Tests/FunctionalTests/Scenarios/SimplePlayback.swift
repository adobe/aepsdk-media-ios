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
class SimplePlayback: MediaFunctionalTestBase {
    private typealias EventType = MediaConstants.MediaCollection.EventType
    private typealias Media = MediaConstants.MediaCollection.Media
    var fakeMediaService: FakeMediaHitProcessor!
    var mediaEventTracker: MediaEventTracking!
    var mediaTracker: MediaEventGenerator!
    var mediaInfo = MediaInfo(id: "mediaID", name: "mediaName", streamType: "aod", mediaType: MediaType.Audio, length: 30.0, prerollWaitingTime: 0)!
    var mediaMetadata = ["media.show": "sampleshow", "key1": "value1"]
    let semaphore = DispatchSemaphore(value: 0)

    typealias CollectionEventType = MediaConstants.MediaCollection.EventType
    override func setUp() {
        super.setupBase()
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
        var startTs: Int64 = mediaTracker.getTimeStamp()
        var playhead: Double = mediaTracker.getCurrentPlayhead()
        for _ in 1...time/1000 {
            mediaTracker.incrementTimeStamp(value: 1000)
            mediaTracker.incrementCurrentPlayhead(time: updatePlayhead ? 1 : 0)
        }
    }

    func checkHits(expectedHits: [MediaHit]) {
        let actualHitsCount = fakeMediaService.getHitCountFromActiveSession()
        XCTAssertEqual(expectedHits.count, actualHitsCount, "No of expected hits not equal to actual hits")

        for i in 0...expectedHits.count-1 {
            XCTAssertEqual(expectedHits[i], fakeMediaService.getHitFromActiveSession(index: i))
        }
    }

    // tests
    func testTrackSimplePlayBack_RealTimeTracker() {
        //test
        mediaTracker.trackSessionStart(info: mediaInfo.toMap(), metadata: mediaMetadata)
        mediaTracker.trackPlay()
        waitFor(time: 5000, updatePlayhead: true)
        mediaTracker.trackPause()
        waitFor(time: 15000, updatePlayhead: false)
        mediaTracker.trackPlay()
        waitFor(time: 15000, updatePlayhead: true)
        mediaTracker.trackComplete()

        let sessionStartParams: [String: Any]  = [
            MediaConstants.MediaCollection.Media.ID: "mediaID",
            MediaConstants.MediaCollection.Media.NAME: "mediaName",
            MediaConstants.MediaCollection.Media.LENGTH: 30.0,
            MediaConstants.MediaCollection.Media.CONTENT_TYPE: "aod",
            MediaConstants.MediaCollection.Media.STREAM_TYPE: "audio",
            MediaConstants.MediaCollection.Media.RESUME: false,

            "media.downloaded": false,
        ]

        let expectedHits: [MediaHit] = [
            MediaHit(eventType: CollectionEventType.SESSION_START, playhead: 0, ts: 0, params: sessionStartParams, customMetadata: mediaMetadata),
            MediaHit(eventType: CollectionEventType.PLAY, playhead: 0, ts: 0),
            MediaHit(eventType: CollectionEventType.PLAY, playhead: 1, ts: 1000),
            MediaHit(eventType: CollectionEventType.PAUSE_START, playhead: 5, ts: 5000),
            MediaHit(eventType: CollectionEventType.PING, playhead: 5, ts: 15000),
            MediaHit(eventType: CollectionEventType.PLAY, playhead: 5, ts: 20000),
            MediaHit(eventType: CollectionEventType.PING, playhead: 15, ts: 30000),
            MediaHit(eventType: CollectionEventType.SESSION_COMPLETE, playhead: 20, ts: 35000)

        ]
        //verify
        checkHits(expectedHits: expectedHits)
    }

}
