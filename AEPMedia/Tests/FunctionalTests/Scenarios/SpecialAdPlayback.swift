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

@testable import AEPMedia

class SpecialAdPlayback: BaseScenarioTest {
    private typealias EventType = MediaConstants.MediaCollection.EventType
    private typealias Media = MediaConstants.MediaCollection.Media
    private typealias AdBreak = MediaConstants.MediaCollection.AdBreak
    private typealias Ad = MediaConstants.MediaCollection.Ad
    private typealias Chapter = MediaConstants.MediaCollection.Chapter

    static let mediaInfo = MediaInfo(id: "mediaID", name: "mediaName", streamType: "aod", mediaType: MediaType.Audio, length: 30.0, prerollWaitingTime: 0)!
    static let mediaInfoWithDefaultPreroll = MediaInfo(id: "mediaID", name: "mediaName", streamType: "aod", mediaType: MediaType.Audio, length: 30.0)!
    static let mediaInfoWithDefaultPrerollAndGranularTracking = MediaInfo(id: "mediaID", name: "mediaName", streamType: "aod", mediaType: MediaType.Audio, length: 30.0, granularAdTracking: true)!
    static let mediaMetadata = ["media.show": "sampleshow", "key1": "value1", "key2": "мểŧẳđαţả"]

    static let adBreakInfo = AdBreakInfo(name: "adBreakName", position: 1, startTime: 1.1)!
    static let adBreakInfo2 = AdBreakInfo(name: "adBreakName2", position: 2, startTime: 2.2)!

    static let adInfo = AdInfo(id: "adID", name: "adName", position: 1, length: 15.0)!
    static let adMetadata = ["media.ad.advertiser": "sampleAdvertiser", "key1": "value1", "key2": "мểŧẳđαţả"]

    static let adInfo2 = AdInfo(id: "adID2", name: "adName2", position: 2, length: 20.0)!
    static let adMetadata2 = ["media.ad.advertiser": "sampleAdvertiser2", "key2": "value2", "key3": "мểŧẳđαţả"]

    static let chapterInfo = ChapterInfo(name: "chapterName", position: 1, startTime: 1.1, length: 30)!
    static let chapterMetadata = ["media.artist": "sampleArtist", "key1": "value1", "key2": "мểŧẳđαţả"]

    static let chapterInfo2 = ChapterInfo(name: "chapterName2", position: 2, startTime: 2.2, length: 40)!
    static let chapterMetadata2 = ["media.artist": "sampleArtist2", "key2": "value2", "key3": "мểŧẳđαţả"]

    // Expected Values
    static let expectedSessionStartParamsRealTime: [String: Any]  = [
        Media.ID: "mediaID",
        Media.NAME: "mediaName",
        Media.LENGTH: 30.0,
        Media.CONTENT_TYPE: "aod",
        Media.STREAM_TYPE: "audio",
        Media.RESUME: false,
        Media.DOWNLOADED: false,
    ]

    static let expectedSessionStartParamsDownloaded: [String: Any]  = [
        Media.ID: "mediaID",
        Media.NAME: "mediaName",
        Media.LENGTH: 30.0,
        Media.CONTENT_TYPE: "aod",
        Media.STREAM_TYPE: "audio",
        Media.RESUME: false,
        Media.DOWNLOADED: true,
    ]

    static let expectedAdBreakStartParams: [String: Any] = [
        AdBreak.POD_FRIENDLY_NAME: "adBreakName",
        AdBreak.POD_INDEX: 1,
        AdBreak.POD_SECOND: 1.1
    ]

    static let expectedAdBreakStartParams2: [String: Any] = [
        AdBreak.POD_FRIENDLY_NAME: "adBreakName2",
        AdBreak.POD_INDEX: 2,
        AdBreak.POD_SECOND: 2.2
    ]

    static let expectedAdParams: [String: Any] = [
        Ad.ID: "adID",
        Ad.NAME: "adName",
        Ad.LENGTH: 15.0,
        Ad.POD_POSITION: 1
    ]

    static let expectedAdParams2: [String: Any] = [
        Ad.ID: "adID2",
        Ad.NAME: "adName2",
        Ad.LENGTH: 20.0,
        Ad.POD_POSITION: 2
    ]

    static let expectedChapterStartParams: [String: Any] = [
        Chapter.FRIENDLY_NAME: "chapterName",
        Chapter.INDEX: 1,
        Chapter.LENGTH: 30,
        Chapter.OFFSET: 1.1
    ]

    static let expectedChapterStartParams2: [String: Any] = [
        Chapter.FRIENDLY_NAME: "chapterName2",
        Chapter.INDEX: 2,
        Chapter.LENGTH: 40,
        Chapter.OFFSET: 2.2
    ]

    override func setUp() {
        super.setup()
    }

    // tests
    func testDelayedAds_RealTimeTracker() {
        // test
        mediaTracker.trackSessionStart(info: Self.mediaInfoWithDefaultPreroll.toMap(), metadata: Self.mediaMetadata)
        mediaTracker.trackEvent(event: MediaEvent.AdBreakStart, info: Self.adBreakInfo.toMap())
        waitFor(time: 15000, updatePlayhead: false)
        mediaTracker.trackEvent(event: MediaEvent.AdStart, info: Self.adInfo.toMap(), metadata: Self.adMetadata)
        waitFor(time: 15000, updatePlayhead: false)
        mediaTracker.trackEvent(event: MediaEvent.AdComplete)
        mediaTracker.trackEvent(event: MediaEvent.AdBreakComplete)
        // should switch to play state
        mediaTracker.trackEvent(event: MediaEvent.ChapterStart, info: Self.chapterInfo.toMap())
        waitFor(time: 15000, updatePlayhead: true)
        mediaTracker.trackEvent(event: MediaEvent.ChapterComplete)
        mediaTracker.trackEvent(event: MediaEvent.AdBreakStart, info: Self.adBreakInfo2.toMap())
        waitFor(time: 25000, updatePlayhead: false)
        mediaTracker.trackEvent(event: MediaEvent.AdStart, info: Self.adInfo2.toMap(), metadata: Self.adMetadata2)
        waitFor(time: 15000, updatePlayhead: false)
        mediaTracker.trackEvent(event: MediaEvent.AdComplete)
        mediaTracker.trackEvent(event: MediaEvent.AdBreakComplete)
        mediaTracker.trackComplete()

        let expectedHits: [MediaHit] = [
            MediaHit(eventType: EventType.SESSION_START, playhead: 0, ts: 0, params: Self.expectedSessionStartParamsRealTime, customMetadata: Self.mediaMetadata),

            MediaHit(eventType: EventType.ADBREAK_START, playhead: 0, ts: 0, params: Self.expectedAdBreakStartParams),
            MediaHit(eventType: EventType.PING, playhead: 0, ts: 10000),
            MediaHit(eventType: EventType.AD_START, playhead: 0, ts: 15000, params: Self.expectedAdParams, customMetadata: Self.adMetadata),
            MediaHit(eventType: EventType.PLAY, playhead: 0, ts: 15000),
            MediaHit(eventType: EventType.PING, playhead: 0, ts: 25000),
            MediaHit(eventType: EventType.AD_COMPLETE, playhead: 0, ts: 30000),
            MediaHit(eventType: EventType.ADBREAK_COMPLETE, playhead: 0, ts: 30000),

            MediaHit(eventType: EventType.PLAY, playhead: 0, ts: 30000),

            MediaHit(eventType: EventType.CHAPTER_START, playhead: 0, ts: 30000, params: Self.expectedChapterStartParams),
            MediaHit(eventType: EventType.PLAY, playhead: 1, ts: 31000),
            MediaHit(eventType: EventType.PING, playhead: 11, ts: 41000),
            MediaHit(eventType: EventType.CHAPTER_COMPLETE, playhead: 15, ts: 45000),

            MediaHit(eventType: EventType.ADBREAK_START, playhead: 15, ts: 45000, params: Self.expectedAdBreakStartParams2),
            MediaHit(eventType: EventType.PING, playhead: 15, ts: 51000),
            MediaHit(eventType: EventType.PING, playhead: 15, ts: 61000),
            MediaHit(eventType: EventType.AD_START, playhead: 15, ts: 70000, params: Self.expectedAdParams2, customMetadata: Self.adMetadata2),
            MediaHit(eventType: EventType.PLAY, playhead: 15, ts: 70000),
            MediaHit(eventType: EventType.PING, playhead: 15, ts: 80000),
            MediaHit(eventType: EventType.AD_COMPLETE, playhead: 15, ts: 85000),
            MediaHit(eventType: EventType.ADBREAK_COMPLETE, playhead: 15, ts: 85000),

            MediaHit(eventType: EventType.PLAY, playhead: 15, ts: 85000),
            MediaHit(eventType: EventType.SESSION_COMPLETE, playhead: 15, ts: 85000)
        ]

        // verify
        checkHits(expectedHits: expectedHits)
    }

    func testDelayedAds_DownloadedTracker() {
        // setup
        createTracker(downloaded: true)

        // test
        mediaTracker.trackSessionStart(info: Self.mediaInfoWithDefaultPreroll.toMap(), metadata: Self.mediaMetadata)
        mediaTracker.trackEvent(event: MediaEvent.AdBreakStart, info: Self.adBreakInfo.toMap())
        waitFor(time: 55000, updatePlayhead: false)
        mediaTracker.trackEvent(event: MediaEvent.AdStart, info: Self.adInfo.toMap(), metadata: Self.adMetadata)
        waitFor(time: 55000, updatePlayhead: false)
        mediaTracker.trackEvent(event: MediaEvent.AdComplete)
        mediaTracker.trackEvent(event: MediaEvent.AdBreakComplete)
        // should switch to play state
        mediaTracker.trackEvent(event: MediaEvent.ChapterStart, info: Self.chapterInfo.toMap())
        waitFor(time: 15000, updatePlayhead: true)
        mediaTracker.trackEvent(event: MediaEvent.ChapterComplete)
        mediaTracker.trackEvent(event: MediaEvent.AdBreakStart, info: Self.adBreakInfo2.toMap())
        waitFor(time: 55000, updatePlayhead: false)
        mediaTracker.trackEvent(event: MediaEvent.AdStart, info: Self.adInfo2.toMap(), metadata: Self.adMetadata2)
        waitFor(time: 15000, updatePlayhead: false)
        mediaTracker.trackEvent(event: MediaEvent.AdComplete)
        mediaTracker.trackEvent(event: MediaEvent.AdBreakComplete)
        mediaTracker.trackComplete()

        let expectedHits: [MediaHit] = [
            MediaHit(eventType: EventType.SESSION_START, playhead: 0, ts: 0, params: Self.expectedSessionStartParamsDownloaded, customMetadata: Self.mediaMetadata),
            MediaHit(eventType: EventType.ADBREAK_START, playhead: 0, ts: 0, params: Self.expectedAdBreakStartParams),
            MediaHit(eventType: EventType.PING, playhead: 0, ts: 50000),
            MediaHit(eventType: EventType.AD_START, playhead: 0, ts: 55000, params: Self.expectedAdParams, customMetadata: Self.adMetadata),
            MediaHit(eventType: EventType.PLAY, playhead: 0, ts: 55000),
            MediaHit(eventType: EventType.PING, playhead: 0, ts: 105000),
            MediaHit(eventType: EventType.AD_COMPLETE, playhead: 0, ts: 110000),
            MediaHit(eventType: EventType.ADBREAK_COMPLETE, playhead: 0, ts: 110000),
            MediaHit(eventType: EventType.PLAY, playhead: 0, ts: 110000),
            MediaHit(eventType: EventType.CHAPTER_START, playhead: 0, ts: 110000, params: Self.expectedChapterStartParams),
            MediaHit(eventType: EventType.PLAY, playhead: 1, ts: 111000),
            MediaHit(eventType: EventType.CHAPTER_COMPLETE, playhead: 15, ts: 125000),

            MediaHit(eventType: EventType.ADBREAK_START, playhead: 15, ts: 125000, params: Self.expectedAdBreakStartParams2),
            MediaHit(eventType: EventType.PING, playhead: 15, ts: 161000),
            MediaHit(eventType: EventType.AD_START, playhead: 15, ts: 180000, params: Self.expectedAdParams2, customMetadata: Self.adMetadata2),
            MediaHit(eventType: EventType.PLAY, playhead: 15, ts: 180000),
            MediaHit(eventType: EventType.AD_COMPLETE, playhead: 15, ts: 195000),
            MediaHit(eventType: EventType.ADBREAK_COMPLETE, playhead: 15, ts: 195000),

            MediaHit(eventType: EventType.PLAY, playhead: 15, ts: 195000),
            MediaHit(eventType: EventType.SESSION_COMPLETE, playhead: 15, ts: 195000)
        ]

        // verify
        checkHits(expectedHits: expectedHits)
    }

    func testAdWithSeek_RealTimeTracker() {
        // test
        mediaTracker.trackSessionStart(info: Self.mediaInfoWithDefaultPreroll.toMap(), metadata: Self.mediaMetadata)
        mediaTracker.trackEvent(event: MediaEvent.AdBreakStart, info: Self.adBreakInfo.toMap())
        mediaTracker.trackEvent(event: MediaEvent.AdStart, info: Self.adInfo.toMap(), metadata: Self.adMetadata)
        waitFor(time: 5000, updatePlayhead: false)
        // seek out of ad into main content chapter
        mediaTracker.trackEvent(event: MediaEvent.SeekStart)
        mediaTracker.incrementTimeStamp(value: 1000)
        mediaTracker.incrementCurrentPlayhead(time: 5)
        mediaTracker.trackEvent(event: MediaEvent.SeekComplete)
        mediaTracker.trackEvent(event: MediaEvent.AdSkip)
        mediaTracker.trackEvent(event: MediaEvent.AdBreakComplete)
        // should switch to play state
        mediaTracker.trackEvent(event: MediaEvent.ChapterStart, info: Self.chapterInfo.toMap())
        waitFor(time: 15000, updatePlayhead: true)
        // seek out of chapter into Ad
        mediaTracker.trackEvent(event: MediaEvent.SeekStart)
        mediaTracker.incrementTimeStamp(value: 1000)
        mediaTracker.incrementCurrentPlayhead(time: 5)
        mediaTracker.trackEvent(event: MediaEvent.ChapterSkip)
        mediaTracker.trackEvent(event: MediaEvent.SeekComplete)
        mediaTracker.trackEvent(event: MediaEvent.AdBreakStart, info: Self.adBreakInfo2.toMap())
        mediaTracker.trackEvent(event: MediaEvent.AdStart, info: Self.adInfo2.toMap(), metadata: Self.adMetadata2)
        waitFor(time: 15000, updatePlayhead: false)
        mediaTracker.trackSessionEnd()

        let expectedHits: [MediaHit] = [
            MediaHit(eventType: EventType.SESSION_START, playhead: 0, ts: 0, params: Self.expectedSessionStartParamsRealTime, customMetadata: Self.mediaMetadata),

            MediaHit(eventType: EventType.ADBREAK_START, playhead: 0, ts: 0, params: Self.expectedAdBreakStartParams),
            MediaHit(eventType: EventType.AD_START, playhead: 0, ts: 0, params: Self.expectedAdParams, customMetadata: Self.adMetadata),
            MediaHit(eventType: EventType.PLAY, playhead: 0, ts: 0),
            MediaHit(eventType: EventType.PAUSE_START, playhead: 0, ts: 5000),
            MediaHit(eventType: EventType.PLAY, playhead: 5, ts: 6000),
            MediaHit(eventType: EventType.AD_SKIP, playhead: 5, ts: 6000),
            MediaHit(eventType: EventType.ADBREAK_COMPLETE, playhead: 5, ts: 6000),

            MediaHit(eventType: EventType.PLAY, playhead: 5, ts: 6000),

            MediaHit(eventType: EventType.CHAPTER_START, playhead: 5, ts: 6000, params: Self.expectedChapterStartParams),
            MediaHit(eventType: EventType.PLAY, playhead: 6, ts: 7000),
            MediaHit(eventType: EventType.PING, playhead: 16, ts: 17000),
            MediaHit(eventType: EventType.PAUSE_START, playhead: 20, ts: 21000),
            MediaHit(eventType: EventType.CHAPTER_SKIP, playhead: 25, ts: 22000),
            MediaHit(eventType: EventType.PLAY, playhead: 25, ts: 22000),

            MediaHit(eventType: EventType.ADBREAK_START, playhead: 25, ts: 22000, params: Self.expectedAdBreakStartParams2),
            MediaHit(eventType: EventType.AD_START, playhead: 25, ts: 22000, params: Self.expectedAdParams2, customMetadata: Self.adMetadata2),
            MediaHit(eventType: EventType.PLAY, playhead: 25, ts: 22000),
            MediaHit(eventType: EventType.PING, playhead: 25, ts: 32000),
            MediaHit(eventType: EventType.AD_SKIP, playhead: 25, ts: 37000),
            MediaHit(eventType: EventType.ADBREAK_COMPLETE, playhead: 25, ts: 37000),
            MediaHit(eventType: EventType.SESSION_END, playhead: 25, ts: 37000)
        ]

        // verify
        checkHits(expectedHits: expectedHits)
    }

    func testAdWithBuffer_RealtimeTracker() {
        // test
        mediaTracker.trackSessionStart(info: Self.mediaInfoWithDefaultPreroll.toMap(), metadata: Self.mediaMetadata)
        mediaTracker.trackEvent(event: MediaEvent.BufferStart)
        waitFor(time: 5000, updatePlayhead: false)
        mediaTracker.trackEvent(event: MediaEvent.BufferComplete)
        mediaTracker.trackEvent(event: MediaEvent.AdBreakStart, info: Self.adBreakInfo.toMap())
        mediaTracker.trackEvent(event: MediaEvent.BufferStart)
        waitFor(time: 5000, updatePlayhead: false)
        mediaTracker.trackEvent(event: MediaEvent.BufferComplete)
        mediaTracker.trackEvent(event: MediaEvent.AdStart, info: Self.adInfo.toMap(), metadata: Self.adMetadata)
        waitFor(time: 15000, updatePlayhead: false)
        mediaTracker.trackEvent(event: MediaEvent.BufferStart)
        waitFor(time: 5000, updatePlayhead: false)
        mediaTracker.trackEvent(event: MediaEvent.BufferComplete)
        waitFor(time: 5000, updatePlayhead: false)
        mediaTracker.trackEvent(event: MediaEvent.AdComplete)
        mediaTracker.trackEvent(event: MediaEvent.AdBreakComplete)
        mediaTracker.trackPlay()
        waitFor(time: 5000, updatePlayhead: true)
        mediaTracker.trackComplete()

        let expectedHits: [MediaHit] = [
            MediaHit(eventType: EventType.SESSION_START, playhead: 0, ts: 0, params: Self.expectedSessionStartParamsRealTime, customMetadata: Self.mediaMetadata),
            MediaHit(eventType: EventType.BUFFER_START, playhead: 0, ts: 0),
            MediaHit(eventType: EventType.PAUSE_START, playhead: 0, ts: 5000),
            MediaHit(eventType: EventType.ADBREAK_START, playhead: 0, ts: 5000, params: Self.expectedAdBreakStartParams),
            MediaHit(eventType: EventType.AD_START, playhead: 0, ts: 10000, params: Self.expectedAdParams, customMetadata: Self.adMetadata),
            MediaHit(eventType: EventType.PAUSE_START, playhead: 0, ts: 10000),
            MediaHit(eventType: EventType.PING, playhead: 0, ts: 20000),
            MediaHit(eventType: EventType.BUFFER_START, playhead: 0, ts: 25000),
            MediaHit(eventType: EventType.PAUSE_START, playhead: 0, ts: 30000),
            MediaHit(eventType: EventType.AD_COMPLETE, playhead: 0, ts: 35000),
            MediaHit(eventType: EventType.ADBREAK_COMPLETE, playhead: 0, ts: 35000),
            MediaHit(eventType: EventType.PAUSE_START, playhead: 0, ts: 35000),
            MediaHit(eventType: EventType.PLAY, playhead: 0, ts: 35000),
            MediaHit(eventType: EventType.PLAY, playhead: 1, ts: 36000),
            MediaHit(eventType: EventType.SESSION_COMPLETE, playhead: 5, ts: 40000)
        ]

        // verify
        checkHits(expectedHits: expectedHits)
    }

    func testAdWithBuffer_DownloadedTracker() {
        // setup
        createTracker(downloaded: true)

        // test
        mediaTracker.trackSessionStart(info: Self.mediaInfoWithDefaultPreroll.toMap(), metadata: Self.mediaMetadata)
        mediaTracker.trackEvent(event: MediaEvent.BufferStart)
        waitFor(time: 5000, updatePlayhead: false)
        mediaTracker.trackEvent(event: MediaEvent.BufferComplete)
        mediaTracker.trackEvent(event: MediaEvent.AdBreakStart, info: Self.adBreakInfo.toMap())
        mediaTracker.trackEvent(event: MediaEvent.BufferStart)
        waitFor(time: 5000, updatePlayhead: false)
        mediaTracker.trackEvent(event: MediaEvent.BufferComplete)
        mediaTracker.trackEvent(event: MediaEvent.AdStart, info: Self.adInfo.toMap(), metadata: Self.adMetadata)
        waitFor(time: 15000, updatePlayhead: false)
        mediaTracker.trackEvent(event: MediaEvent.BufferStart)
        waitFor(time: 5000, updatePlayhead: false)
        mediaTracker.trackEvent(event: MediaEvent.BufferComplete)
        waitFor(time: 5000, updatePlayhead: false)
        mediaTracker.trackEvent(event: MediaEvent.AdComplete)
        mediaTracker.trackEvent(event: MediaEvent.AdBreakComplete)
        mediaTracker.trackPlay()
        waitFor(time: 5000, updatePlayhead: true)
        mediaTracker.trackComplete()

        let expectedHits: [MediaHit] = [
            MediaHit(eventType: EventType.SESSION_START, playhead: 0, ts: 0, params: Self.expectedSessionStartParamsDownloaded, customMetadata: Self.mediaMetadata),
            MediaHit(eventType: EventType.BUFFER_START, playhead: 0, ts: 0),
            MediaHit(eventType: EventType.PAUSE_START, playhead: 0, ts: 5000),
            MediaHit(eventType: EventType.ADBREAK_START, playhead: 0, ts: 5000, params: Self.expectedAdBreakStartParams),
            MediaHit(eventType: EventType.AD_START, playhead: 0, ts: 10000, params: Self.expectedAdParams, customMetadata: Self.adMetadata),
            MediaHit(eventType: EventType.PAUSE_START, playhead: 0, ts: 10000),
            MediaHit(eventType: EventType.BUFFER_START, playhead: 0, ts: 25000),
            MediaHit(eventType: EventType.PAUSE_START, playhead: 0, ts: 30000),
            MediaHit(eventType: EventType.AD_COMPLETE, playhead: 0, ts: 35000),
            MediaHit(eventType: EventType.ADBREAK_COMPLETE, playhead: 0, ts: 35000),
            MediaHit(eventType: EventType.PAUSE_START, playhead: 0, ts: 35000),
            MediaHit(eventType: EventType.PLAY, playhead: 0, ts: 35000),
            MediaHit(eventType: EventType.PLAY, playhead: 1, ts: 36000),
            MediaHit(eventType: EventType.SESSION_COMPLETE, playhead: 5, ts: 40000)
        ]

        // verify
        checkHits(expectedHits: expectedHits)
    }
}
