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
    var mediaTracker: MediaEventTracking!
    var mediaEventGenerator: MediaEventGenerator!
    var mediaInfo = MediaInfo(id: "mediaID", name: "mediaName", streamType: "aod", mediaType: MediaType.Audio, length: 30.0, prerollWaitingTime: 0)!
    var mediaMetadata = ["media.show": "sampleshow", "key1": "value1"]
    let semaphore = DispatchSemaphore(value: 0)

    override func setUp() {
        super.setupBase()
        fakeMediaService = FakeMediaHitProcessor()
    }

    func getExpectedSessionStartHit(info: MediaInfo, metadata: [String: String]? = nil, qoeData: [String: Any]? = nil, downloaded: Bool = false, ts: Int64 = 0, playhead: Double = 0) -> MediaHit {
        var expectedMediaInfo = MediaCollectionHelper.generateMediaParams(mediaInfo: info, metadata: metadata ?? [:])
        expectedMediaInfo[Media.DOWNLOADED] = downloaded
        return MediaHit(eventType: EventType.SESSION_START, playhead: playhead, ts: ts, params: expectedMediaInfo, customMetadata: metadata, qoeData: qoeData)
    }

    func getExpectedPlaybackHit(eventType: String, qoeData: [String: Any]? = nil, ts: Int64 = 0, playhead: Double = 0) -> MediaHit {
        return MediaHit(eventType: eventType, playhead: playhead, ts: ts, qoeData: qoeData)

    }

    func createTracker(downloaded: Bool = false) {
        let config = [MediaConstants.TrackerConfig.DOWNLOADED_CONTENT: downloaded]
        mediaTracker = MediaEventTracker(hitProcessor: fakeMediaService, config: config)
        mediaEventGenerator = MediaEventGenerator(config: config)
        mediaEventGenerator.setTimeStamp(value: 0)
    }

    func updatePlayerTime(ts: Int64?, playhead: Double? = nil) {
        if let ts = ts {
            mediaEventGenerator.setTimeStamp(value: ts)
        }
        if let playhead = playhead {
            mediaEventGenerator.updateCurrentPlayhead(time: playhead)
            let event = mediaEventGenerator.dispatchedEvent!
            mediaTracker.track(eventData: event.data)
            waitForProcessing()
        }
    }

    func waitFor(time: Int, updatePlayhead: Bool) {
        var startTs: Int64 = mediaEventGenerator.tracker.mockTimeStamp
        var playhead: Double = mediaEventGenerator.previousPlayhead
        for _ in 1...time/1000 {
            startTs = startTs + 1000
            if updatePlayhead {
                playhead += 1
            }
            updatePlayerTime(ts: startTs, playhead: playhead)
        }
    }

    // tests
    func testTrackSimplePlayBack_RealTimeTracker() {
        createTracker()

        mediaEventGenerator.trackSessionStart(info: mediaInfo.toMap(), metadata: mediaMetadata)
        let startEvent = mediaEventGenerator.dispatchedEvent!
        mediaTracker.track(eventData: startEvent.data)

        mediaEventGenerator.trackPlay()
        let playEvent1 = mediaEventGenerator.dispatchedEvent!
        mediaTracker.track(eventData: playEvent1.data)
        waitFor(time: 5000, updatePlayhead: true)

        mediaEventGenerator.trackPause()
        let pauseEvent = mediaEventGenerator.dispatchedEvent!
        mediaTracker.track(eventData: pauseEvent.data)
        waitFor(time: 15000, updatePlayhead: false)

        mediaEventGenerator.trackPlay()
        let playEvent2 = mediaEventGenerator.dispatchedEvent!
        mediaTracker.track(eventData: playEvent2.data)
        waitFor(time: 15000, updatePlayhead: true)

        mediaEventGenerator.trackComplete()
        let completeEvent = mediaEventGenerator.dispatchedEvent!
        mediaTracker.track(eventData: completeEvent.data)

        let expectedHit1 = getExpectedSessionStartHit(info: mediaInfo, metadata: mediaMetadata)
        let actualHit1 = fakeMediaService.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedHit1, actualHit1)
        let expectedHit2 = getExpectedPlaybackHit(eventType: EventType.PLAY)
        let actualHit2 = fakeMediaService.getHitFromActiveSession(index: 1)
        XCTAssertEqual(expectedHit2, actualHit2)
        let expectedHit3 = getExpectedPlaybackHit(eventType: EventType.PLAY, ts: 1000, playhead: 1)
        let actualHit3 = fakeMediaService.getHitFromActiveSession(index: 2)
        XCTAssertEqual(expectedHit3, actualHit3)
        let expectedHit4 = getExpectedPlaybackHit(eventType: EventType.PAUSE_START, ts: 5000, playhead: 5)
        let actualHit4 = fakeMediaService.getHitFromActiveSession(index: 3)
        XCTAssertEqual(expectedHit4, actualHit4)
        let expectedHit5 = getExpectedPlaybackHit(eventType: EventType.PING, ts: 15000, playhead: 5)
        let actualHit5 = fakeMediaService.getHitFromActiveSession(index: 4)
        XCTAssertEqual(expectedHit5, actualHit5)
        let expectedHit6 = getExpectedPlaybackHit(eventType: EventType.PLAY, ts: 20000, playhead: 5)
        let actualHit6 = fakeMediaService.getHitFromActiveSession(index: 5)
        XCTAssertEqual(expectedHit6, actualHit6)
        let expectedHit7 = getExpectedPlaybackHit(eventType: EventType.PING, ts: 30000, playhead: 15)
        let actualHit7 = fakeMediaService.getHitFromActiveSession(index: 6)
        XCTAssertEqual(expectedHit7, actualHit7)
        let expectedHit8 = getExpectedPlaybackHit(eventType: EventType.SESSION_COMPLETE, ts: 35000, playhead: 20)
        let actualHit8 = fakeMediaService.getHitFromActiveSession(index: 7)
        XCTAssertEqual(expectedHit8, actualHit8)
    }
}
