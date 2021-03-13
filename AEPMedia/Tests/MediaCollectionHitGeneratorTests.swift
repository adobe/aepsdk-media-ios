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

class MediaCollectionHitGeneratorTests: XCTestCase {
    private let emptyParams:[String: Any] = [:]
    private let emptyQoeData:[String: Any] = [:]
    private let emptyMetadata:[String: String] = [:]
    private var mediaInfo: MediaInfo!
    private var hitProcessor: FakeMediaHitProcessor!
    private var hitGenerator: MediaCollectionHitGenerator!
    private var mediaContext: MediaContext!
    private let expectedSessionId = "0"
    private let expectedPlayhead: Double = 50
    private let expectedTimestamp = TimeInterval(0)
    
    static let validAdbreakInfo : [String : Any] = [
        MediaConstants.AdBreakInfo.NAME : "Adbreakname",
        MediaConstants.AdBreakInfo.POSITION : 1,
        MediaConstants.AdBreakInfo.START_TIME : 0.0
    ]
    
    static let validAdInfo : [String : Any] = [
        MediaConstants.AdInfo.ID : "AdID",
        MediaConstants.AdInfo.NAME : "AdName",
        MediaConstants.AdInfo.POSITION : 1,
        MediaConstants.AdInfo.LENGTH : 2.5
    ]
    
    static let validChapterInfo : [String : Any] = [
        MediaConstants.ChapterInfo.NAME : "ChapterName",
        MediaConstants.ChapterInfo.POSITION : 3,
        MediaConstants.ChapterInfo.START_TIME : 3.0,
        MediaConstants.ChapterInfo.LENGTH : 5.0
    ]
    
    static var validQoEInfo : [String : Any] = [
        MediaConstants.QoEInfo.BITRATE : 24.0,
        MediaConstants.QoEInfo.DROPPED_FRAMES : 2.0,
        MediaConstants.QoEInfo.FPS : 30.0,
        MediaConstants.QoEInfo.STARTUP_TIME : 0.0
    ]

    override func setUp() {
        let info = ["media.id":"testId", "media.name":"testName", "media.streamtype":"video", "media.contenttype":"vod", "media.type":"video", "media.length": 10.0, "media.resume": false] as [String : Any]
        mediaInfo = MediaInfo.init(info: info)
        let metadata = ["k1": "v1", "a.media.show": "show"]
        let config = [MediaConstants.TrackerConfig.DOWNLOADED_CONTENT: true]
        self.mediaContext = MediaContext(mediaInfo: mediaInfo, metadata: metadata)
        self.hitProcessor = FakeMediaHitProcessor()
        self.hitGenerator = MediaCollectionHitGenerator.init(context: mediaContext, hitProcessor: hitProcessor, config: config, refTS: expectedTimestamp)
    }

    override func tearDown() {
        self.mediaContext = nil
        self.hitProcessor = nil
        self.hitGenerator = nil
    }
    
    //MARK: MediaCollectionHitGenerator Unit Tests
    func testMediaStart() {
        // test
        hitGenerator.processMediaStart()
        // verify
        var params = MediaCollectionHelper.extractMediaParams(mediaContext: mediaContext)
        params[MediaConstants.MediaCollection.Media.DOWNLOADED] = true
        let metadata = MediaCollectionHelper.extractMediaMetadata(mediaContext: mediaContext)
        let expectedHit = MediaHit.init(eventType: "sessionStart", playhead: expectedPlayhead, ts: expectedTimestamp, params: params, customMetadata: metadata, qoeData: emptyQoeData)
        let generatedHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedHit, generatedHit)
    }
    
    func testMediaStartOnline() {
        // setup
        let config = [MediaConstants.TrackerConfig.DOWNLOADED_CONTENT: false]
        hitGenerator = MediaCollectionHitGenerator.init(context: mediaContext, hitProcessor: hitProcessor, config: config, refTS: expectedTimestamp)
        // test
        hitGenerator.processMediaStart()
        // verify
        var params = MediaCollectionHelper.extractMediaParams(mediaContext: mediaContext)
        params[MediaConstants.MediaCollection.Media.DOWNLOADED] = false
        let metadata = MediaCollectionHelper.extractMediaMetadata(mediaContext: mediaContext)
        let expectedHit = MediaHit.init(eventType: "sessionStart", playhead: expectedPlayhead, ts: expectedTimestamp, params: params, customMetadata: metadata, qoeData: emptyQoeData)
        let generatedHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedHit, generatedHit)
    }
    
    func testMediaStartWithConfig() {
        // setup
        let config: [String: Any] = [MediaConstants.TrackerConfig.DOWNLOADED_CONTENT: true, MediaConstants.TrackerConfig.CHANNEL: "test-channel"]
        hitGenerator = MediaCollectionHitGenerator.init(context: mediaContext, hitProcessor: hitProcessor, config: config, refTS: expectedTimestamp)
        // test
        hitGenerator.processMediaStart()
        // verify
        var params = MediaCollectionHelper.extractMediaParams(mediaContext: mediaContext)
        params[MediaConstants.MediaCollection.Media.DOWNLOADED] = true
        params[MediaConstants.MediaCollection.Media.CHANNEL] = "test-channel"
        let metadata = MediaCollectionHelper.extractMediaMetadata(mediaContext: mediaContext)
        let expectedHit = MediaHit.init(eventType: "sessionStart", playhead: expectedPlayhead, ts: expectedTimestamp, params: params, customMetadata: metadata, qoeData: emptyQoeData)
        let generatedHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedHit, generatedHit)
    }
    
    func testMediaStart_ForceResumeTrue() {
        // test
        hitGenerator.processMediaStart(forceResume: true)
        // verify
        var params = MediaCollectionHelper.extractMediaParams(mediaContext: mediaContext)
        params[MediaConstants.MediaCollection.Media.DOWNLOADED] = true
        params[MediaConstants.MediaCollection.Media.RESUME] = true
        let metadata = MediaCollectionHelper.extractMediaMetadata(mediaContext: mediaContext)
        let expectedHit = MediaHit.init(eventType: "sessionStart", playhead: expectedPlayhead, ts: expectedTimestamp, params: params, customMetadata: metadata, qoeData: emptyQoeData)
        let generatedHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedHit, generatedHit)
    }
    
    func testMediaComplete() {
        // test
        hitGenerator.processMediaComplete()
        // verify
        let expectedHit = MediaHit.init(eventType: "sessionComplete", playhead: expectedPlayhead, ts: expectedTimestamp, params: emptyParams, customMetadata: emptyMetadata, qoeData: emptyQoeData)
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
        let adBreakInfo = AdBreakInfo(info: MediaCollectionHitGeneratorTests.validAdbreakInfo)
        mediaContext.setAdBreakInfo(adBreakInfo: adBreakInfo)

        let adInfo = AdInfo(info: MediaCollectionHitGeneratorTests.validAdInfo)
        let adMetadata = ["k1": "v1", "a.media.ad.advertisier":"advertiser"]
        mediaContext.setAdInfo(adInfo: adInfo, metadata: adMetadata)

        let chapterInfo = ChapterInfo(info: MediaCollectionHitGeneratorTests.validChapterInfo)
        let chapterMetadata = ["k1": "v1"]
        mediaContext.setChapterInfo(chapterInfo: chapterInfo, metadata: chapterMetadata)
        
        var params = MediaCollectionHelper.extractMediaParams(mediaContext: mediaContext)
        params[MediaConstants.MediaCollection.Media.DOWNLOADED] = true
        params[MediaConstants.MediaCollection.Media.RESUME] = true
        let metadata = MediaCollectionHelper.extractMediaMetadata(mediaContext: mediaContext)
        
        mediaContext.enterState(MediaPlaybackState.Play)
        
        let config = [MediaConstants.TrackerConfig.DOWNLOADED_CONTENT: true]
        self.hitGenerator = MediaCollectionHitGenerator.init(context: mediaContext, hitProcessor: hitProcessor, config: config, refTS: expectedTimestamp)
        // test
        hitGenerator.processSessionRestart()
        // verify number hits
        XCTAssertEqual(5, hitProcessor.getHitCountFromActiveSession())
        // verify media start hit
        let expectedMediaStartHit = MediaHit.init(eventType: "sessionStart", playhead: expectedPlayhead, ts: expectedTimestamp, params: params, customMetadata: metadata, qoeData: emptyQoeData)
        let mediaStartHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedMediaStartHit, mediaStartHit)
        // verify chapter start hit
        let expectedChapterStartHit = MediaHit.init(eventType: "chapterStart", playhead: expectedPlayhead, ts: expectedTimestamp, params: emptyParams, customMetadata: emptyMetadata, qoeData: emptyQoeData)
        let chapterStartHit = hitProcessor.getHitFromActiveSession(index: 1)
        XCTAssertEqual(expectedChapterStartHit, chapterStartHit)
        // verify ad break start hit
        let expectedAdBreakStartHit = MediaHit.init(eventType: "adBreakStart", playhead: expectedPlayhead, ts: expectedTimestamp, params: emptyParams, customMetadata: emptyMetadata, qoeData: emptyQoeData)
        let adBreakStartHit = hitProcessor.getHitFromActiveSession(index: 2)
        XCTAssertEqual(adBreakStartHit, expectedAdBreakStartHit)
        // verify ad start
        let expectedAdStartHit = MediaHit.init(eventType: "adStart", playhead: expectedPlayhead, ts: expectedTimestamp, params: emptyParams, customMetadata: emptyMetadata, qoeData: emptyQoeData)
        let adStartHit = hitProcessor.getHitFromActiveSession(index: 3)
        XCTAssertEqual(adStartHit, expectedAdStartHit)
        // verify play
        let expectedPlayHit = MediaHit.init(eventType: "play", playhead: expectedPlayhead, ts: expectedTimestamp, params: emptyParams, customMetadata: emptyMetadata, qoeData: emptyQoeData)
        let playHit = hitProcessor.getHitFromActiveSession(index: 4)
        XCTAssertEqual(expectedPlayHit, playHit)
    }
    
    func testProcessIdleCompleteOnline() {
        // setup
        let adBreakInfo = AdBreakInfo(info: MediaCollectionHitGeneratorTests.validAdbreakInfo)
        mediaContext.setAdBreakInfo(adBreakInfo: adBreakInfo)

        let adInfo = AdInfo(info: MediaCollectionHitGeneratorTests.validAdInfo)
        let adMetadata = ["k1": "v1", "a.media.ad.advertisier":"advertiser"]
        mediaContext.setAdInfo(adInfo: adInfo, metadata: adMetadata)

        let chapterInfo = ChapterInfo(info: MediaCollectionHitGeneratorTests.validChapterInfo)
        let chapterMetadata = ["k1": "v1"]
        mediaContext.setChapterInfo(chapterInfo: chapterInfo, metadata: chapterMetadata)
        
        var params = MediaCollectionHelper.extractMediaParams(mediaContext: mediaContext)
        params[MediaConstants.MediaCollection.Media.DOWNLOADED] = false
        params[MediaConstants.MediaCollection.Media.RESUME] = true
        let metadata = MediaCollectionHelper.extractMediaMetadata(mediaContext: mediaContext)
        mediaContext.enterState(MediaPlaybackState.Play)
        let config = [MediaConstants.TrackerConfig.DOWNLOADED_CONTENT: false]
        self.hitGenerator = MediaCollectionHitGenerator.init(context: mediaContext, hitProcessor: hitProcessor, config: config, refTS: expectedTimestamp)
        // test
        hitGenerator.processSessionRestart()
        // verify number hits
        XCTAssertEqual(5, hitProcessor.getHitCountFromActiveSession())
        // verify media start hit
        let expectedMediaStartHit = MediaHit.init(eventType: "sessionStart", playhead: expectedPlayhead, ts: expectedTimestamp, params: params, customMetadata: metadata, qoeData: emptyQoeData)
        let mediaStartHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedMediaStartHit, mediaStartHit)
        // verify chapter start hit
        let expectedChapterStartHit = MediaHit.init(eventType: "chapterStart", playhead: expectedPlayhead, ts: expectedTimestamp, params: emptyParams, customMetadata: emptyMetadata, qoeData: emptyQoeData)
        let chapterStartHit = hitProcessor.getHitFromActiveSession(index: 1)
        XCTAssertEqual(expectedChapterStartHit, chapterStartHit)
        // verify ad break start hit
        let expectedAdBreakStartHit = MediaHit.init(eventType: "adBreakStart", playhead: expectedPlayhead, ts: expectedTimestamp, params: emptyParams, customMetadata: emptyMetadata, qoeData: emptyQoeData)
        let adBreakStartHit = hitProcessor.getHitFromActiveSession(index: 2)
        XCTAssertEqual(adBreakStartHit, expectedAdBreakStartHit)
        // verify ad start
        let expectedAdStartHit = MediaHit.init(eventType: "adStart", playhead: expectedPlayhead, ts: expectedTimestamp, params: emptyParams, customMetadata: emptyMetadata, qoeData: emptyQoeData)
        let adStartHit = hitProcessor.getHitFromActiveSession(index: 3)
        XCTAssertEqual(adStartHit, expectedAdStartHit)
        // verify play
        let expectedPlayHit = MediaHit.init(eventType: "play", playhead: expectedPlayhead, ts: expectedTimestamp, params: emptyParams, customMetadata: emptyMetadata, qoeData: emptyQoeData)
        let playHit = hitProcessor.getHitFromActiveSession(index: 4)
        XCTAssertEqual(expectedPlayHit, playHit)
    }
    
    func testProcessIdleCompleteStateTrackingResumesAfterIdle() {
        // setup
        let stateInfo = StateInfo(stateName: "fullscreen")
        mediaContext.enterState(MediaPlaybackState.Play)
        _ = mediaContext.startState(stateInfo)
        var params = MediaCollectionHelper.extractMediaParams(mediaContext: mediaContext)
        params[MediaConstants.MediaCollection.Media.DOWNLOADED] = true
        params[MediaConstants.MediaCollection.Media.RESUME] = true
        let metadata = MediaCollectionHelper.extractMediaMetadata(mediaContext: mediaContext)
        let config = [MediaConstants.TrackerConfig.DOWNLOADED_CONTENT: true]
        self.hitGenerator = MediaCollectionHitGenerator.init(context: mediaContext, hitProcessor: hitProcessor, config: config, refTS: expectedTimestamp)
        // test
        hitGenerator.processSessionRestart()
        // verify number hits
        XCTAssertEqual(3, hitProcessor.getHitCountFromActiveSession())
        // verify media start hit
        let expectedMediaStartHit = MediaHit.init(eventType: "sessionStart", playhead: expectedPlayhead, ts: expectedTimestamp, params: params, customMetadata: metadata, qoeData: emptyQoeData)
        let mediaStartHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedMediaStartHit, mediaStartHit)
        // verify state start hit
        let startParams = ["state.name": "fullscreen"]
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
        mediaContext.enterState(MediaPlaybackState.Play)
        var params = MediaCollectionHelper.extractMediaParams(mediaContext: mediaContext)
        params[MediaConstants.MediaCollection.Media.DOWNLOADED] = true
        params[MediaConstants.MediaCollection.Media.RESUME] = true
        let metadata = MediaCollectionHelper.extractMediaMetadata(mediaContext: mediaContext)
        let config = [MediaConstants.TrackerConfig.DOWNLOADED_CONTENT: true]
        self.hitGenerator = MediaCollectionHitGenerator.init(context: mediaContext, hitProcessor: hitProcessor, config: config, refTS: expectedTimestamp)
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
        let stateInfo = StateInfo(stateName: "fullscreen")
        mediaContext.enterState(MediaPlaybackState.Play)
        _ = mediaContext.startState(stateInfo)
        _ = mediaContext.endState(stateInfo)
        _ = mediaContext.startState(stateInfo)
        var params = MediaCollectionHelper.extractMediaParams(mediaContext: mediaContext)
        params[MediaConstants.MediaCollection.Media.DOWNLOADED] = true
        params[MediaConstants.MediaCollection.Media.RESUME] = true
        let metadata = MediaCollectionHelper.extractMediaMetadata(mediaContext: mediaContext)
        let config = [MediaConstants.TrackerConfig.DOWNLOADED_CONTENT: true]
        self.hitGenerator = MediaCollectionHitGenerator.init(context: mediaContext, hitProcessor: hitProcessor, config: config, refTS: expectedTimestamp)
        // test
        hitGenerator.processSessionRestart()
        // verify number hits
        XCTAssertEqual(3, hitProcessor.getHitCountFromActiveSession())
        // verify media start hit
        let expectedMediaStartHit = MediaHit.init(eventType: "sessionStart", playhead: expectedPlayhead, ts: expectedTimestamp, params: params, customMetadata: metadata, qoeData: emptyQoeData)
        let mediaStartHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedMediaStartHit, mediaStartHit)
        // verify state start hit
        let startParams = ["state.name": "fullscreen"]
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
        var params = MediaCollectionHelper.extractMediaParams(mediaContext: mediaContext)
        params[MediaConstants.MediaCollection.Media.DOWNLOADED] = true
        params[MediaConstants.MediaCollection.Media.RESUME] = true
        let config = [MediaConstants.TrackerConfig.DOWNLOADED_CONTENT: true]
        self.hitGenerator = MediaCollectionHitGenerator.init(context: mediaContext, hitProcessor: hitProcessor, config: config, refTS: expectedTimestamp)
        // test
        hitGenerator.processPlayback()
        XCTAssertEqual(0, hitProcessor.getHitCount(sessionId: self.expectedSessionId))
        // play hit
        mediaContext.enterState(MediaPlaybackState.Play)
        hitGenerator.processPlayback()
        XCTAssertEqual(1, hitProcessor.getHitCountFromActiveSession())
        let expectedPlayHit = MediaHit.init(eventType: "play", playhead: expectedPlayhead, ts: expectedTimestamp, params: emptyParams, customMetadata: emptyMetadata, qoeData: emptyQoeData)
        let playHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedPlayHit, playHit)
        hitProcessor.clearHitsFromActiveSession()
        // buffer start hit
        mediaContext.enterState(MediaPlaybackState.Buffer)
        hitGenerator.mediaContext = mediaContext
        hitGenerator.processPlayback()
        XCTAssertEqual(1, hitProcessor.getHitCountFromActiveSession())
        let expectedBufferStartHit = MediaHit.init(eventType: "bufferStart", playhead: expectedPlayhead, ts: expectedTimestamp, params: emptyParams, customMetadata: emptyMetadata, qoeData: emptyQoeData)
        let bufferStartHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedBufferStartHit, bufferStartHit)
        hitProcessor.clearHitsFromActiveSession()
        // buffer end hit (will be play)
        mediaContext.exitState(MediaPlaybackState.Buffer)
        hitGenerator.mediaContext = mediaContext
        hitGenerator.processPlayback()
        XCTAssertEqual(1, hitProcessor.getHitCountFromActiveSession())
        let expectedBufferEndHit = MediaHit.init(eventType: "play", playhead: expectedPlayhead, ts: expectedTimestamp, params: emptyParams, customMetadata: emptyMetadata, qoeData: emptyQoeData)
        let bufferEndHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedBufferEndHit, bufferEndHit)
        hitProcessor.clearHitsFromActiveSession()
        // start seek hit
        mediaContext.enterState(MediaPlaybackState.Seek)
        hitGenerator.mediaContext = mediaContext
        hitGenerator.processPlayback()
        XCTAssertEqual(1, hitProcessor.getHitCountFromActiveSession())
        let expectedSeekStartHit = MediaHit.init(eventType: "pauseStart", playhead: expectedPlayhead, ts: expectedTimestamp, params: emptyParams, customMetadata: emptyMetadata, qoeData: emptyQoeData)
        let seekStartHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedSeekStartHit, seekStartHit)
        hitProcessor.clearHitsFromActiveSession()
        // exit seek hit
        mediaContext.exitState(MediaPlaybackState.Seek)
        hitGenerator.mediaContext = mediaContext
        hitGenerator.processPlayback()
        XCTAssertEqual(1, hitProcessor.getHitCountFromActiveSession())
        let expectedSeekExitHit = MediaHit.init(eventType: "play", playhead: expectedPlayhead, ts: expectedTimestamp, params: emptyParams, customMetadata: emptyMetadata, qoeData: emptyQoeData)
        let seekExitHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedSeekExitHit, seekExitHit)
        hitProcessor.clearHitsFromActiveSession()
        // pause hit
        mediaContext.enterState(MediaPlaybackState.Pause)
        hitGenerator.mediaContext = mediaContext
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
        let params = ["state.name": "fullscreen"]
        let expectedStateStartHit = MediaHit.init(eventType: "stateStart", playhead: expectedPlayhead, ts: expectedTimestamp, params: params, customMetadata: emptyMetadata, qoeData: emptyQoeData)
        let stateStartHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedStateStartHit, stateStartHit)
    }
    
    func testProcessStateStartShouldNotSendQoEData() {
        // setup
        guard let qoeInfo = QoEInfo(info: MediaCollectionHitGeneratorTests.validQoEInfo) else {
            XCTFail("qoe info creation failed")
            return
        }
        mediaContext.setQoeInfo(qoeInfo: qoeInfo)
        guard let stateInfo = StateInfo(stateName: "fullscreen") else {
            XCTFail("state creation failed")
            return
        }
        // test
        hitGenerator.processStateStart(stateInfo: stateInfo)
        // verify state start hit + empty qoe info
        XCTAssertEqual(1, hitProcessor.getHitCount(sessionId: self.expectedSessionId))
        let params = ["state.name": "fullscreen"]
        let expectedStateStartHit = MediaHit.init(eventType: "stateStart", playhead: expectedPlayhead, ts: expectedTimestamp, params: params, customMetadata: emptyMetadata, qoeData: emptyQoeData)
        let stateStartHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedStateStartHit, stateStartHit)
    }
    
    func testProcessStateStartShouldSendQoEDataInNextPingAfterStateStart() {
        // setup
        guard let qoeInfo = QoEInfo(info: MediaCollectionHitGeneratorTests.validQoEInfo) else {
            XCTFail("qoe info creation failed")
            return
        }
        mediaContext.setQoeInfo(qoeInfo: qoeInfo)
        guard let stateInfo = StateInfo(stateName: "fullscreen") else {
            XCTFail("state creation failed")
            return
        }
        // test
        hitGenerator.processStateStart(stateInfo: stateInfo)
        // verify state start hit + empty qoe info
        XCTAssertEqual(1, hitProcessor.getHitCount(sessionId: self.expectedSessionId))
        let params = ["state.name": "fullscreen"]
        let expectedStateStartHit = MediaHit.init(eventType: "stateStart", playhead: expectedPlayhead, ts: expectedTimestamp, params: params, customMetadata: emptyMetadata, qoeData: emptyQoeData)
        let stateStartHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedStateStartHit, stateStartHit)
        // clear hits
        hitProcessor.clearHitsFromActiveSession()
        // second hit should have qoe info
        mediaContext.enterState(MediaPlaybackState.Play)
        hitGenerator.processPlayback()
        XCTAssertEqual(1, hitProcessor.getHitCount(sessionId: self.expectedSessionId))
        let expectedSecondHit = MediaHit.init(eventType: "play", playhead: expectedPlayhead, ts: expectedTimestamp, params: emptyParams, customMetadata: emptyMetadata, qoeData: MediaCollectionHitGeneratorTests.validQoEInfo)
        let secondHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedSecondHit, secondHit)
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
        let params = ["state.name": "fullscreen"]
        let expectedStateEndHit = MediaHit.init(eventType: "stateEnd", playhead: expectedPlayhead, ts: expectedTimestamp, params: params, customMetadata: emptyMetadata, qoeData: emptyQoeData)
        let stateEndHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedStateEndHit, stateEndHit)
    }
    
    func testProcessStateEndShouldNotSendQoEData() {
        // setup
        guard let qoeInfo = QoEInfo(info: MediaCollectionHitGeneratorTests.validQoEInfo) else {
            XCTFail("qoe info creation failed")
            return
        }
        mediaContext.setQoeInfo(qoeInfo: qoeInfo)
        guard let stateInfo = StateInfo(stateName: "fullscreen") else {
            XCTFail("state creation failed")
            return
        }
        // test
        hitGenerator.processStateEnd(stateInfo: stateInfo)
        // verify state end hit + empty qoe info
        XCTAssertEqual(1, hitProcessor.getHitCount(sessionId: self.expectedSessionId))
        let params = ["state.name": "fullscreen"]
        let expectedStateEndHit = MediaHit.init(eventType: "stateEnd", playhead: expectedPlayhead, ts: expectedTimestamp, params: params, customMetadata: emptyMetadata, qoeData: emptyQoeData)
        let stateEndHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedStateEndHit, stateEndHit)
    }
    
    func testProcessStateEndShouldSendQoEDataInNextPingAfterStateStart() {
        // setup
        guard let qoeInfo = QoEInfo(info: MediaCollectionHitGeneratorTests.validQoEInfo) else {
            XCTFail("qoe info creation failed")
            return
        }
        mediaContext.setQoeInfo(qoeInfo: qoeInfo)
        guard let stateInfo = StateInfo(stateName: "fullscreen") else {
            XCTFail("state creation failed")
            return
        }
        // test
        hitGenerator.processStateEnd(stateInfo: stateInfo)
        // verify state end hit + empty qoe info
        XCTAssertEqual(1, hitProcessor.getHitCount(sessionId: self.expectedSessionId))
        let params = ["state.name": "fullscreen"]
        let expectedStateEndHit = MediaHit.init(eventType: "stateEnd", playhead: expectedPlayhead, ts: expectedTimestamp, params: params, customMetadata: emptyMetadata, qoeData: emptyQoeData)
        let stateEndHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedStateEndHit, stateEndHit)
        // clear hits
        hitProcessor.clearHitsFromActiveSession()
        // second hit should have qoe info
        mediaContext.enterState(MediaPlaybackState.Play)
        hitGenerator.processPlayback()
        XCTAssertEqual(1, hitProcessor.getHitCount(sessionId: self.expectedSessionId))
        let expectedSecondHit = MediaHit.init(eventType: "play", playhead: expectedPlayhead, ts: expectedTimestamp, params: emptyParams, customMetadata: emptyMetadata, qoeData: MediaCollectionHitGeneratorTests.validQoEInfo)
        let secondHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedSecondHit, secondHit)
    }
    
    func testProcessPlaybackStateSameStateOnline() {
        // setup
        mediaContext.enterState(MediaPlaybackState.Play)
        let config = [MediaConstants.TrackerConfig.DOWNLOADED_CONTENT: false]
        self.hitGenerator = MediaCollectionHitGenerator.init(context: mediaContext, hitProcessor: hitProcessor, config: config, refTS: expectedTimestamp)
        var params = MediaCollectionHelper.extractMediaParams(mediaContext: mediaContext)
        params[MediaConstants.MediaCollection.Media.DOWNLOADED] = false
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
        hitGenerator.setRefTS(ts: 100)
        hitGenerator.processPlayback()
        XCTAssertEqual(1, hitProcessor.getHitCountFromActiveSession())
    }
    
    func testProcessPlaybackSameStateInit() {
        // no hit due to the current state == previous state and offline ping interval not elapsed
        hitGenerator.processPlayback()
        XCTAssertEqual(0, hitProcessor.getHitCountFromActiveSession())
        // no hit due to timestamp being lower than default offline ping interval
        hitGenerator.setRefTS(ts: 10)
        hitGenerator.processPlayback()
        XCTAssertEqual(0, hitProcessor.getHitCountFromActiveSession())
        // expect 1 hit due to timestamp >= the default offline ping interval
        hitGenerator.setRefTS(ts: 50)
        hitGenerator.processPlayback()
        XCTAssertEqual(1, hitProcessor.getHitCountFromActiveSession())
        let expectedPingHit = MediaHit.init(eventType: "ping", playhead: expectedPlayhead, ts: 50, params: emptyParams, customMetadata: emptyMetadata, qoeData: emptyQoeData)
        let pingHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedPingHit, pingHit)
    }
    
    func testProcessPlaybackSameStateInitOnline() {
        // setup
        let config = [MediaConstants.TrackerConfig.DOWNLOADED_CONTENT: false]
        self.hitGenerator = MediaCollectionHitGenerator.init(context: mediaContext, hitProcessor: hitProcessor, config: config, refTS: expectedTimestamp)
        // no hit due to the current state == previous state and online ping interval not elapsed
        hitGenerator.processPlayback()
        XCTAssertEqual(0, hitProcessor.getHitCountFromActiveSession())
        // expect 1 hit due to timestamp >= default online ping interval
        hitGenerator.setRefTS(ts: 10)
        hitGenerator.processPlayback()
        XCTAssertEqual(1, hitProcessor.getHitCountFromActiveSession())
        var expectedPingHit = MediaHit.init(eventType: "ping", playhead: expectedPlayhead, ts: 10, params: emptyParams, customMetadata: emptyMetadata, qoeData: emptyQoeData)
        var pingHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedPingHit, pingHit)
        // expect another hit due to timestamp >= the default online ping interval
        hitGenerator.setRefTS(ts: 50)
        hitGenerator.processPlayback()
        XCTAssertEqual(2, hitProcessor.getHitCountFromActiveSession())
        expectedPingHit = MediaHit.init(eventType: "ping", playhead: expectedPlayhead, ts: 50, params: emptyParams, customMetadata: emptyMetadata, qoeData: emptyQoeData)
        pingHit = hitProcessor.getHitFromActiveSession(index: 1)
        XCTAssertEqual(expectedPingHit, pingHit)
    }
    
    func testprocessPlaybackSameStateTimeout() {
        // trigger play hit
        mediaContext.enterState(MediaPlaybackState.Play)
        hitGenerator.processPlayback()
        XCTAssertEqual(1, hitProcessor.getHitCountFromActiveSession())
        let expectedPlayHit = MediaHit.init(eventType: "play", playhead: expectedPlayhead, ts: 0, params: emptyParams, customMetadata: emptyMetadata, qoeData: emptyQoeData)
        let playHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedPlayHit, playHit)
        hitProcessor.clearHitsFromActiveSession()
        // expect ping hit due to timestamp >= default online ping interval but current state == previous state
        hitGenerator.setRefTS(ts: 51)
        hitGenerator.processPlayback()
        XCTAssertEqual(1, hitProcessor.getHitCountFromActiveSession())
        let expectedPingHit = MediaHit.init(eventType: "ping", playhead: expectedPlayhead, ts: 51, params: emptyParams, customMetadata: emptyMetadata, qoeData: emptyQoeData)
        let pingHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedPingHit, pingHit)
    }
    
    func testprocessPlaybackFlush() {
        // trigger play hit
        mediaContext.enterState(MediaPlaybackState.Play)
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
        guard let qoeInfo = QoEInfo(info: MediaCollectionHitGeneratorTests.validQoEInfo) else {
            XCTFail("qoe info creation failed")
            return
        }
        mediaContext.setQoeInfo(qoeInfo: qoeInfo)
        // test
        hitGenerator.processError(errorId: "error-id")
        // verify
        var expectedQoeInfo = MediaCollectionHitGeneratorTests.validQoEInfo
        expectedQoeInfo.merge([MediaConstants.MediaCollection.QoE.ERROR_SOURCE: MediaConstants.MediaCollection.QoE.ERROR_SOURCE_PLAYER, MediaConstants.MediaCollection.QoE.ERROR_ID: "error-id"], uniquingKeysWith: { _, new in new })
        XCTAssertEqual(1, hitProcessor.getHitCount(sessionId: self.expectedSessionId))
        let expectedErrorHit = MediaHit.init(eventType: "error", playhead: expectedPlayhead, ts: expectedTimestamp, params: emptyParams, customMetadata: emptyMetadata, qoeData: expectedQoeInfo)
        let errorHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedErrorHit, errorHit)
    }
    
    func testGenerateHitAfterMediaSession() {
        // test
        hitGenerator.endTrackingSession()
        hitGenerator.processPlayback()
        // verify no hit because tracking is stopped
        XCTAssertEqual(0, hitProcessor.getHitCountFromActiveSession())
    }
    
    func testGenerateHitAfterMediaSession2() {
        // test
        hitGenerator.endTrackingSession()
        hitGenerator.generateHit(eventType: MediaConstants.EventName.PLAY, params: emptyParams, metadata: emptyMetadata, qoeData: emptyQoeData)
        // verify no hit because tracking is stopped
        XCTAssertEqual(0, hitProcessor.getHitCountFromActiveSession())
    }
    
    func testGenerateHitProcessQoEChange() {
        // setup
        guard let qoeInfo = QoEInfo(info: MediaCollectionHitGeneratorTests.validQoEInfo) else {
            XCTFail("qoe info creation failed")
            return
        }
        mediaContext.setQoeInfo(qoeInfo: qoeInfo)
        // test
        hitGenerator.processBitrateChange()
        // verify bitrate change hit + qoe info
        XCTAssertEqual(1, hitProcessor.getHitCount(sessionId: self.expectedSessionId))
        let expectedBitrateChangeHit = MediaHit.init(eventType: "bitrateChange", playhead: expectedPlayhead, ts: 0, params: emptyParams, customMetadata: emptyMetadata, qoeData: MediaCollectionHitGeneratorTests.validQoEInfo)
        let bitrateChangeHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedBitrateChangeHit, bitrateChangeHit)
        // clear hits
        hitProcessor.clearHitsFromActiveSession()
        // test second bitrate change
        hitGenerator.processBitrateChange()
        // verify second bitrate change hit + qoe info
        XCTAssertEqual(1, hitProcessor.getHitCount(sessionId: self.expectedSessionId))
        let nextExpectedBitrateChangeHit = MediaHit.init(eventType: "bitrateChange", playhead: expectedPlayhead, ts: 0, params: emptyParams, customMetadata: emptyMetadata, qoeData: MediaCollectionHitGeneratorTests.validQoEInfo)
        let nextBitrateChangeHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(nextExpectedBitrateChangeHit, nextBitrateChangeHit)
        // clear hits
        hitProcessor.clearHitsFromActiveSession()
        // setup new qoeInfo
        guard let qoeInfo2 = QoEInfo(info: [MediaConstants.QoEInfo.BITRATE : 48.0,
                                            MediaConstants.QoEInfo.DROPPED_FRAMES : 4.0,
                                            MediaConstants.QoEInfo.FPS : 60.0,
                                            MediaConstants.QoEInfo.STARTUP_TIME : 1.0]) else {
            XCTFail("qoe info creation failed")
            return
        }
        mediaContext.setQoeInfo(qoeInfo: qoeInfo2)
        // test
        hitGenerator.processBitrateChange()
        // verify third bitrate change hit + new qoe info
        XCTAssertEqual(1, hitProcessor.getHitCount(sessionId: self.expectedSessionId))
        let lastExpectedBitrateChangeHit = MediaHit.init(eventType: "bitrateChange", playhead: expectedPlayhead, ts: 0, params: emptyParams, customMetadata: emptyMetadata, qoeData: qoeInfo2.toMap())
        let lastBitrateChangeHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(lastExpectedBitrateChangeHit, lastBitrateChangeHit)
    }
    
    func testGenerateHitUpdatedQoEInfo() {
        // test
        hitGenerator.generateHit(eventType: MediaConstants.EventName.PLAY)
        guard let newQoeInfo = QoEInfo(info: [MediaConstants.QoEInfo.BITRATE : 10000.0,
                                              MediaConstants.QoEInfo.DROPPED_FRAMES : 4.0,
                                              MediaConstants.QoEInfo.FPS : 60.0,
                                              MediaConstants.QoEInfo.STARTUP_TIME : 1.0]) else {
            XCTFail("qoe info creation failed")
            return
        }
        hitGenerator.generateHit(eventType: MediaConstants.EventName.PLAY, params: emptyParams, metadata: emptyMetadata, qoeData: newQoeInfo.toMap())
        // verify updated Qoe Info is present in second hit
        let expectedHit = MediaHit.init(eventType: "play", playhead: expectedPlayhead, ts: 0, params: emptyParams, customMetadata: emptyMetadata, qoeData: newQoeInfo.toMap())
        let actualHit = hitProcessor.getHitFromActiveSession(index: 1)
        XCTAssertEqual(expectedHit, actualHit)
    }
    
    func testGetPlaybackStateMediaContextState() {
        let states = [MediaPlaybackState.Init, MediaPlaybackState.Play, MediaPlaybackState.Pause, MediaPlaybackState.Seek, MediaPlaybackState.Buffer, MediaPlaybackState.Stall]
        
        for state in states {
            mediaContext.enterState(state)
            hitGenerator.mediaContext = mediaContext
            let playbackState = hitGenerator.getPlaybackState()
            XCTAssertEqual(state, playbackState)
            mediaContext.exitState(state)
        }
    }
    
    func testGetMediaCollectionEventForMediaPlaybackState() {
        let playbackStateToMediaCollectionDict = [MediaPlaybackState.Init: MediaConstants.MediaCollection.EventType.PING, MediaPlaybackState.Play: MediaConstants.MediaCollection.EventType.PLAY, MediaPlaybackState.Pause: MediaConstants.MediaCollection.EventType.PAUSE_START, MediaPlaybackState.Buffer: MediaConstants.MediaCollection.EventType.BUFFER_START, MediaPlaybackState.Seek: MediaConstants.MediaCollection.EventType.PAUSE_START, MediaPlaybackState.Stall: MediaConstants.MediaCollection.EventType.PLAY]
        let states = [MediaPlaybackState.Init, MediaPlaybackState.Play, MediaPlaybackState.Pause, MediaPlaybackState.Seek, MediaPlaybackState.Buffer, MediaPlaybackState.Stall]
        
        for state in states {
            let actual = hitGenerator.getMediaCollectionEvent(state: state)
            let expected = playbackStateToMediaCollectionDict[state]
            XCTAssertEqual(actual, expected)
        }
    }
}
