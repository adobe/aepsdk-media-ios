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

class AdChapterPlayback: BaseScenarioTest {
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
    func testMultipleAdChapter_RealTimeTracker() {
        // test
        mediaTracker.trackSessionStart(info: Self.mediaInfoWithDefaultPreroll.toMap(), metadata: Self.mediaMetadata)
        mediaTracker.trackEvent(event: MediaEvent.AdBreakStart, info: Self.adBreakInfo.toMap())
        mediaTracker.trackEvent(event: MediaEvent.AdStart, info: Self.adInfo.toMap(), metadata: Self.adMetadata)
        waitFor(time: 15000, updatePlayhead: false)
        mediaTracker.trackEvent(event: MediaEvent.AdComplete)
        mediaTracker.trackEvent(event: MediaEvent.AdBreakComplete)
        // should switch to play state
        mediaTracker.trackEvent(event: MediaEvent.ChapterStart, info: Self.chapterInfo.toMap())
        waitFor(time: 15000, updatePlayhead: true)
        mediaTracker.trackEvent(event: MediaEvent.ChapterComplete)
        mediaTracker.trackEvent(event: MediaEvent.ChapterStart, info: Self.chapterInfo2.toMap())
        waitFor(time: 15000, updatePlayhead: true)
        mediaTracker.trackEvent(event: MediaEvent.ChapterComplete)
        mediaTracker.trackEvent(event: MediaEvent.AdBreakStart, info: Self.adBreakInfo2.toMap())
        mediaTracker.trackEvent(event: MediaEvent.AdStart, info: Self.adInfo2.toMap(), metadata: Self.adMetadata2)
        waitFor(time: 15000, updatePlayhead: false)
        mediaTracker.trackEvent(event: MediaEvent.AdComplete)
        mediaTracker.trackEvent(event: MediaEvent.AdBreakComplete)
        mediaTracker.trackComplete()

        let expectedHits: [MediaHit] = [
            MediaHit(eventType: EventType.SESSION_START, playhead: 0, ts: 0, params: Self.expectedSessionStartParamsRealTime, customMetadata: Self.mediaMetadata),

            MediaHit(eventType: EventType.ADBREAK_START, playhead: 0, ts: 0, params: Self.expectedAdBreakStartParams),
            MediaHit(eventType: EventType.AD_START, playhead: 0, ts: 0, params: Self.expectedAdParams, customMetadata: Self.adMetadata),
            MediaHit(eventType: EventType.PLAY, playhead: 0, ts: 0),
            MediaHit(eventType: EventType.PING, playhead: 0, ts: 10000),
            MediaHit(eventType: EventType.AD_COMPLETE, playhead: 0, ts: 15000),
            MediaHit(eventType: EventType.ADBREAK_COMPLETE, playhead: 0, ts: 15000),

            MediaHit(eventType: EventType.PLAY, playhead: 0, ts: 15000),

            MediaHit(eventType: EventType.CHAPTER_START, playhead: 0, ts: 15000, params: Self.expectedChapterStartParams),
            MediaHit(eventType: EventType.PLAY, playhead: 1, ts: 16000),
            MediaHit(eventType: EventType.PING, playhead: 11, ts: 26000),
            MediaHit(eventType: EventType.CHAPTER_COMPLETE, playhead: 15, ts: 30000),
            MediaHit(eventType: EventType.CHAPTER_START, playhead: 15, ts: 30000, params: Self.expectedChapterStartParams2),
            MediaHit(eventType: EventType.PING, playhead: 21, ts: 36000),
            MediaHit(eventType: EventType.CHAPTER_COMPLETE, playhead: 30, ts: 45000),

            MediaHit(eventType: EventType.ADBREAK_START, playhead: 30, ts: 45000, params: Self.expectedAdBreakStartParams2),
            MediaHit(eventType: EventType.AD_START, playhead: 30, ts: 45000, params: Self.expectedAdParams2, customMetadata: Self.adMetadata2),
            MediaHit(eventType: EventType.PLAY, playhead: 30, ts: 45000),
            MediaHit(eventType: EventType.PING, playhead: 30, ts: 55000),
            MediaHit(eventType: EventType.AD_COMPLETE, playhead: 30, ts: 60000),
            MediaHit(eventType: EventType.ADBREAK_COMPLETE, playhead: 30, ts: 60000),

            MediaHit(eventType: EventType.PLAY, playhead: 30, ts: 60000),
            MediaHit(eventType: EventType.SESSION_COMPLETE, playhead: 30, ts: 60000)
        ]

        // verify
        checkHits(expectedHits: expectedHits)
    }

    func testMultipleAdChapter_GranularAdTracking_RealTimeTracker() {
        // test
        mediaTracker.trackSessionStart(info: Self.mediaInfoWithDefaultPrerollAndGranularTracking.toMap(), metadata: Self.mediaMetadata)
        mediaTracker.trackEvent(event: MediaEvent.AdBreakStart, info: Self.adBreakInfo.toMap())
        mediaTracker.trackEvent(event: MediaEvent.AdStart, info: Self.adInfo.toMap(), metadata: Self.adMetadata)
        waitFor(time: 5000, updatePlayhead: false)
        mediaTracker.trackEvent(event: MediaEvent.AdComplete)
        mediaTracker.trackEvent(event: MediaEvent.AdBreakComplete)
        // should switch to play state
        mediaTracker.trackEvent(event: MediaEvent.ChapterStart, info: Self.chapterInfo.toMap())
        waitFor(time: 15000, updatePlayhead: true)
        mediaTracker.trackEvent(event: MediaEvent.ChapterComplete)
        mediaTracker.trackEvent(event: MediaEvent.ChapterStart, info: Self.chapterInfo2.toMap())
        waitFor(time: 15000, updatePlayhead: true)
        mediaTracker.trackEvent(event: MediaEvent.ChapterComplete)
        mediaTracker.trackEvent(event: MediaEvent.AdBreakStart, info: Self.adBreakInfo2.toMap())
        mediaTracker.trackEvent(event: MediaEvent.AdStart, info: Self.adInfo2.toMap(), metadata: Self.adMetadata2)
        waitFor(time: 5000, updatePlayhead: false)
        mediaTracker.trackEvent(event: MediaEvent.AdComplete)
        mediaTracker.trackEvent(event: MediaEvent.AdBreakComplete)
        mediaTracker.trackComplete()

        let expectedHits: [MediaHit] = [
            MediaHit(eventType: EventType.SESSION_START, playhead: 0, ts: 0, params: Self.expectedSessionStartParamsRealTime, customMetadata: Self.mediaMetadata),

            MediaHit(eventType: EventType.ADBREAK_START, playhead: 0, ts: 0, params: Self.expectedAdBreakStartParams),
            MediaHit(eventType: EventType.AD_START, playhead: 0, ts: 0, params: Self.expectedAdParams, customMetadata: Self.adMetadata),
            MediaHit(eventType: EventType.PLAY, playhead: 0, ts: 0),
            MediaHit(eventType: EventType.PING, playhead: 0, ts: 1000),
            MediaHit(eventType: EventType.PING, playhead: 0, ts: 2000),
            MediaHit(eventType: EventType.PING, playhead: 0, ts: 3000),
            MediaHit(eventType: EventType.PING, playhead: 0, ts: 4000),
            MediaHit(eventType: EventType.PING, playhead: 0, ts: 5000),
            MediaHit(eventType: EventType.AD_COMPLETE, playhead: 0, ts: 5000),
            MediaHit(eventType: EventType.ADBREAK_COMPLETE, playhead: 0, ts: 5000),

            MediaHit(eventType: EventType.PLAY, playhead: 0, ts: 5000),

            MediaHit(eventType: EventType.CHAPTER_START, playhead: 0, ts: 5000, params: Self.expectedChapterStartParams),
            MediaHit(eventType: EventType.PLAY, playhead: 1, ts: 6000),
            MediaHit(eventType: EventType.PING, playhead: 11, ts: 16000),
            MediaHit(eventType: EventType.CHAPTER_COMPLETE, playhead: 15, ts: 20000),
            MediaHit(eventType: EventType.CHAPTER_START, playhead: 15, ts: 20000, params: Self.expectedChapterStartParams2),
            MediaHit(eventType: EventType.PING, playhead: 21, ts: 26000),
            MediaHit(eventType: EventType.CHAPTER_COMPLETE, playhead: 30, ts: 35000),

            MediaHit(eventType: EventType.ADBREAK_START, playhead: 30, ts: 35000, params: Self.expectedAdBreakStartParams2),
            MediaHit(eventType: EventType.AD_START, playhead: 30, ts: 35000, params: Self.expectedAdParams2, customMetadata: Self.adMetadata2),
            MediaHit(eventType: EventType.PLAY, playhead: 30, ts: 35000),
            MediaHit(eventType: EventType.PING, playhead: 30, ts: 36000),
            MediaHit(eventType: EventType.PING, playhead: 30, ts: 37000),
            MediaHit(eventType: EventType.PING, playhead: 30, ts: 38000),
            MediaHit(eventType: EventType.PING, playhead: 30, ts: 39000),
            MediaHit(eventType: EventType.PING, playhead: 30, ts: 40000),
            MediaHit(eventType: EventType.AD_COMPLETE, playhead: 30, ts: 40000),
            MediaHit(eventType: EventType.ADBREAK_COMPLETE, playhead: 30, ts: 40000),

            MediaHit(eventType: EventType.PLAY, playhead: 30, ts: 40000),
            MediaHit(eventType: EventType.SESSION_COMPLETE, playhead: 30, ts: 40000)
        ]

        // verify
        checkHits(expectedHits: expectedHits)
    }

    func testMultipleAdChapter_DownloadedTracker() {
        // setup
        createTracker(downloaded: true)

        // test
        mediaTracker.trackSessionStart(info: Self.mediaInfoWithDefaultPreroll.toMap(), metadata: Self.mediaMetadata)
        mediaTracker.trackEvent(event: MediaEvent.AdBreakStart, info: Self.adBreakInfo.toMap())
        mediaTracker.trackEvent(event: MediaEvent.AdStart, info: Self.adInfo.toMap(), metadata: Self.adMetadata)
        waitFor(time: 55000, updatePlayhead: false)
        mediaTracker.trackEvent(event: MediaEvent.AdComplete)
        mediaTracker.trackEvent(event: MediaEvent.AdBreakComplete)
        // should switch to play state
        mediaTracker.trackEvent(event: MediaEvent.ChapterStart, info: Self.chapterInfo.toMap())
        waitFor(time: 55000, updatePlayhead: true)
        mediaTracker.trackEvent(event: MediaEvent.ChapterComplete)
        mediaTracker.trackEvent(event: MediaEvent.ChapterStart, info: Self.chapterInfo2.toMap())
        waitFor(time: 55000, updatePlayhead: true)
        mediaTracker.trackEvent(event: MediaEvent.ChapterComplete)
        mediaTracker.trackEvent(event: MediaEvent.AdBreakStart, info: Self.adBreakInfo2.toMap())
        mediaTracker.trackEvent(event: MediaEvent.AdStart, info: Self.adInfo2.toMap(), metadata: Self.adMetadata2)
        waitFor(time: 55000, updatePlayhead: false)
        mediaTracker.trackEvent(event: MediaEvent.AdComplete)
        mediaTracker.trackEvent(event: MediaEvent.AdBreakComplete)
        mediaTracker.trackComplete()

        // verify
        let expectedHits: [MediaHit] = [
            MediaHit(eventType: EventType.SESSION_START, playhead: 0, ts: 0, params: Self.expectedSessionStartParamsDownloaded, customMetadata: Self.mediaMetadata),

            MediaHit(eventType: EventType.ADBREAK_START, playhead: 0, ts: 0, params: Self.expectedAdBreakStartParams),
            MediaHit(eventType: EventType.AD_START, playhead: 0, ts: 0, params: Self.expectedAdParams, customMetadata: Self.adMetadata),
            MediaHit(eventType: EventType.PLAY, playhead: 0, ts: 0),
            MediaHit(eventType: EventType.PING, playhead: 0, ts: 50000),
            MediaHit(eventType: EventType.AD_COMPLETE, playhead: 0, ts: 55000),
            MediaHit(eventType: EventType.ADBREAK_COMPLETE, playhead: 0, ts: 55000),

            MediaHit(eventType: EventType.PLAY, playhead: 0, ts: 55000),

            MediaHit(eventType: EventType.CHAPTER_START, playhead: 0, ts: 55000, params: Self.expectedChapterStartParams),
            MediaHit(eventType: EventType.PLAY, playhead: 1, ts: 56000),
            MediaHit(eventType: EventType.PING, playhead: 51, ts: 106000),
            MediaHit(eventType: EventType.CHAPTER_COMPLETE, playhead: 55, ts: 110000),
            MediaHit(eventType: EventType.CHAPTER_START, playhead: 55, ts: 110000, params: Self.expectedChapterStartParams2),
            MediaHit(eventType: EventType.PING, playhead: 101, ts: 156000),
            MediaHit(eventType: EventType.CHAPTER_COMPLETE, playhead: 110, ts: 165000),

            MediaHit(eventType: EventType.ADBREAK_START, playhead: 110, ts: 165000, params: Self.expectedAdBreakStartParams2),
            MediaHit(eventType: EventType.AD_START, playhead: 110, ts: 165000, params: Self.expectedAdParams2, customMetadata: Self.adMetadata2),
            MediaHit(eventType: EventType.PLAY, playhead: 110, ts: 165000),
            MediaHit(eventType: EventType.PING, playhead: 110, ts: 215000),
            MediaHit(eventType: EventType.AD_COMPLETE, playhead: 110, ts: 220000),
            MediaHit(eventType: EventType.ADBREAK_COMPLETE, playhead: 110, ts: 220000),

            MediaHit(eventType: EventType.PLAY, playhead: 110, ts: 220000),
            MediaHit(eventType: EventType.SESSION_COMPLETE, playhead: 110, ts: 220000)
        ]

        // assert
        checkHits(expectedHits: expectedHits)
    }

}
