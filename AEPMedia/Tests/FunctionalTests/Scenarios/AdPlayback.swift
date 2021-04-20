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

class AdPlayback: XCTestCase {
    private typealias EventType = MediaConstants.MediaCollection.EventType
    private typealias Media = MediaConstants.MediaCollection.Media
    private typealias AdBreak = MediaConstants.MediaCollection.AdBreak
    private typealias Ad = MediaConstants.MediaCollection.Ad

    var fakeMediaService: FakeMediaHitProcessor!
    var mediaEventTracker: MediaEventTracking!
    var mediaTracker: MediaEventGenerator!

    let mediaInfo = MediaInfo(id: "mediaID", name: "mediaName", streamType: "aod", mediaType: MediaType.Audio, length: 30.0, prerollWaitingTime: 0)!
    let mediaInfoWithDefaultPreroll = MediaInfo(id: "mediaID", name: "mediaName", streamType: "aod", mediaType: MediaType.Audio, length: 30.0)!
    let mediaMetadata = ["media.show": "sampleshow", "key1": "value1", "key2": "мểŧẳđαţả"]

    let adBreakInfo = AdBreakInfo(name: "adBreakName", position: 1, startTime: 1.1)!

    let adInfo = AdInfo(id: "adID", name: "adName", position: 1, length: 15.0)!
    let adMetadata = ["media.ad.advertiser": "sampleAdvertiser", "key1": "value1", "key2": "мểŧẳđαţả"]

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
    func testPrerollAd_RealTimeTracker() {
        //test
        mediaTracker.trackSessionStart(info: mediaInfoWithDefaultPreroll.toMap(), metadata: mediaMetadata)
        mediaTracker.trackPlay()
        mediaTracker.trackEvent(event: MediaEvent.AdBreakStart, info: adBreakInfo.toMap())
        mediaTracker.trackEvent(event: MediaEvent.AdStart, info: adInfo.toMap(), metadata: adMetadata)
        waitFor(time: 15000, updatePlayhead: false)
        mediaTracker.trackEvent(event: MediaEvent.AdComplete)
        mediaTracker.trackEvent(event: MediaEvent.AdBreakComplete)
        // should switch to play state
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

        let expectedAdBreakStartParams: [String: Any] = [
            AdBreak.POD_FRIENDLY_NAME: "adBreakName",
            AdBreak.POD_INDEX: 1,
            AdBreak.POD_SECOND: 1.1
        ]

        let expectedAdParams: [String: Any] = [
            Ad.ID: "adID",
            Ad.NAME: "adName",
            Ad.LENGTH: 15.0,
            Ad.POD_POSITION: 1
        ]

        let expectedHits: [MediaHit] = [
            MediaHit(eventType: EventType.SESSION_START, playhead: 0, ts: 0, params: expectedSessionStartParams, customMetadata: mediaMetadata),
            MediaHit(eventType: EventType.ADBREAK_START, playhead: 0, ts: 0, params: expectedAdBreakStartParams),
            MediaHit(eventType: EventType.AD_START, playhead: 0, ts: 0, params: expectedAdParams, customMetadata: adMetadata),
            MediaHit(eventType: EventType.PLAY, playhead: 0, ts: 0),
            MediaHit(eventType: EventType.PING, playhead: 0, ts: 10000),
            MediaHit(eventType: EventType.AD_COMPLETE, playhead: 0, ts: 15000),
            MediaHit(eventType: EventType.ADBREAK_COMPLETE, playhead: 0, ts: 15000),
            MediaHit(eventType: EventType.PLAY, playhead: 0, ts: 15000),
            MediaHit(eventType: EventType.PLAY, playhead: 1, ts: 16000),
            MediaHit(eventType: EventType.PING, playhead: 11, ts: 26000),
            MediaHit(eventType: EventType.SESSION_COMPLETE, playhead: 15, ts: 30000)
        ]

        //verify
        checkHits(expectedHits: expectedHits)
    }

    func testPrerollAd_DownloadedTracker() {
        //setup
        createTracker(downloaded: true)

        //test
        mediaTracker.trackSessionStart(info: mediaInfoWithDefaultPreroll.toMap(), metadata: mediaMetadata)
        mediaTracker.trackPlay()
        mediaTracker.trackEvent(event: MediaEvent.AdBreakStart, info: adBreakInfo.toMap())
        mediaTracker.trackEvent(event: MediaEvent.AdStart, info: adInfo.toMap(), metadata: adMetadata)
        waitFor(time: 55000, updatePlayhead: false)
        mediaTracker.trackEvent(event: MediaEvent.AdComplete)
        mediaTracker.trackEvent(event: MediaEvent.AdBreakComplete)
        // should switch to play state
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

        let expectedAdBreakStartParams: [String: Any] = [
            AdBreak.POD_FRIENDLY_NAME: "adBreakName",
            AdBreak.POD_INDEX: 1,
            AdBreak.POD_SECOND: 1.1
        ]

        let expectedAdParams: [String: Any] = [
            Ad.ID: "adID",
            Ad.NAME: "adName",
            Ad.LENGTH: 15.0,
            Ad.POD_POSITION: 1
        ]

        let expectedHits: [MediaHit] = [
            MediaHit(eventType: EventType.SESSION_START, playhead: 0, ts: 0, params: expectedSessionStartParams, customMetadata: mediaMetadata),
            MediaHit(eventType: EventType.ADBREAK_START, playhead: 0, ts: 0, params: expectedAdBreakStartParams),
            MediaHit(eventType: EventType.AD_START, playhead: 0, ts: 0, params: expectedAdParams, customMetadata: adMetadata),
            MediaHit(eventType: EventType.PLAY, playhead: 0, ts: 0),
            MediaHit(eventType: EventType.PING, playhead: 0, ts: 50000),
            MediaHit(eventType: EventType.AD_COMPLETE, playhead: 0, ts: 55000),
            MediaHit(eventType: EventType.ADBREAK_COMPLETE, playhead: 0, ts: 55000),
            MediaHit(eventType: EventType.PLAY, playhead: 0, ts: 55000),
            MediaHit(eventType: EventType.PLAY, playhead: 1, ts: 56000),
            MediaHit(eventType: EventType.PING, playhead: 51, ts: 106000),
            MediaHit(eventType: EventType.SESSION_COMPLETE, playhead: 55, ts: 110000)
        ]

        //verify
        checkHits(expectedHits: expectedHits)
    }
}
