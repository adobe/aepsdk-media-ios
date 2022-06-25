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
@testable import AEPMedia

class AdPlayback: BaseScenarioTest {
    private typealias EventType = MediaConstants.MediaCollection.EventType
    private typealias Media = MediaConstants.MediaCollection.Media
    private typealias AdBreak = MediaConstants.MediaCollection.AdBreak
    private typealias Ad = MediaConstants.MediaCollection.Ad

    let mediaInfo = MediaInfo(id: "mediaID", name: "mediaName", streamType: "aod", mediaType: MediaType.Audio, length: 30.0, prerollWaitingTime: 0)!
    let mediaInfoWithDefaultPreroll = MediaInfo(id: "mediaID", name: "mediaName", streamType: "aod", mediaType: MediaType.Audio, length: 30.0)!
    let mediaInfoWithDefaultPrerollAndGranularTracking = MediaInfo(id: "mediaID", name: "mediaName", streamType: "aod", mediaType: MediaType.Audio, length: 30.0, granularAdTracking: true)!
    let mediaMetadata = ["media.show": "sampleshow", "key1": "value1", "key2": "мểŧẳđαţả"]

    let adBreakInfo = AdBreakInfo(name: "adBreakName", position: 1, startTime: 1.1)!
    let adBreakInfo2 = AdBreakInfo(name: "adBreakName2", position: 2, startTime: 2.2)!

    let adInfo = AdInfo(id: "adID", name: "adName", position: 1, length: 15.0)!
    let adMetadata = ["media.ad.advertiser": "sampleAdvertiser", "key1": "value1", "key2": "мểŧẳđαţả"]

    let adInfo2 = AdInfo(id: "adID2", name: "adName2", position: 2, length: 20.0)!
    let adMetadata2 = ["media.ad.advertiser": "sampleAdvertiser2", "key2": "value2", "key3": "мểŧẳđαţả"]

    override func setUp() {
        super.setup()
    }

    // tests
    func testPrerollAd_RealTimeTracker() {
        // test
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

        // verify
        checkHits(expectedHits: expectedHits)
    }

    func testPrerollAd_DownloadedTracker() {
        // setup
        createTracker(downloaded: true)

        // test
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

        // verify
        checkHits(expectedHits: expectedHits)
    }

    func testPrerollAd_withGranularTrackingEnabled_RealTimeTracker() {
        // test
        mediaTracker.trackSessionStart(info: mediaInfoWithDefaultPrerollAndGranularTracking.toMap(), metadata: mediaMetadata)
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
            MediaHit(eventType: EventType.PING, playhead: 0, ts: 1000),
            MediaHit(eventType: EventType.PING, playhead: 0, ts: 2000),
            MediaHit(eventType: EventType.PING, playhead: 0, ts: 3000),
            MediaHit(eventType: EventType.PING, playhead: 0, ts: 4000),
            MediaHit(eventType: EventType.PING, playhead: 0, ts: 5000),
            MediaHit(eventType: EventType.PING, playhead: 0, ts: 6000),
            MediaHit(eventType: EventType.PING, playhead: 0, ts: 7000),
            MediaHit(eventType: EventType.PING, playhead: 0, ts: 8000),
            MediaHit(eventType: EventType.PING, playhead: 0, ts: 9000),
            MediaHit(eventType: EventType.PING, playhead: 0, ts: 10000),
            MediaHit(eventType: EventType.PING, playhead: 0, ts: 11000),
            MediaHit(eventType: EventType.PING, playhead: 0, ts: 12000),
            MediaHit(eventType: EventType.PING, playhead: 0, ts: 13000),
            MediaHit(eventType: EventType.PING, playhead: 0, ts: 14000),
            MediaHit(eventType: EventType.PING, playhead: 0, ts: 15000),
            MediaHit(eventType: EventType.AD_COMPLETE, playhead: 0, ts: 15000),
            MediaHit(eventType: EventType.ADBREAK_COMPLETE, playhead: 0, ts: 15000),
            MediaHit(eventType: EventType.PLAY, playhead: 0, ts: 15000),
            MediaHit(eventType: EventType.PLAY, playhead: 1, ts: 16000),
            MediaHit(eventType: EventType.PING, playhead: 11, ts: 26000),
            MediaHit(eventType: EventType.SESSION_COMPLETE, playhead: 15, ts: 30000)
        ]

        // verify
        checkHits(expectedHits: expectedHits)
    }

    func testPreollAd_withGranularTrackingEnabled_DownloadedTracker() {
        // setup
        createTracker(downloaded: true)

        // test
        mediaTracker.trackSessionStart(info: mediaInfoWithDefaultPrerollAndGranularTracking.toMap(), metadata: mediaMetadata)
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

        // verify
        checkHits(expectedHits: expectedHits)
    }

    func testMultipleAdBreakMultipleAds_RealTimeTracker() {
        // test
        mediaTracker.trackSessionStart(info: mediaInfo.toMap(), metadata: mediaMetadata)
        mediaTracker.trackEvent(event: MediaEvent.AdBreakStart, info: adBreakInfo.toMap())
        mediaTracker.trackEvent(event: MediaEvent.AdStart, info: adInfo.toMap(), metadata: adMetadata)
        waitFor(time: 15000, updatePlayhead: false)
        mediaTracker.trackEvent(event: MediaEvent.AdComplete)
        mediaTracker.trackEvent(event: MediaEvent.AdStart, info: adInfo2.toMap(), metadata: adMetadata2)
        waitFor(time: 15000, updatePlayhead: false)
        mediaTracker.trackEvent(event: MediaEvent.AdComplete)
        mediaTracker.trackEvent(event: MediaEvent.AdBreakComplete)
        // explicitly switch to play state
        mediaTracker.trackPlay()
        waitFor(time: 15000, updatePlayhead: true)
        mediaTracker.trackEvent(event: MediaEvent.AdBreakStart, info: adBreakInfo2.toMap())
        mediaTracker.trackEvent(event: MediaEvent.AdStart, info: adInfo.toMap(), metadata: adMetadata)
        waitFor(time: 15000, updatePlayhead: false)
        mediaTracker.trackEvent(event: MediaEvent.AdComplete)
        mediaTracker.trackEvent(event: MediaEvent.AdStart, info: adInfo2.toMap(), metadata: adMetadata2)
        waitFor(time: 15000, updatePlayhead: false)
        mediaTracker.trackEvent(event: MediaEvent.AdComplete)
        mediaTracker.trackEvent(event: MediaEvent.AdBreakComplete)
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

        let expectedAdBreakStartParams2: [String: Any] = [
            AdBreak.POD_FRIENDLY_NAME: "adBreakName2",
            AdBreak.POD_INDEX: 2,
            AdBreak.POD_SECOND: 2.2
        ]

        let expectedAdParams: [String: Any] = [
            Ad.ID: "adID",
            Ad.NAME: "adName",
            Ad.LENGTH: 15.0,
            Ad.POD_POSITION: 1
        ]

        let expectedAdParams2: [String: Any] = [
            Ad.ID: "adID2",
            Ad.NAME: "adName2",
            Ad.LENGTH: 20.0,
            Ad.POD_POSITION: 2
        ]

        let expectedHits: [MediaHit] = [
            MediaHit(eventType: EventType.SESSION_START, playhead: 0, ts: 0, params: expectedSessionStartParams, customMetadata: mediaMetadata),
            MediaHit(eventType: EventType.ADBREAK_START, playhead: 0, ts: 0, params: expectedAdBreakStartParams),
            MediaHit(eventType: EventType.AD_START, playhead: 0, ts: 0, params: expectedAdParams, customMetadata: adMetadata),
            MediaHit(eventType: EventType.PLAY, playhead: 0, ts: 0),
            MediaHit(eventType: EventType.PING, playhead: 0, ts: 10000),
            MediaHit(eventType: EventType.AD_COMPLETE, playhead: 0, ts: 15000),
            MediaHit(eventType: EventType.AD_START, playhead: 0, ts: 15000, params: expectedAdParams2, customMetadata: adMetadata2),
            MediaHit(eventType: EventType.PLAY, playhead: 0, ts: 15000),
            MediaHit(eventType: EventType.PING, playhead: 0, ts: 25000),
            MediaHit(eventType: EventType.AD_COMPLETE, playhead: 0, ts: 30000),
            MediaHit(eventType: EventType.ADBREAK_COMPLETE, playhead: 0, ts: 30000),
            MediaHit(eventType: EventType.PLAY, playhead: 0, ts: 30000),
            MediaHit(eventType: EventType.PLAY, playhead: 1, ts: 31000),
            MediaHit(eventType: EventType.PING, playhead: 11, ts: 41000),
            MediaHit(eventType: EventType.ADBREAK_START, playhead: 15, ts: 45000, params: expectedAdBreakStartParams2),
            MediaHit(eventType: EventType.AD_START, playhead: 15, ts: 45000, params: expectedAdParams, customMetadata: adMetadata),
            MediaHit(eventType: EventType.PLAY, playhead: 15, ts: 45000),
            MediaHit(eventType: EventType.PING, playhead: 15, ts: 55000),
            MediaHit(eventType: EventType.AD_COMPLETE, playhead: 15, ts: 60000),
            MediaHit(eventType: EventType.AD_START, playhead: 15, ts: 60000, params: expectedAdParams2, customMetadata: adMetadata2),
            MediaHit(eventType: EventType.PLAY, playhead: 15, ts: 60000),
            MediaHit(eventType: EventType.PING, playhead: 15, ts: 70000),
            MediaHit(eventType: EventType.AD_COMPLETE, playhead: 15, ts: 75000),
            MediaHit(eventType: EventType.ADBREAK_COMPLETE, playhead: 15, ts: 75000),
            MediaHit(eventType: EventType.PLAY, playhead: 15, ts: 75000),
            MediaHit(eventType: EventType.SESSION_COMPLETE, playhead: 15, ts: 75000)
        ]

        // verify
        checkHits(expectedHits: expectedHits)
    }

    func testMultipleAdBreakMultipleAds_GranularTracking_RealTimeTracker() {
        // test
        mediaTracker.trackSessionStart(info: mediaInfoWithDefaultPrerollAndGranularTracking.toMap(), metadata: mediaMetadata)
        mediaTracker.trackEvent(event: MediaEvent.AdBreakStart, info: adBreakInfo.toMap())
        mediaTracker.trackEvent(event: MediaEvent.AdStart, info: adInfo.toMap(), metadata: adMetadata)
        waitFor(time: 5000, updatePlayhead: false)
        mediaTracker.trackEvent(event: MediaEvent.AdComplete)
        mediaTracker.trackEvent(event: MediaEvent.AdStart, info: adInfo2.toMap(), metadata: adMetadata2)
        waitFor(time: 5000, updatePlayhead: false)
        mediaTracker.trackEvent(event: MediaEvent.AdComplete)
        mediaTracker.trackEvent(event: MediaEvent.AdBreakComplete)
        // explicitly switch to play state
        mediaTracker.trackPlay()
        waitFor(time: 15000, updatePlayhead: true)
        mediaTracker.trackEvent(event: MediaEvent.AdBreakStart, info: adBreakInfo2.toMap())
        mediaTracker.trackEvent(event: MediaEvent.AdStart, info: adInfo.toMap(), metadata: adMetadata)
        waitFor(time: 5000, updatePlayhead: false)
        mediaTracker.trackEvent(event: MediaEvent.AdComplete)
        mediaTracker.trackEvent(event: MediaEvent.AdStart, info: adInfo2.toMap(), metadata: adMetadata2)
        waitFor(time: 5000, updatePlayhead: false)
        mediaTracker.trackEvent(event: MediaEvent.AdComplete)
        mediaTracker.trackEvent(event: MediaEvent.AdBreakComplete)
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

        let expectedAdBreakStartParams2: [String: Any] = [
            AdBreak.POD_FRIENDLY_NAME: "adBreakName2",
            AdBreak.POD_INDEX: 2,
            AdBreak.POD_SECOND: 2.2
        ]

        let expectedAdParams: [String: Any] = [
            Ad.ID: "adID",
            Ad.NAME: "adName",
            Ad.LENGTH: 15.0,
            Ad.POD_POSITION: 1
        ]

        let expectedAdParams2: [String: Any] = [
            Ad.ID: "adID2",
            Ad.NAME: "adName2",
            Ad.LENGTH: 20.0,
            Ad.POD_POSITION: 2
        ]

        let expectedHits: [MediaHit] = [
            MediaHit(eventType: EventType.SESSION_START, playhead: 0, ts: 0, params: expectedSessionStartParams, customMetadata: mediaMetadata),
            MediaHit(eventType: EventType.ADBREAK_START, playhead: 0, ts: 0, params: expectedAdBreakStartParams),
            MediaHit(eventType: EventType.AD_START, playhead: 0, ts: 0, params: expectedAdParams, customMetadata: adMetadata),
            MediaHit(eventType: EventType.PLAY, playhead: 0, ts: 0),
            MediaHit(eventType: EventType.PING, playhead: 0, ts: 1000),
            MediaHit(eventType: EventType.PING, playhead: 0, ts: 2000),
            MediaHit(eventType: EventType.PING, playhead: 0, ts: 3000),
            MediaHit(eventType: EventType.PING, playhead: 0, ts: 4000),
            MediaHit(eventType: EventType.PING, playhead: 0, ts: 5000),
            MediaHit(eventType: EventType.AD_COMPLETE, playhead: 0, ts: 5000),
            MediaHit(eventType: EventType.AD_START, playhead: 0, ts: 5000, params: expectedAdParams2, customMetadata: adMetadata2),
            MediaHit(eventType: EventType.PLAY, playhead: 0, ts: 5000),
            MediaHit(eventType: EventType.PING, playhead: 0, ts: 6000),
            MediaHit(eventType: EventType.PING, playhead: 0, ts: 7000),
            MediaHit(eventType: EventType.PING, playhead: 0, ts: 8000),
            MediaHit(eventType: EventType.PING, playhead: 0, ts: 9000),
            MediaHit(eventType: EventType.PING, playhead: 0, ts: 10000),
            MediaHit(eventType: EventType.AD_COMPLETE, playhead: 0, ts: 10000),
            MediaHit(eventType: EventType.ADBREAK_COMPLETE, playhead: 0, ts: 10000),
            MediaHit(eventType: EventType.PLAY, playhead: 0, ts: 10000),
            MediaHit(eventType: EventType.PLAY, playhead: 1, ts: 11000),
            MediaHit(eventType: EventType.PING, playhead: 11, ts: 21000),
            MediaHit(eventType: EventType.ADBREAK_START, playhead: 15, ts: 25000, params: expectedAdBreakStartParams2),
            MediaHit(eventType: EventType.AD_START, playhead: 15, ts: 25000, params: expectedAdParams, customMetadata: adMetadata),
            MediaHit(eventType: EventType.PLAY, playhead: 15, ts: 25000),
            MediaHit(eventType: EventType.PING, playhead: 15, ts: 26000),
            MediaHit(eventType: EventType.PING, playhead: 15, ts: 27000),
            MediaHit(eventType: EventType.PING, playhead: 15, ts: 28000),
            MediaHit(eventType: EventType.PING, playhead: 15, ts: 29000),
            MediaHit(eventType: EventType.PING, playhead: 15, ts: 30000),
            MediaHit(eventType: EventType.AD_COMPLETE, playhead: 15, ts: 30000),
            MediaHit(eventType: EventType.AD_START, playhead: 15, ts: 30000, params: expectedAdParams2, customMetadata: adMetadata2),
            MediaHit(eventType: EventType.PLAY, playhead: 15, ts: 30000),
            MediaHit(eventType: EventType.PING, playhead: 15, ts: 31000),
            MediaHit(eventType: EventType.PING, playhead: 15, ts: 32000),
            MediaHit(eventType: EventType.PING, playhead: 15, ts: 33000),
            MediaHit(eventType: EventType.PING, playhead: 15, ts: 34000),
            MediaHit(eventType: EventType.PING, playhead: 15, ts: 35000),
            MediaHit(eventType: EventType.AD_COMPLETE, playhead: 15, ts: 35000),
            MediaHit(eventType: EventType.ADBREAK_COMPLETE, playhead: 15, ts: 35000),
            MediaHit(eventType: EventType.PLAY, playhead: 15, ts: 35000),
            MediaHit(eventType: EventType.SESSION_COMPLETE, playhead: 15, ts: 35000)
        ]

        // verify
        checkHits(expectedHits: expectedHits)
    }

    func testMultipleAdBreakMultipleAds_DownloadedTracker() {
        //
        createTracker(downloaded: true)

        // test
        mediaTracker.trackSessionStart(info: mediaInfo.toMap(), metadata: mediaMetadata)
        mediaTracker.trackEvent(event: MediaEvent.AdBreakStart, info: adBreakInfo.toMap())
        mediaTracker.trackEvent(event: MediaEvent.AdStart, info: adInfo.toMap(), metadata: adMetadata)
        waitFor(time: 55000, updatePlayhead: false)
        mediaTracker.trackEvent(event: MediaEvent.AdComplete)
        mediaTracker.trackEvent(event: MediaEvent.AdStart, info: adInfo2.toMap(), metadata: adMetadata2)
        waitFor(time: 55000, updatePlayhead: false)
        mediaTracker.trackEvent(event: MediaEvent.AdComplete)
        mediaTracker.trackEvent(event: MediaEvent.AdBreakComplete)
        // explicitly switch to play state
        mediaTracker.trackPlay()
        waitFor(time: 55000, updatePlayhead: true)
        mediaTracker.trackEvent(event: MediaEvent.AdBreakStart, info: adBreakInfo2.toMap())
        mediaTracker.trackEvent(event: MediaEvent.AdStart, info: adInfo.toMap(), metadata: adMetadata)
        waitFor(time: 55000, updatePlayhead: false)
        mediaTracker.trackEvent(event: MediaEvent.AdComplete)
        mediaTracker.trackEvent(event: MediaEvent.AdStart, info: adInfo2.toMap(), metadata: adMetadata2)
        waitFor(time: 55000, updatePlayhead: false)
        mediaTracker.trackEvent(event: MediaEvent.AdComplete)
        mediaTracker.trackEvent(event: MediaEvent.AdBreakComplete)
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

        let expectedAdBreakStartParams2: [String: Any] = [
            AdBreak.POD_FRIENDLY_NAME: "adBreakName2",
            AdBreak.POD_INDEX: 2,
            AdBreak.POD_SECOND: 2.2
        ]

        let expectedAdParams: [String: Any] = [
            Ad.ID: "adID",
            Ad.NAME: "adName",
            Ad.LENGTH: 15.0,
            Ad.POD_POSITION: 1
        ]

        let expectedAdParams2: [String: Any] = [
            Ad.ID: "adID2",
            Ad.NAME: "adName2",
            Ad.LENGTH: 20.0,
            Ad.POD_POSITION: 2
        ]

        let expectedHits: [MediaHit] = [
            MediaHit(eventType: EventType.SESSION_START, playhead: 0, ts: 0, params: expectedSessionStartParams, customMetadata: mediaMetadata),
            MediaHit(eventType: EventType.ADBREAK_START, playhead: 0, ts: 0, params: expectedAdBreakStartParams),
            MediaHit(eventType: EventType.AD_START, playhead: 0, ts: 0, params: expectedAdParams, customMetadata: adMetadata),
            MediaHit(eventType: EventType.PLAY, playhead: 0, ts: 0),
            MediaHit(eventType: EventType.PING, playhead: 0, ts: 50000),
            MediaHit(eventType: EventType.AD_COMPLETE, playhead: 0, ts: 55000),
            MediaHit(eventType: EventType.AD_START, playhead: 0, ts: 55000, params: expectedAdParams2, customMetadata: adMetadata2),
            MediaHit(eventType: EventType.PLAY, playhead: 0, ts: 55000),
            MediaHit(eventType: EventType.PING, playhead: 0, ts: 105000),
            MediaHit(eventType: EventType.AD_COMPLETE, playhead: 0, ts: 110000),
            MediaHit(eventType: EventType.ADBREAK_COMPLETE, playhead: 0, ts: 110000),
            MediaHit(eventType: EventType.PLAY, playhead: 0, ts: 110000),
            MediaHit(eventType: EventType.PLAY, playhead: 1, ts: 111000),
            MediaHit(eventType: EventType.PING, playhead: 51, ts: 161000),
            MediaHit(eventType: EventType.ADBREAK_START, playhead: 55, ts: 165000, params: expectedAdBreakStartParams2),
            MediaHit(eventType: EventType.AD_START, playhead: 55, ts: 165000, params: expectedAdParams, customMetadata: adMetadata),
            MediaHit(eventType: EventType.PLAY, playhead: 55, ts: 165000),
            MediaHit(eventType: EventType.PING, playhead: 55, ts: 215000),
            MediaHit(eventType: EventType.AD_COMPLETE, playhead: 55, ts: 220000),
            MediaHit(eventType: EventType.AD_START, playhead: 55, ts: 220000, params: expectedAdParams2, customMetadata: adMetadata2),
            MediaHit(eventType: EventType.PLAY, playhead: 55, ts: 220000),
            MediaHit(eventType: EventType.PING, playhead: 55, ts: 270000),
            MediaHit(eventType: EventType.AD_COMPLETE, playhead: 55, ts: 275000),
            MediaHit(eventType: EventType.ADBREAK_COMPLETE, playhead: 55, ts: 275000),
            MediaHit(eventType: EventType.PLAY, playhead: 55, ts: 275000),
            MediaHit(eventType: EventType.SESSION_COMPLETE, playhead: 55, ts: 275000)
        ]

        // verify
        checkHits(expectedHits: expectedHits)
    }
}
