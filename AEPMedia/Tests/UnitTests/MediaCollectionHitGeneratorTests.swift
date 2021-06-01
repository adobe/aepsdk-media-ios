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

class MediaCollectionHitGeneratorTests: XCTestCase {
    private let emptyParams: [String: Any] = [:]
    private let emptyQoeData: [String: Any] = [:]
    private let emptyMetadata: [String: String] = [:]
    private var mediaInfo: MediaInfo!
    private var hitProcessor: FakeMediaHitProcessor!
    private var hitGenerator: MediaCollectionHitGenerator!
    private var mediaContext: MediaContext!
    private let expectedSessionId = "0"
    private let expectedPlayhead: Double = 0
    private let expectedTimestamp = Int64(0)
    private typealias EventType = MediaConstants.MediaCollection.EventType
    private typealias Media = MediaConstants.MediaCollection.Media
    private typealias QoE = MediaConstants.MediaCollection.QoE
    private typealias Tracker = MediaConstants.Tracker

    static let validAdbreakInfo: [String: Any] = [
        MediaConstants.AdBreakInfo.NAME: "Adbreakname",
        MediaConstants.AdBreakInfo.POSITION: 1,
        MediaConstants.AdBreakInfo.START_TIME: 10.0
    ]

    static let validAdInfo: [String: Any] = [
        MediaConstants.AdInfo.ID: "AdID",
        MediaConstants.AdInfo.NAME: "AdName",
        MediaConstants.AdInfo.POSITION: 1,
        MediaConstants.AdInfo.LENGTH: 15.0
    ]

    static let validChapterInfo: [String: Any] = [
        MediaConstants.ChapterInfo.NAME: "ChapterName",
        MediaConstants.ChapterInfo.POSITION: 1,
        MediaConstants.ChapterInfo.START_TIME: 10.0,
        MediaConstants.ChapterInfo.LENGTH: 30.0
    ]

    static let validQoEInfo: [String: Any] = [
        MediaConstants.QoEInfo.BITRATE: 24.0,
        MediaConstants.QoEInfo.DROPPED_FRAMES: 2.0,
        MediaConstants.QoEInfo.FPS: 30.0,
        MediaConstants.QoEInfo.STARTUP_TIME: 0.0
    ]

    static let sessionId = "clientSessionId"
    static let refEvent = Event(name: MediaConstants.Media.EVENT_NAME_TRACK_MEDIA,
                                type: MediaConstants.Media.EVENT_TYPE,
                                source: MediaConstants.Media.EVENT_SOURCE_TRACK_MEDIA,
                                data: [MediaConstants.Tracker.SESSION_ID: sessionId])

    override func setUp() {
        let info = ["media.id": "testId", "media.name": "testName", "media.streamtype": "video", "media.contenttype": "vod", "media.type": "video", "media.length": 10.0, "media.resume": false] as [String: Any]
        mediaInfo = MediaInfo.init(info: info)
        let metadata = ["k1": "v1", "a.media.show": "show"]
        let config = [MediaConstants.TrackerConfig.DOWNLOADED_CONTENT: true]
        self.mediaContext = MediaContext(mediaInfo: mediaInfo, metadata: metadata)
        self.hitProcessor = FakeMediaHitProcessor()
        self.hitGenerator = MediaCollectionHitGenerator.init(context: mediaContext, hitProcessor: hitProcessor, config: config, refEvent: Self.refEvent, refTS: expectedTimestamp)
    }

    override func tearDown() {
        self.mediaContext = nil
        self.hitProcessor = nil
        self.hitGenerator = nil
    }

    // MARK: MediaCollectionHitGenerator Unit Tests
    func testMediaStart() {
        // test
        hitGenerator.processMediaStart()
        // verify
        var params = MediaCollectionHelper.generateMediaParams(mediaInfo: mediaContext.mediaInfo, metadata: mediaContext.mediaMetadata)
        params[Media.DOWNLOADED] = true
        params[Tracker.SESSION_ID] = Self.sessionId
        let metadata = MediaCollectionHelper.generateMediaMetadata(metadata: mediaContext.mediaMetadata)
        let expectedHit = MediaHit.init(eventType: "sessionStart", playhead: expectedPlayhead, ts: expectedTimestamp, params: params, customMetadata: metadata, qoeData: emptyQoeData)
        let generatedHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedHit, generatedHit)
    }

    func testMediaStartOnline() {
        // setup
        let config = [MediaConstants.TrackerConfig.DOWNLOADED_CONTENT: false]
        hitGenerator = MediaCollectionHitGenerator.init(context: mediaContext, hitProcessor: hitProcessor, config: config, refEvent: Self.refEvent, refTS: expectedTimestamp)
        // test
        hitGenerator.processMediaStart()
        // verify
        var params = MediaCollectionHelper.generateMediaParams(mediaInfo: mediaContext.mediaInfo, metadata: mediaContext.mediaMetadata)
        params[Media.DOWNLOADED] = false
        params[Tracker.SESSION_ID] = Self.sessionId
        let metadata = MediaCollectionHelper.generateMediaMetadata(metadata: mediaContext.mediaMetadata)
        let expectedHit = MediaHit.init(eventType: "sessionStart", playhead: expectedPlayhead, ts: expectedTimestamp, params: params, customMetadata: metadata, qoeData: emptyQoeData)
        let generatedHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedHit, generatedHit)
    }

    func testMediaStartWithConfig() {
        // setup
        let config: [String: Any] = [MediaConstants.TrackerConfig.DOWNLOADED_CONTENT: true, MediaConstants.TrackerConfig.CHANNEL: "test-channel"]
        hitGenerator = MediaCollectionHitGenerator.init(context: mediaContext, hitProcessor: hitProcessor, config: config, refEvent: Self.refEvent, refTS: expectedTimestamp)
        // test
        hitGenerator.processMediaStart()
        // verify
        var params = MediaCollectionHelper.generateMediaParams(mediaInfo: mediaContext.mediaInfo, metadata: mediaContext.mediaMetadata)
        params[Media.DOWNLOADED] = true
        params[Media.CHANNEL] = "test-channel"
        params[Tracker.SESSION_ID] = Self.sessionId
        let metadata = MediaCollectionHelper.generateMediaMetadata(metadata: mediaContext.mediaMetadata)
        let expectedHit = MediaHit.init(eventType: "sessionStart", playhead: expectedPlayhead, ts: expectedTimestamp, params: params, customMetadata: metadata, qoeData: emptyQoeData)
        let generatedHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedHit, generatedHit)
    }

    func testMediaStart_ForceResumeTrue() {
        // test
        hitGenerator.processMediaStart(forceResume: true)
        // verify
        var params = MediaCollectionHelper.generateMediaParams(mediaInfo: mediaContext.mediaInfo, metadata: mediaContext.mediaMetadata)
        params[Media.DOWNLOADED] = true
        params[Media.RESUME] = true
        params[Tracker.SESSION_ID] = Self.sessionId
        let metadata = MediaCollectionHelper.generateMediaMetadata(metadata: mediaContext.mediaMetadata)
        let expectedHit = MediaHit.init(eventType: "sessionStart", playhead: expectedPlayhead, ts: expectedTimestamp, params: params, customMetadata: metadata, qoeData: emptyQoeData)
        let generatedHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedHit, generatedHit)
    }

    func testMediaComplete() {
        // test
        hitGenerator.processMediaComplete()
        // verify
        let expectedHit = MediaHit.init(eventType: "sessionComplete", playhead: mediaContext.playhead, ts: expectedTimestamp, params: emptyParams, customMetadata: emptyMetadata, qoeData: emptyQoeData)
        let generatedHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedHit, generatedHit)
    }

    func testMediaSkip() {
        // test
        hitGenerator.processMediaSkip()
        // verify
        let expectedHit = MediaHit.init(eventType: "sessionEnd", playhead: expectedPlayhead, ts: expectedTimestamp, params: emptyParams, customMetadata: emptyMetadata, qoeData: emptyQoeData)
        let generatedHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedHit, generatedHit)
    }

    func testAdBreakStart() {
        // test
        hitGenerator.processAdBreakStart()
        // verify
        let expectedHit = MediaHit.init(eventType: "adBreakStart", playhead: expectedPlayhead, ts: expectedTimestamp, params: emptyParams, customMetadata: emptyMetadata, qoeData: emptyQoeData)
        let generatedHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedHit, generatedHit)
    }

    func testAdBreakComplete() {
        // test
        hitGenerator.processAdBreakComplete()
        // verify
        let expectedHit = MediaHit.init(eventType: "adBreakComplete", playhead: expectedPlayhead, ts: expectedTimestamp, params: emptyParams, customMetadata: emptyMetadata, qoeData: emptyQoeData)
        let generatedHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedHit, generatedHit)
    }

    func testAdBreakSkip() {
        // test
        hitGenerator.processAdBreakSkip()
        // verify
        let expectedHit = MediaHit.init(eventType: "adBreakComplete", playhead: expectedPlayhead, ts: expectedTimestamp, params: emptyParams, customMetadata: emptyMetadata, qoeData: emptyQoeData)
        let generatedHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedHit, generatedHit)
    }

    func testAdStart() {
        // test
        hitGenerator.processAdStart()
        // verify
        let expectedHit = MediaHit.init(eventType: "adStart", playhead: expectedPlayhead, ts: expectedTimestamp, params: emptyParams, customMetadata: emptyMetadata, qoeData: emptyQoeData)
        let generatedHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedHit, generatedHit)
    }

    func testAdComplete() {
        // test
        hitGenerator.processAdComplete()
        // verify
        let expectedHit = MediaHit.init(eventType: "adComplete", playhead: expectedPlayhead, ts: expectedTimestamp, params: emptyParams, customMetadata: emptyMetadata, qoeData: emptyQoeData)
        let generatedHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedHit, generatedHit)
    }

    func testAdSkip() {
        // test
        hitGenerator.processAdSkip()
        // verify
        let expectedHit = MediaHit.init(eventType: "adSkip", playhead: expectedPlayhead, ts: expectedTimestamp, params: emptyParams, customMetadata: emptyMetadata, qoeData: emptyQoeData)
        let generatedHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedHit, generatedHit)
    }

    func testChapterStart() {
        // test
        hitGenerator.processChapterStart()
        // verify
        let expectedHit = MediaHit.init(eventType: "chapterStart", playhead: expectedPlayhead, ts: expectedTimestamp, params: emptyParams, customMetadata: emptyMetadata, qoeData: emptyQoeData)
        let generatedHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedHit, generatedHit)
    }

    func testChapterComplete() {
        // test
        hitGenerator.processChapterComplete()
        // verify
        let expectedHit = MediaHit.init(eventType: "chapterComplete", playhead: expectedPlayhead, ts: expectedTimestamp, params: emptyParams, customMetadata: emptyMetadata, qoeData: emptyQoeData)
        let generatedHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedHit, generatedHit)
    }

    func testChapterSkip() {
        // test
        hitGenerator.processChapterSkip()
        // verify
        let expectedHit = MediaHit.init(eventType: "chapterSkip", playhead: expectedPlayhead, ts: expectedTimestamp, params: emptyParams, customMetadata: emptyMetadata, qoeData: emptyQoeData)
        let generatedHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedHit, generatedHit)
    }

    func testProcessIdleStart() {
        // test
        hitGenerator.processSessionAbort()
        // verify
        let expectedHit = MediaHit.init(eventType: "sessionEnd", playhead: expectedPlayhead, ts: expectedTimestamp, params: emptyParams, customMetadata: emptyMetadata, qoeData: emptyQoeData)
        let generatedHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedHit, generatedHit)
    }

    func testProcessIdleComplete() {
        // setup
        let adBreakInfo = AdBreakInfo(info: Self.validAdbreakInfo)
        mediaContext.setAdBreak(info: adBreakInfo!)

        let adInfo = AdInfo(info: Self.validAdInfo)
        let adMetadata = ["k1": "v1", "a.media.ad.advertiser": "advertiser"]
        mediaContext.setAd(info: adInfo!, metadata: adMetadata)

        let chapterInfo = ChapterInfo(info: Self.validChapterInfo)
        let chapterMetadata = ["k1": "v1"]
        mediaContext.setChapter(info: chapterInfo!, metadata: chapterMetadata)

        var params = MediaCollectionHelper.generateMediaParams(mediaInfo: mediaContext.mediaInfo, metadata: mediaContext.mediaMetadata)
        params[Media.DOWNLOADED] = true
        params[Media.RESUME] = true
        params[Tracker.SESSION_ID] = Self.sessionId
        let metadata = MediaCollectionHelper.generateMediaMetadata(metadata: mediaContext.mediaMetadata)

        mediaContext.enterPlaybackState(state: .Play)
        // test
        hitGenerator.processSessionRestart()
        // verify number hits
        XCTAssertEqual(5, hitProcessor.getHitCountFromActiveSession())
        // verify media start hit
        let expectedMediaStartHit = MediaHit.init(eventType: "sessionStart", playhead: expectedPlayhead, ts: expectedTimestamp, params: params, customMetadata: metadata, qoeData: emptyQoeData)
        let mediaStartHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedMediaStartHit, mediaStartHit)
        // verify chapter start hit
        let expectedChapterParams = MediaCollectionHelper.generateChapterParams(chapterInfo: mediaContext.chapterInfo)
        let expectedChapterMetadata = mediaContext.chapterMetadata
        let expectedChapterStartHit = MediaHit.init(eventType: "chapterStart", playhead: expectedPlayhead, ts: expectedTimestamp, params: expectedChapterParams, customMetadata: expectedChapterMetadata, qoeData: emptyQoeData)
        let chapterStartHit = hitProcessor.getHitFromActiveSession(index: 1)
        XCTAssertEqual(expectedChapterStartHit, chapterStartHit)
        // verify ad break start hit
        let expectedAdBreakParams = MediaCollectionHelper.generateAdBreakParams(adBreakInfo: mediaContext.adBreakInfo)
        let expectedAdBreakStartHit = MediaHit.init(eventType: "adBreakStart", playhead: expectedPlayhead, ts: expectedTimestamp, params: expectedAdBreakParams, customMetadata: emptyMetadata, qoeData: emptyQoeData)
        let adBreakStartHit = hitProcessor.getHitFromActiveSession(index: 2)
        XCTAssertEqual(adBreakStartHit, expectedAdBreakStartHit)
        // verify ad start
        let expectedAdParams = MediaCollectionHelper.generateAdParams(adInfo: mediaContext.adInfo, adMetadata: mediaContext.adMetadata)
        let expectedAdMetadata = MediaCollectionHelper.generateAdMetadata(adMetadata: mediaContext.adMetadata)
        let expectedAdStartHit = MediaHit.init(eventType: "adStart", playhead: expectedPlayhead, ts: expectedTimestamp, params: expectedAdParams, customMetadata: expectedAdMetadata, qoeData: emptyQoeData)
        let adStartHit = hitProcessor.getHitFromActiveSession(index: 3)
        XCTAssertEqual(adStartHit, expectedAdStartHit)
        // verify play
        let expectedPlayHit = MediaHit.init(eventType: "play", playhead: expectedPlayhead, ts: expectedTimestamp, params: emptyParams, customMetadata: emptyMetadata, qoeData: emptyQoeData)
        let playHit = hitProcessor.getHitFromActiveSession(index: 4)
        XCTAssertEqual(expectedPlayHit, playHit)
    }

    func testProcessIdleCompleteOnline() {
        // setup
        let adBreakInfo = AdBreakInfo(info: Self.validAdbreakInfo)
        mediaContext.setAdBreak(info: adBreakInfo!)

        let adInfo = AdInfo(info: Self.validAdInfo)
        let adMetadata = ["k1": "v1", "a.media.ad.advertiser": "advertiser"]
        mediaContext.setAd(info: adInfo!, metadata: adMetadata)

        let chapterInfo = ChapterInfo(info: Self.validChapterInfo)
        let chapterMetadata = ["k1": "v1"]
        mediaContext.setChapter(info: chapterInfo!, metadata: chapterMetadata)

        var params = MediaCollectionHelper.generateMediaParams(mediaInfo: mediaContext.mediaInfo, metadata: mediaContext.mediaMetadata)
        params[Media.DOWNLOADED] = false
        params[Media.RESUME] = true
        params[Tracker.SESSION_ID] = Self.sessionId
        let metadata = MediaCollectionHelper.generateMediaMetadata(metadata: mediaContext.mediaMetadata)
        mediaContext.enterPlaybackState(state: .Play)
        let config = [MediaConstants.TrackerConfig.DOWNLOADED_CONTENT: false]
        self.hitGenerator = MediaCollectionHitGenerator.init(context: mediaContext, hitProcessor: hitProcessor, config: config, refEvent: Self.refEvent, refTS: expectedTimestamp)
        // test
        hitGenerator.processSessionRestart()
        // verify number hits
        XCTAssertEqual(5, hitProcessor.getHitCountFromActiveSession())
        // verify media start hit
        let expectedMediaStartHit = MediaHit.init(eventType: "sessionStart", playhead: expectedPlayhead, ts: expectedTimestamp, params: params, customMetadata: metadata, qoeData: emptyQoeData)
        let mediaStartHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedMediaStartHit, mediaStartHit)
        // verify chapter start hit
        let expectedChapterParams = MediaCollectionHelper.generateChapterParams(chapterInfo: mediaContext.chapterInfo)
        let expectedChapterMetadata = mediaContext.chapterMetadata
        let expectedChapterStartHit = MediaHit.init(eventType: "chapterStart", playhead: expectedPlayhead, ts: expectedTimestamp, params: expectedChapterParams, customMetadata: expectedChapterMetadata, qoeData: emptyQoeData)
        let chapterStartHit = hitProcessor.getHitFromActiveSession(index: 1)
        XCTAssertEqual(expectedChapterStartHit, chapterStartHit)
        // verify ad break start hit
        let expectedAdBreakParams = MediaCollectionHelper.generateAdBreakParams(adBreakInfo: mediaContext.adBreakInfo)
        let expectedAdBreakStartHit = MediaHit.init(eventType: "adBreakStart", playhead: expectedPlayhead, ts: expectedTimestamp, params: expectedAdBreakParams, customMetadata: emptyMetadata, qoeData: emptyQoeData)
        let adBreakStartHit = hitProcessor.getHitFromActiveSession(index: 2)
        XCTAssertEqual(adBreakStartHit, expectedAdBreakStartHit)
        // verify ad start
        let expectedAdParams = MediaCollectionHelper.generateAdParams(adInfo: mediaContext.adInfo, adMetadata: mediaContext.adMetadata)
        let expectedAdMetadata = MediaCollectionHelper.generateAdMetadata(adMetadata: mediaContext.adMetadata)
        let expectedAdStartHit = MediaHit.init(eventType: "adStart", playhead: expectedPlayhead, ts: expectedTimestamp, params: expectedAdParams, customMetadata: expectedAdMetadata, qoeData: emptyQoeData)
        let adStartHit = hitProcessor.getHitFromActiveSession(index: 3)
        XCTAssertEqual(adStartHit, expectedAdStartHit)
        // verify play
        let expectedPlayHit = MediaHit.init(eventType: "play", playhead: expectedPlayhead, ts: expectedTimestamp, params: emptyParams, customMetadata: emptyMetadata, qoeData: emptyQoeData)
        let playHit = hitProcessor.getHitFromActiveSession(index: 4)
        XCTAssertEqual(expectedPlayHit, playHit)
    }

    func testProcessIdleCompleteStateTrackingResumesAfterIdle() {
        // setup
        guard let fullscreenStateInfo = StateInfo(stateName: "fullscreen") else {
            XCTFail("unable to create state info")
            return
        }
        mediaContext.enterPlaybackState(state: .Play)
        _ = mediaContext.startState(info: fullscreenStateInfo)
        var params = MediaCollectionHelper.generateMediaParams(mediaInfo: mediaContext.mediaInfo, metadata: mediaContext.mediaMetadata)
        params[Media.DOWNLOADED] = true
        params[Media.RESUME] = true
        params[Tracker.SESSION_ID] = Self.sessionId
        let metadata = MediaCollectionHelper.generateMediaMetadata(metadata: mediaContext.mediaMetadata)
        let config = [MediaConstants.TrackerConfig.DOWNLOADED_CONTENT: true]
        self.hitGenerator = MediaCollectionHitGenerator.init(context: mediaContext, hitProcessor: hitProcessor, config: config, refEvent: Self.refEvent, refTS: expectedTimestamp)
        // test
        hitGenerator.processSessionRestart()
        // verify number hits
        XCTAssertEqual(3, hitProcessor.getHitCountFromActiveSession())
        // verify media start hit
        let expectedMediaStartHit = MediaHit.init(eventType: "sessionStart", playhead: expectedPlayhead, ts: expectedTimestamp, params: params, customMetadata: metadata, qoeData: emptyQoeData)
        let mediaStartHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedMediaStartHit, mediaStartHit)
        // verify state start hit
        let startParams = [MediaConstants.MediaCollection.State.NAME: fullscreenStateInfo.stateName]
        let expectedStateStartHit = MediaHit.init(eventType: "stateStart", playhead: expectedPlayhead, ts: expectedTimestamp, params: startParams, customMetadata: emptyMetadata, qoeData: emptyQoeData)
        let stateStartHit = hitProcessor.getHitFromActiveSession(index: 1)
        XCTAssertEqual(expectedStateStartHit, stateStartHit)
        // verify play
        let expectedPlayHit = MediaHit.init(eventType: "play", playhead: expectedPlayhead, ts: expectedTimestamp, params: emptyParams, customMetadata: emptyMetadata, qoeData: emptyQoeData)
        let playHit = hitProcessor.getHitFromActiveSession(index: 2)
        XCTAssertEqual(expectedPlayHit, playHit)
    }

    func testProcessIdleCompleteStateNoActiveStates() {
        // setup
        mediaContext.enterPlaybackState(state: .Play)
        var params = MediaCollectionHelper.generateMediaParams(mediaInfo: mediaContext.mediaInfo, metadata: mediaContext.mediaMetadata)
        params[Media.DOWNLOADED] = true
        params[Media.RESUME] = true
        params[Tracker.SESSION_ID] = Self.sessionId
        let metadata = MediaCollectionHelper.generateMediaMetadata(metadata: mediaContext.mediaMetadata)
        let config = [MediaConstants.TrackerConfig.DOWNLOADED_CONTENT: true]
        self.hitGenerator = MediaCollectionHitGenerator.init(context: mediaContext, hitProcessor: hitProcessor, config: config, refEvent: Self.refEvent, refTS: expectedTimestamp)
        // test
        hitGenerator.processSessionRestart()
        // verify number hits
        XCTAssertEqual(2, hitProcessor.getHitCountFromActiveSession())
        // verify media start hit
        let expectedMediaStartHit = MediaHit.init(eventType: "sessionStart", playhead: expectedPlayhead, ts: expectedTimestamp, params: params, customMetadata: metadata, qoeData: emptyQoeData)
        let mediaStartHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedMediaStartHit, mediaStartHit)
        // verify play
        let expectedPlayHit = MediaHit.init(eventType: "play", playhead: expectedPlayhead, ts: expectedTimestamp, params: emptyParams, customMetadata: emptyMetadata, qoeData: emptyQoeData)
        let playHit = hitProcessor.getHitFromActiveSession(index: 1)
        XCTAssertEqual(expectedPlayHit, playHit)
    }

    func testProcessIdleCompleteStateTrackingResumesAfterIdle2() {
        // setup
        guard let fullscreenStateInfo = StateInfo(stateName: "fullscreen") else {
            XCTFail("unable to create state info")
            return
        }
        mediaContext.enterPlaybackState(state: .Play)
        mediaContext.enterPlaybackState(state: .Play)
        mediaContext.startState(info: fullscreenStateInfo)
        mediaContext.endState(info: fullscreenStateInfo)
        mediaContext.startState(info: fullscreenStateInfo)
        var params = MediaCollectionHelper.generateMediaParams(mediaInfo: mediaContext.mediaInfo, metadata: mediaContext.mediaMetadata)
        params[Media.DOWNLOADED] = true
        params[Media.RESUME] = true
        params[Tracker.SESSION_ID] = Self.sessionId
        let metadata = MediaCollectionHelper.generateMediaMetadata(metadata: mediaContext.mediaMetadata)
        let config = [MediaConstants.TrackerConfig.DOWNLOADED_CONTENT: true]
        self.hitGenerator = MediaCollectionHitGenerator.init(context: mediaContext, hitProcessor: hitProcessor, config: config, refEvent: Self.refEvent, refTS: expectedTimestamp)
        // test
        hitGenerator.processSessionRestart()
        // verify number hits
        XCTAssertEqual(3, hitProcessor.getHitCountFromActiveSession())
        // verify media start hit
        let expectedMediaStartHit = MediaHit.init(eventType: "sessionStart", playhead: expectedPlayhead, ts: expectedTimestamp, params: params, customMetadata: metadata, qoeData: emptyQoeData)
        let mediaStartHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedMediaStartHit, mediaStartHit)
        // verify state start hit
        let startParams = [MediaConstants.MediaCollection.State.NAME: fullscreenStateInfo.stateName]
        let expectedStateStartHit = MediaHit.init(eventType: "stateStart", playhead: expectedPlayhead, ts: expectedTimestamp, params: startParams, customMetadata: emptyMetadata, qoeData: emptyQoeData)
        let stateStartHit = hitProcessor.getHitFromActiveSession(index: 1)
        XCTAssertEqual(expectedStateStartHit, stateStartHit)
        // verify play
        let expectedPlayHit = MediaHit.init(eventType: "play", playhead: expectedPlayhead, ts: expectedTimestamp, params: emptyParams, customMetadata: emptyMetadata, qoeData: emptyQoeData)
        let playHit = hitProcessor.getHitFromActiveSession(index: 2)
        XCTAssertEqual(expectedPlayHit, playHit)
    }

    func testProcessPlaybackStateDifferentStates() {
        // setup
        var params = MediaCollectionHelper.generateMediaParams(mediaInfo: mediaContext.mediaInfo, metadata: mediaContext.mediaMetadata)
        params[Media.DOWNLOADED] = true
        params[Media.RESUME] = true
        let config = [MediaConstants.TrackerConfig.DOWNLOADED_CONTENT: true]
        self.hitGenerator = MediaCollectionHitGenerator.init(context: mediaContext, hitProcessor: hitProcessor, config: config, refEvent: Self.refEvent, refTS: expectedTimestamp)
        // test
        hitGenerator.processPlayback()
        XCTAssertEqual(0, hitProcessor.getHitCount(sessionId: self.expectedSessionId))
        // play hit
        mediaContext.enterPlaybackState(state: .Play)
        hitGenerator.processPlayback()
        XCTAssertEqual(1, hitProcessor.getHitCountFromActiveSession())
        let expectedPlayHit = MediaHit.init(eventType: "play", playhead: expectedPlayhead, ts: expectedTimestamp, params: emptyParams, customMetadata: emptyMetadata, qoeData: emptyQoeData)
        let playHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedPlayHit, playHit)
        hitProcessor.clearHitsFromActiveSession()
        // buffer start hit
        mediaContext.enterPlaybackState(state: .Buffer)
        hitGenerator.processPlayback()
        XCTAssertEqual(1, hitProcessor.getHitCountFromActiveSession())
        let expectedBufferStartHit = MediaHit.init(eventType: "bufferStart", playhead: expectedPlayhead, ts: expectedTimestamp, params: emptyParams, customMetadata: emptyMetadata, qoeData: emptyQoeData)
        let bufferStartHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedBufferStartHit, bufferStartHit)
        hitProcessor.clearHitsFromActiveSession()
        // buffer end hit (will be play)
        mediaContext.exitPlaybackState(state: .Buffer)
        hitGenerator.processPlayback()
        XCTAssertEqual(1, hitProcessor.getHitCountFromActiveSession())
        let expectedBufferEndHit = MediaHit.init(eventType: "play", playhead: expectedPlayhead, ts: expectedTimestamp, params: emptyParams, customMetadata: emptyMetadata, qoeData: emptyQoeData)
        let bufferEndHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedBufferEndHit, bufferEndHit)
        hitProcessor.clearHitsFromActiveSession()
        // start seek hit
        mediaContext.enterPlaybackState(state: .Seek)
        hitGenerator.processPlayback()
        XCTAssertEqual(1, hitProcessor.getHitCountFromActiveSession())
        let expectedSeekStartHit = MediaHit.init(eventType: "pauseStart", playhead: expectedPlayhead, ts: expectedTimestamp, params: emptyParams, customMetadata: emptyMetadata, qoeData: emptyQoeData)
        let seekStartHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedSeekStartHit, seekStartHit)
        hitProcessor.clearHitsFromActiveSession()
        // exit seek hit
        mediaContext.exitPlaybackState(state: .Seek)
        hitGenerator.processPlayback()
        XCTAssertEqual(1, hitProcessor.getHitCountFromActiveSession())
        let expectedSeekExitHit = MediaHit.init(eventType: "play", playhead: expectedPlayhead, ts: expectedTimestamp, params: emptyParams, customMetadata: emptyMetadata, qoeData: emptyQoeData)
        let seekExitHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedSeekExitHit, seekExitHit)
        hitProcessor.clearHitsFromActiveSession()
        // pause hit
        mediaContext.enterPlaybackState(state: .Pause)
        hitGenerator.processPlayback()
        XCTAssertEqual(1, hitProcessor.getHitCountFromActiveSession())
        let expectedPauseHit = MediaHit.init(eventType: "pauseStart", playhead: expectedPlayhead, ts: expectedTimestamp, params: emptyParams, customMetadata: emptyMetadata, qoeData: emptyQoeData)
        let pauseHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedPauseHit, pauseHit)
        hitProcessor.clearHitsFromActiveSession()
    }

    func testProcessStateStartFullscreen() {
        // setup
        guard let stateInfo = StateInfo(stateName: "fullscreen") else {
            XCTFail("state creation failed")
            return
        }
        // test
        hitGenerator.processStateStart(stateInfo: stateInfo)
        // verify state start hit
        XCTAssertEqual(1, hitProcessor.getHitCount(sessionId: self.expectedSessionId))
        let params = [MediaConstants.MediaCollection.State.NAME: "fullscreen"]
        let expectedStateStartHit = MediaHit.init(eventType: "stateStart", playhead: expectedPlayhead, ts: expectedTimestamp, params: params, customMetadata: emptyMetadata, qoeData: emptyQoeData)
        let stateStartHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedStateStartHit, stateStartHit)
    }

    func testProcessStateStartShouldSendQoEData() {
        // setup
        let qoeInfo = QoEInfo(info: Self.validQoEInfo)
        mediaContext.qoeInfo = qoeInfo
        guard let stateInfo = StateInfo(stateName: "fullscreen") else {
            XCTFail("state creation failed")
            return
        }
        // test
        hitGenerator.processStateStart(stateInfo: stateInfo)
        // verify state start hit + qoe info
        XCTAssertEqual(1, hitProcessor.getHitCount(sessionId: self.expectedSessionId))
        let params = [MediaConstants.MediaCollection.State.NAME: "fullscreen"]
        let qoeData = MediaCollectionHelper.generateQoEParam(qoeInfo: qoeInfo)
        let expectedStateStartHit = MediaHit.init(eventType: "stateStart", playhead: expectedPlayhead, ts: expectedTimestamp, params: params, customMetadata: emptyMetadata, qoeData: qoeData)
        let stateStartHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedStateStartHit, stateStartHit)
    }

    func testProcessStateEndFullscreen() {
        // setup
        guard let stateInfo = StateInfo(stateName: "fullscreen") else {
            XCTFail("state creation failed")
            return
        }
        // test
        hitGenerator.processStateEnd(stateInfo: stateInfo)
        // verify state end hit
        XCTAssertEqual(1, hitProcessor.getHitCount(sessionId: self.expectedSessionId))
        let params = [MediaConstants.MediaCollection.State.NAME: "fullscreen"]
        let expectedStateEndHit = MediaHit.init(eventType: "stateEnd", playhead: expectedPlayhead, ts: expectedTimestamp, params: params, customMetadata: emptyMetadata, qoeData: emptyQoeData)
        let stateEndHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedStateEndHit, stateEndHit)
    }

    func testProcessStateEndShouldSendQoEData() {
        // setup
        let qoeInfo = QoEInfo(info: Self.validQoEInfo)
        mediaContext.qoeInfo = qoeInfo
        guard let stateInfo = StateInfo(stateName: "fullscreen") else {
            XCTFail("state creation failed")
            return
        }
        // test
        hitGenerator.processStateEnd(stateInfo: stateInfo)
        // verify state end hit + qoe info
        XCTAssertEqual(1, hitProcessor.getHitCount(sessionId: self.expectedSessionId))
        let params = [MediaConstants.MediaCollection.State.NAME: "fullscreen"]
        let qoeData = MediaCollectionHelper.generateQoEParam(qoeInfo: qoeInfo)
        let expectedStateEndHit = MediaHit.init(eventType: "stateEnd", playhead: expectedPlayhead, ts: expectedTimestamp, params: params, customMetadata: emptyMetadata, qoeData: qoeData)
        let stateEndHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedStateEndHit, stateEndHit)
    }

    func testProcessPlaybackStateSameStateOnline() {
        // setup
        mediaContext.enterPlaybackState(state: .Play)
        let config = [MediaConstants.TrackerConfig.DOWNLOADED_CONTENT: false]
        self.hitGenerator = MediaCollectionHitGenerator.init(context: mediaContext, hitProcessor: hitProcessor, config: config, refEvent: Self.refEvent, refTS: expectedTimestamp)
        var params = MediaCollectionHelper.generateMediaParams(mediaInfo: mediaContext.mediaInfo, metadata: mediaContext.mediaMetadata)
        params[Media.DOWNLOADED] = false
        // verify play hit
        hitGenerator.processPlayback()
        XCTAssertEqual(1, hitProcessor.getHitCountFromActiveSession())
        let expectedPlayHit = MediaHit.init(eventType: "play", playhead: expectedPlayhead, ts: expectedTimestamp, params: emptyParams, customMetadata: emptyMetadata, qoeData: emptyQoeData)
        let playHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedPlayHit, playHit)
        hitProcessor.clearHitsFromActiveSession()
        // second play hit should not be sent
        hitGenerator.processPlayback()
        XCTAssertEqual(0, hitProcessor.getHitCount(sessionId: self.expectedSessionId))
        // set timestamp greater than session interval to allow a new play hit to be sent
        hitGenerator.setRefTS(ts: 100000)
        hitGenerator.processPlayback()
        XCTAssertEqual(1, hitProcessor.getHitCountFromActiveSession())
    }

    func testProcessPlaybackSameStateInit() {
        // no hit due to the current state == previous state and offline ping interval not elapsed
        hitGenerator.processPlayback()
        XCTAssertEqual(0, hitProcessor.getHitCountFromActiveSession())
        // no hit due to timestamp being lower than default offline ping interval
        hitGenerator.setRefTS(ts: 10000)
        hitGenerator.processPlayback()
        XCTAssertEqual(0, hitProcessor.getHitCountFromActiveSession())
        // expect 1 hit due to timestamp >= the default offline ping interval
        hitGenerator.setRefTS(ts: 50000)
        hitGenerator.processPlayback()
        XCTAssertEqual(1, hitProcessor.getHitCountFromActiveSession())
        let expectedPingHit = MediaHit.init(eventType: "ping", playhead: expectedPlayhead, ts: 50000, params: emptyParams, customMetadata: emptyMetadata, qoeData: emptyQoeData)
        let pingHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedPingHit, pingHit)
    }

    func testProcessPlaybackSameStateInitOnline() {
        // setup
        let config = [MediaConstants.TrackerConfig.DOWNLOADED_CONTENT: false]
        self.hitGenerator = MediaCollectionHitGenerator.init(context: mediaContext, hitProcessor: hitProcessor, config: config, refEvent: Self.refEvent, refTS: expectedTimestamp)
        // no hit due to the current state == previous state and online ping interval not elapsed
        hitGenerator.processPlayback()
        XCTAssertEqual(0, hitProcessor.getHitCountFromActiveSession())
        // expect 1 hit due to timestamp >= default online ping interval
        hitGenerator.setRefTS(ts: 10000)
        hitGenerator.processPlayback()
        XCTAssertEqual(1, hitProcessor.getHitCountFromActiveSession())
        var expectedPingHit = MediaHit.init(eventType: "ping", playhead: expectedPlayhead, ts: 10000, params: emptyParams, customMetadata: emptyMetadata, qoeData: emptyQoeData)
        var pingHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedPingHit, pingHit)
        // expect another hit due to timestamp >= the default online ping interval
        hitGenerator.setRefTS(ts: 50000)
        hitGenerator.processPlayback()
        XCTAssertEqual(2, hitProcessor.getHitCountFromActiveSession())
        expectedPingHit = MediaHit.init(eventType: "ping", playhead: expectedPlayhead, ts: 50000, params: emptyParams, customMetadata: emptyMetadata, qoeData: emptyQoeData)
        pingHit = hitProcessor.getHitFromActiveSession(index: 1)
        XCTAssertEqual(expectedPingHit, pingHit)
    }

    func testprocessPlaybackSameStateTimeout() {
        // trigger play hit
        mediaContext.enterPlaybackState(state: .Play)
        hitGenerator.processPlayback()
        XCTAssertEqual(1, hitProcessor.getHitCountFromActiveSession())
        let expectedPlayHit = MediaHit.init(eventType: "play", playhead: expectedPlayhead, ts: 0, params: emptyParams, customMetadata: emptyMetadata, qoeData: emptyQoeData)
        let playHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedPlayHit, playHit)
        hitProcessor.clearHitsFromActiveSession()
        // expect ping hit due to timestamp >= default online ping interval but current state == previous state
        hitGenerator.setRefTS(ts: 51000)
        hitGenerator.processPlayback()
        XCTAssertEqual(1, hitProcessor.getHitCountFromActiveSession())
        let expectedPingHit = MediaHit.init(eventType: "ping", playhead: expectedPlayhead, ts: 51000, params: emptyParams, customMetadata: emptyMetadata, qoeData: emptyQoeData)
        let pingHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedPingHit, pingHit)
    }

    func testprocessPlaybackFlush() {
        // trigger play hit
        mediaContext.enterPlaybackState(state: .Play)
        hitGenerator.processPlayback()
        XCTAssertEqual(1, hitProcessor.getHitCountFromActiveSession())
        let expectedPlayHit = MediaHit.init(eventType: "play", playhead: expectedPlayhead, ts: 0, params: emptyParams, customMetadata: emptyMetadata, qoeData: emptyQoeData)
        let playHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedPlayHit, playHit)
        hitProcessor.clearHitsFromActiveSession()
        // expect play hit due to flush
        hitGenerator.setRefTS(ts: 10)
        hitGenerator.processPlayback(doFlush: true)
        XCTAssertEqual(1, hitProcessor.getHitCountFromActiveSession())
        let expectedPlayHit2 = MediaHit.init(eventType: "play", playhead: expectedPlayhead, ts: 10, params: emptyParams, customMetadata: emptyMetadata, qoeData: emptyQoeData)
        let playHit2 = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedPlayHit2, playHit2)
    }

    func testprocessBitrateChange() {
        // trigger bitrate change hit
        hitGenerator.processBitrateChange()
        // verify
        XCTAssertEqual(1, hitProcessor.getHitCountFromActiveSession())
        let expectedHit = MediaHit.init(eventType: "bitrateChange", playhead: expectedPlayhead, ts: 0, params: emptyParams, customMetadata: emptyMetadata, qoeData: emptyQoeData)
        let hit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedHit, hit)
    }

    func testProcessError() {
        // setup
        let qoeInfo = QoEInfo(info: Self.validQoEInfo)
        mediaContext.qoeInfo = qoeInfo
        // test
        hitGenerator.processError(errorId: "error-id")
        // verify
        let expectedQoeInfo = MediaCollectionHelper.generateQoEParam(qoeInfo: qoeInfo, errorId: "error-id")
        XCTAssertEqual(1, hitProcessor.getHitCount(sessionId: self.expectedSessionId))
        let expectedErrorHit = MediaHit.init(eventType: "error", playhead: expectedPlayhead, ts: expectedTimestamp, params: emptyParams, customMetadata: emptyMetadata, qoeData: expectedQoeInfo)
        let errorHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedErrorHit, errorHit)
    }

    func testGenerateHitProcessQoEChange() {
        // setup
        let qoeInfo = QoEInfo(info: Self.validQoEInfo)
        mediaContext.qoeInfo = qoeInfo
        // test
        hitGenerator.processBitrateChange()
        // verify bitrate change hit + qoe info
        XCTAssertEqual(1, hitProcessor.getHitCount(sessionId: self.expectedSessionId))
        let expectedQoeInfo = MediaCollectionHelper.generateQoEParam(qoeInfo: qoeInfo)
        let expectedBitrateChangeHit = MediaHit.init(eventType: "bitrateChange", playhead: expectedPlayhead, ts: 0, params: emptyParams, customMetadata: emptyMetadata, qoeData: expectedQoeInfo)
        let bitrateChangeHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedBitrateChangeHit, bitrateChangeHit)
        // clear hits
        hitProcessor.clearHitsFromActiveSession()
        // test second bitrate change
        hitGenerator.processBitrateChange()
        // verify second bitrate change hit + qoe info
        XCTAssertEqual(1, hitProcessor.getHitCount(sessionId: self.expectedSessionId))
        let nextExpectedBitrateChangeHit = MediaHit.init(eventType: "bitrateChange", playhead: expectedPlayhead, ts: 0, params: emptyParams, customMetadata: emptyMetadata, qoeData: expectedQoeInfo)
        let nextBitrateChangeHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(nextExpectedBitrateChangeHit, nextBitrateChangeHit)
        // clear hits
        hitProcessor.clearHitsFromActiveSession()
        // setup new qoeInfo
        guard let qoeInfo2 = QoEInfo(info: [MediaConstants.QoEInfo.BITRATE: 48.0,
                                            MediaConstants.QoEInfo.DROPPED_FRAMES: 4.0,
                                            MediaConstants.QoEInfo.FPS: 60.0,
                                            MediaConstants.QoEInfo.STARTUP_TIME: 1.0]) else {
            XCTFail("qoe info creation failed")
            return
        }
        mediaContext.qoeInfo = qoeInfo2
        // Test next hit should have new qoeInfo
        hitGenerator.processAdSkip()
        XCTAssertEqual(1, hitProcessor.getHitCount(sessionId: self.expectedSessionId))
        let expectedQoeInfo2 = MediaCollectionHelper.generateQoEParam(qoeInfo: qoeInfo2)
        let lastExpectedAdSkipHit = MediaHit.init(eventType: "adSkip", playhead: expectedPlayhead, ts: 0, params: emptyParams, customMetadata: emptyMetadata, qoeData: expectedQoeInfo2)
        let lastAdSkipHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(lastExpectedAdSkipHit, lastAdSkipHit)
    }

    // MARK: Negative Tests
    func testCreateMediaHitGeneratorWithNilContext() {
        // test
        let config = [MediaConstants.TrackerConfig.DOWNLOADED_CONTENT: true]
        hitGenerator = MediaCollectionHitGenerator.init(context: nil, hitProcessor: hitProcessor, config: config, refEvent: Self.refEvent, refTS: expectedTimestamp)
        // verify
        XCTAssertNil(hitGenerator)
    }

    func testMediaProcessorFailedToCreateSession() {
        // test
        let config = [MediaConstants.TrackerConfig.DOWNLOADED_CONTENT: true, "testFail": true]
        hitGenerator = MediaCollectionHitGenerator.init(context: mediaContext, hitProcessor: hitProcessor, config: config, refEvent: Self.refEvent, refTS: expectedTimestamp)
        // verify
        XCTAssertEqual("", hitGenerator.sessionId)
    }
}
