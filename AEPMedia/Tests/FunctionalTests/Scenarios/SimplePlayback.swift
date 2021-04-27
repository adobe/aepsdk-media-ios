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

class SimplePlayback: BaseScenarioTest {
    private typealias EventType = MediaConstants.MediaCollection.EventType
    private typealias Media = MediaConstants.MediaCollection.Media

    var mediaInfo = MediaInfo(id: "mediaID", name: "mediaName", streamType: "aod", mediaType: MediaType.Audio, length: 30.0, prerollWaitingTime: 0)!
    var mediaMetadata = ["media.show": "sampleshow", "key1": "value1"]

    override func setUp() {
        super.setup()
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

        let expectedSessionStartParams: [String: Any]  = [
            Media.ID: "mediaID",
            Media.NAME: "mediaName",
            Media.LENGTH: 30.0,
            Media.CONTENT_TYPE: "aod",
            Media.STREAM_TYPE: "audio",
            Media.RESUME: false,
            Media.DOWNLOADED: false,
        ]

        let expectedHits: [MediaHit] = [
            MediaHit(eventType: EventType.SESSION_START, playhead: 0, ts: 0, params: expectedSessionStartParams, customMetadata: mediaMetadata),
            MediaHit(eventType: EventType.PLAY, playhead: 0, ts: 0),
            MediaHit(eventType: EventType.PLAY, playhead: 1, ts: 1000),
            MediaHit(eventType: EventType.PAUSE_START, playhead: 5, ts: 5000),
            MediaHit(eventType: EventType.PING, playhead: 5, ts: 15000),
            MediaHit(eventType: EventType.PLAY, playhead: 5, ts: 20000),
            MediaHit(eventType: EventType.PING, playhead: 15, ts: 30000),
            MediaHit(eventType: EventType.SESSION_COMPLETE, playhead: 20, ts: 35000)
        ]

        //verify
        checkHits(expectedHits: expectedHits)
    }

    func testTrackSimplePlayBack_DownloadedTracker() {
        //setup
        createTracker(downloaded: true)

        //test
        mediaTracker.trackSessionStart(info: mediaInfo.toMap(), metadata: mediaMetadata)
        mediaTracker.trackPlay()
        waitFor(time: 5000, updatePlayhead: true)
        mediaTracker.trackPause()
        waitFor(time: 15000, updatePlayhead: false)
        mediaTracker.trackPlay()
        waitFor(time: 15000, updatePlayhead: true)
        mediaTracker.trackComplete()

        let expectedSessionStartParams: [String: Any]  = [
            Media.ID: "mediaID",
            Media.NAME: "mediaName",
            Media.LENGTH: 30.0,
            Media.CONTENT_TYPE: "aod",
            Media.STREAM_TYPE: "audio",
            Media.RESUME: false,
            Media.DOWNLOADED: true,
        ]

        let expectedHits: [MediaHit] = [
            MediaHit(eventType: EventType.SESSION_START, playhead: 0, ts: 0, params: expectedSessionStartParams, customMetadata: mediaMetadata),
            MediaHit(eventType: EventType.PLAY, playhead: 0, ts: 0),
            MediaHit(eventType: EventType.PLAY, playhead: 1, ts: 1000),
            MediaHit(eventType: EventType.PAUSE_START, playhead: 5, ts: 5000),
            MediaHit(eventType: EventType.PLAY, playhead: 5, ts: 20000),
            MediaHit(eventType: EventType.SESSION_COMPLETE, playhead: 20, ts: 35000)
        ]

        //verify
        checkHits(expectedHits: expectedHits)
    }

    func testTrackSimplePlayBack_with50SecPing_DownloadedTracker() {
        //setup
        createTracker(downloaded: true)

        //test
        mediaTracker.trackSessionStart(info: mediaInfo.toMap(), metadata: mediaMetadata)
        mediaTracker.trackPlay()
        waitFor(time: 5000, updatePlayhead: true)
        mediaTracker.trackPause()
        waitFor(time: 55000, updatePlayhead: false)
        mediaTracker.trackPlay()
        waitFor(time: 55000, updatePlayhead: true)
        mediaTracker.trackComplete()

        let expectedSessionStartParams: [String: Any]  = [
            Media.ID: "mediaID",
            Media.NAME: "mediaName",
            Media.LENGTH: 30.0,
            Media.CONTENT_TYPE: "aod",
            Media.STREAM_TYPE: "audio",
            Media.RESUME: false,
            Media.DOWNLOADED: true,
        ]

        let expectedHits: [MediaHit] = [
            MediaHit(eventType: EventType.SESSION_START, playhead: 0, ts: 0, params: expectedSessionStartParams, customMetadata: mediaMetadata),
            MediaHit(eventType: EventType.PLAY, playhead: 0, ts: 0),
            MediaHit(eventType: EventType.PLAY, playhead: 1, ts: 1000),
            MediaHit(eventType: EventType.PAUSE_START, playhead: 5, ts: 5000),
            MediaHit(eventType: EventType.PING, playhead: 5, ts: 55000),
            MediaHit(eventType: EventType.PLAY, playhead: 5, ts: 60000),
            MediaHit(eventType: EventType.PING, playhead: 55, ts: 110000),
            MediaHit(eventType: EventType.SESSION_COMPLETE, playhead: 60, ts: 115000)
        ]

        //verify
        checkHits(expectedHits: expectedHits)
    }

    func testTrackSimplePlayBack_SessionSkip_RealTimeTracker() {
        //test
        mediaTracker.trackSessionStart(info: mediaInfo.toMap(), metadata: mediaMetadata)
        mediaTracker.trackPlay()
        waitFor(time: 5000, updatePlayhead: true)
        mediaTracker.trackPause()
        waitFor(time: 15000, updatePlayhead: false)
        mediaTracker.trackPlay()
        waitFor(time: 15000, updatePlayhead: true)
        mediaTracker.trackSessionEnd()

        let expectedSessionStartParams: [String: Any]  = [
            Media.ID: "mediaID",
            Media.NAME: "mediaName",
            Media.LENGTH: 30.0,
            Media.CONTENT_TYPE: "aod",
            Media.STREAM_TYPE: "audio",
            Media.RESUME: false,
            Media.DOWNLOADED: false,
        ]

        let expectedHits: [MediaHit] = [
            MediaHit(eventType: EventType.SESSION_START, playhead: 0, ts: 0, params: expectedSessionStartParams, customMetadata: mediaMetadata),
            MediaHit(eventType: EventType.PLAY, playhead: 0, ts: 0),
            MediaHit(eventType: EventType.PLAY, playhead: 1, ts: 1000),
            MediaHit(eventType: EventType.PAUSE_START, playhead: 5, ts: 5000),
            MediaHit(eventType: EventType.PING, playhead: 5, ts: 15000),
            MediaHit(eventType: EventType.PLAY, playhead: 5, ts: 20000),
            MediaHit(eventType: EventType.PING, playhead: 15, ts: 30000),
            MediaHit(eventType: EventType.SESSION_END, playhead: 20, ts: 35000)
        ]

        //verify
        checkHits(expectedHits: expectedHits)
    }

    func testTrackSimplePlayBack_SessionSkip_DownloadedTracker() {
        //setup
        createTracker(downloaded: true)

        //test
        mediaTracker.trackSessionStart(info: mediaInfo.toMap(), metadata: mediaMetadata)
        mediaTracker.trackPlay()
        waitFor(time: 5000, updatePlayhead: true)
        mediaTracker.trackPause()
        waitFor(time: 55000, updatePlayhead: false)
        mediaTracker.trackPlay()
        waitFor(time: 55000, updatePlayhead: true)
        mediaTracker.trackSessionEnd()

        let expectedSessionStartParams: [String: Any]  = [
            Media.ID: "mediaID",
            Media.NAME: "mediaName",
            Media.LENGTH: 30.0,
            Media.CONTENT_TYPE: "aod",
            Media.STREAM_TYPE: "audio",
            Media.RESUME: false,
            Media.DOWNLOADED: true,
        ]

        let expectedHits: [MediaHit] = [
            MediaHit(eventType: EventType.SESSION_START, playhead: 0, ts: 0, params: expectedSessionStartParams, customMetadata: mediaMetadata),
            MediaHit(eventType: EventType.PLAY, playhead: 0, ts: 0),
            MediaHit(eventType: EventType.PLAY, playhead: 1, ts: 1000),
            MediaHit(eventType: EventType.PAUSE_START, playhead: 5, ts: 5000),
            MediaHit(eventType: EventType.PING, playhead: 5, ts: 55000),
            MediaHit(eventType: EventType.PLAY, playhead: 5, ts: 60000),
            MediaHit(eventType: EventType.PING, playhead: 55, ts: 110000),
            MediaHit(eventType: EventType.SESSION_END, playhead: 60, ts: 115000)
        ]

        //verify
        checkHits(expectedHits: expectedHits)
    }

    func testTrackSimplePlayBack_withBuffer_RealTimeTracker() {

        //test
        mediaTracker.trackSessionStart(info: mediaInfo.toMap(), metadata: mediaMetadata)
        mediaTracker.trackEvent(event: MediaEvent.BufferStart)
        waitFor(time: 5000, updatePlayhead: false)
        mediaTracker.trackPlay()
        waitFor(time: 5000, updatePlayhead: true)
        mediaTracker.trackEvent(event: MediaEvent.BufferStart)
        waitFor(time: 15000, updatePlayhead: false)
        mediaTracker.trackEvent(event: MediaEvent.BufferComplete)
        mediaTracker.trackPlay()
        waitFor(time: 15000, updatePlayhead: true)
        mediaTracker.trackComplete()

        let expectedSessionStartParams: [String: Any]  = [
            Media.ID: "mediaID",
            Media.NAME: "mediaName",
            Media.LENGTH: 30.0,
            Media.CONTENT_TYPE: "aod",
            Media.STREAM_TYPE: "audio",
            Media.RESUME: false,
            Media.DOWNLOADED: false,
        ]

        let expectedHits: [MediaHit] = [
            MediaHit(eventType: EventType.SESSION_START, playhead: 0, ts: 0, params: expectedSessionStartParams, customMetadata: mediaMetadata),
            MediaHit(eventType: EventType.BUFFER_START, playhead: 0, ts: 0),
            MediaHit(eventType: EventType.PLAY, playhead: 0, ts: 5000),
            MediaHit(eventType: EventType.PLAY, playhead: 1, ts: 6000),
            MediaHit(eventType: EventType.BUFFER_START, playhead: 5, ts: 10000),
            MediaHit(eventType: EventType.PING, playhead: 5, ts: 20000),
            MediaHit(eventType: EventType.PLAY, playhead: 5, ts: 25000),
            MediaHit(eventType: EventType.PING, playhead: 15, ts: 35000),
            MediaHit(eventType: EventType.SESSION_COMPLETE, playhead: 20, ts: 40000)
        ]

        //verify
        checkHits(expectedHits: expectedHits)
    }

    func testTrackSimplePlayBack_withBuffer_DownloadedTracker() {
        //setup
        createTracker(downloaded: true)

        //test
        mediaTracker.trackSessionStart(info: mediaInfo.toMap(), metadata: mediaMetadata)
        mediaTracker.trackEvent(event: MediaEvent.BufferStart)
        waitFor(time: 5000, updatePlayhead: false)
        mediaTracker.trackPlay()
        waitFor(time: 5000, updatePlayhead: true)
        mediaTracker.trackEvent(event: MediaEvent.BufferStart)
        waitFor(time: 55000, updatePlayhead: false)
        mediaTracker.trackEvent(event: MediaEvent.BufferComplete)
        mediaTracker.trackPlay()
        waitFor(time: 55000, updatePlayhead: true)
        mediaTracker.trackComplete()

        let expectedSessionStartParams: [String: Any]  = [
            Media.ID: "mediaID",
            Media.NAME: "mediaName",
            Media.LENGTH: 30.0,
            Media.CONTENT_TYPE: "aod",
            Media.STREAM_TYPE: "audio",
            Media.RESUME: false,
            Media.DOWNLOADED: true,
        ]

        let expectedHits: [MediaHit] = [
            MediaHit(eventType: EventType.SESSION_START, playhead: 0, ts: 0, params: expectedSessionStartParams, customMetadata: mediaMetadata),
            MediaHit(eventType: EventType.BUFFER_START, playhead: 0, ts: 0),
            MediaHit(eventType: EventType.PLAY, playhead: 0, ts: 5000),
            MediaHit(eventType: EventType.PLAY, playhead: 1, ts: 6000),
            MediaHit(eventType: EventType.BUFFER_START, playhead: 5, ts: 10000),
            MediaHit(eventType: EventType.PING, playhead: 5, ts: 60000),
            MediaHit(eventType: EventType.PLAY, playhead: 5, ts: 65000),
            MediaHit(eventType: EventType.PING, playhead: 55, ts: 115000),
            MediaHit(eventType: EventType.SESSION_COMPLETE, playhead: 60, ts: 120000)
        ]

        //verify
        checkHits(expectedHits: expectedHits)
    }

    func testTrackSimplePlayBack_withSeek_RealTimeTracker() {
        //test
        mediaTracker.trackSessionStart(info: mediaInfo.toMap(), metadata: mediaMetadata)
        mediaTracker.trackEvent(event: MediaEvent.SeekStart)
        waitFor(time: 5000, updatePlayhead: false)
        mediaTracker.trackPlay()
        waitFor(time: 5000, updatePlayhead: true)
        mediaTracker.trackEvent(event: MediaEvent.SeekStart)
        waitFor(time: 15000, updatePlayhead: false)
        mediaTracker.trackEvent(event: MediaEvent.SeekComplete)
        mediaTracker.trackPlay()
        waitFor(time: 15000, updatePlayhead: true)
        mediaTracker.trackComplete()

        let expectedSessionStartParams: [String: Any]  = [
            Media.ID: "mediaID",
            Media.NAME: "mediaName",
            Media.LENGTH: 30.0,
            Media.CONTENT_TYPE: "aod",
            Media.STREAM_TYPE: "audio",
            Media.RESUME: false,
            Media.DOWNLOADED: false,
        ]

        let expectedHits: [MediaHit] = [
            MediaHit(eventType: EventType.SESSION_START, playhead: 0, ts: 0, params: expectedSessionStartParams, customMetadata: mediaMetadata),
            MediaHit(eventType: EventType.PAUSE_START, playhead: 0, ts: 0),
            MediaHit(eventType: EventType.PLAY, playhead: 0, ts: 5000),
            MediaHit(eventType: EventType.PLAY, playhead: 1, ts: 6000),
            MediaHit(eventType: EventType.PAUSE_START, playhead: 5, ts: 10000),
            MediaHit(eventType: EventType.PING, playhead: 5, ts: 20000),
            MediaHit(eventType: EventType.PLAY, playhead: 5, ts: 25000),
            MediaHit(eventType: EventType.PING, playhead: 15, ts: 35000),
            MediaHit(eventType: EventType.SESSION_COMPLETE, playhead: 20, ts: 40000)
        ]

        //verify
        checkHits(expectedHits: expectedHits)
    }

    func testTrackSimplePlayBack_withSeek_DownloadedTracker() {
        //setup
        createTracker(downloaded: true)

        //test
        mediaTracker.trackSessionStart(info: mediaInfo.toMap(), metadata: mediaMetadata)
        mediaTracker.trackEvent(event: MediaEvent.SeekStart)
        waitFor(time: 5000, updatePlayhead: false)
        mediaTracker.trackPlay()
        waitFor(time: 5000, updatePlayhead: true)
        mediaTracker.trackEvent(event: MediaEvent.SeekStart)
        waitFor(time: 55000, updatePlayhead: false)
        mediaTracker.trackEvent(event: MediaEvent.SeekComplete)
        mediaTracker.trackPlay()
        waitFor(time: 55000, updatePlayhead: true)
        mediaTracker.trackComplete()

        let expectedSessionStartParams: [String: Any]  = [
            Media.ID: "mediaID",
            Media.NAME: "mediaName",
            Media.LENGTH: 30.0,
            Media.CONTENT_TYPE: "aod",
            Media.STREAM_TYPE: "audio",
            Media.RESUME: false,
            Media.DOWNLOADED: true,
        ]

        let expectedHits: [MediaHit] = [
            MediaHit(eventType: EventType.SESSION_START, playhead: 0, ts: 0, params: expectedSessionStartParams, customMetadata: mediaMetadata),
            MediaHit(eventType: EventType.PAUSE_START, playhead: 0, ts: 0),
            MediaHit(eventType: EventType.PLAY, playhead: 0, ts: 5000),
            MediaHit(eventType: EventType.PLAY, playhead: 1, ts: 6000),
            MediaHit(eventType: EventType.PAUSE_START, playhead: 5, ts: 10000),
            MediaHit(eventType: EventType.PING, playhead: 5, ts: 60000),
            MediaHit(eventType: EventType.PLAY, playhead: 5, ts: 65000),
            MediaHit(eventType: EventType.PING, playhead: 55, ts: 115000),
            MediaHit(eventType: EventType.SESSION_COMPLETE, playhead: 60, ts: 120000)
        ]

        //verify
        checkHits(expectedHits: expectedHits)
    }
}
