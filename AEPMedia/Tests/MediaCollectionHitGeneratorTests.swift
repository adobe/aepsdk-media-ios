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
    private let emptyQOEData:[String: Any] = [:]
    private let emptyMetadata:[String: String] = [:]
    private var mediaInfo: MediaInfo!
    private var hitProcessor: MockMediaHitProcessor!
    private var hitGenerator: MediaCollectionHitGenerator!
    private var mediaContext: MediaContext!
    private let expectedSessionId = 0
    private let expectedPlayhead: Double = 50
    private let expectedTimestamp = TimeInterval(0)

    override func setUp() {
        let info = ["media.id":"testId", "media.name":"testName", "media.streamtype":"video", "media.contenttype":"vod", "media.type":"video", "media.length": 10.0, "media.resume": false] as [String : Any]
        mediaInfo = MediaInfo.createFrom(info: info)
        let metadata = ["k1": "v1", "a.media.show": "show"]
        let config = [MediaConstants.Configuration.DOWNLOADED_CONTENT: true]
        self.mediaContext = MediaContext(mediaInfo: mediaInfo, metadata: metadata)
        self.hitProcessor = MockMediaHitProcessor()
        self.hitGenerator = MediaCollectionHitGenerator.init(context: mediaContext, hitProcessor: hitProcessor, config: config, timestamp: expectedTimestamp)
    }

    override func tearDown() {
        self.mediaContext = nil
        self.hitProcessor = nil
        self.hitGenerator = nil
    }
    
    // TODO: add QoEInfo tests
    // add test testProcessStateStartShouldNotSendQoEData
    // add test testProcessStateStartShouldSendQoEDataInNextPingAfterStateStart
    // add test for testProcessError
    // add test for testGenerateHitProcessQoEChange
    // add test for testGenerateHitUpdatedQoEInfo
    // add test testProcessStateEndShouldNotSendQoEData
    // add test testProcessStateEndShouldSendQoEDataInNextPingAfterStateStart

    //MARK: MediaCollectionHitGenerator Unit Tests
    func testMediaStart() {
        // test
        hitGenerator.processMediaStart()
        // verify
        var params = MediaCollectionHelper.extractMediaParams(mediaContext: mediaContext)
        params[MediaConstants.MediaCollection.Media.DOWNLOADED] = true
        let metadata = MediaCollectionHelper.extractMediaMetadata(mediaContext: mediaContext)
        let expectedHit = MediaHit.init(eventType: "sessionStart", params: params, metadata: metadata, QOEData: emptyQOEData, playhead: expectedPlayhead, ts: expectedTimestamp)
        let generatedHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedHit, generatedHit)
    }
    
    func testMediaStartOnline() {
        // setup
        let config = [MediaConstants.Configuration.DOWNLOADED_CONTENT: false]
        hitGenerator = MediaCollectionHitGenerator.init(context: mediaContext, hitProcessor: hitProcessor, config: config, timestamp: expectedTimestamp)
        // test
        hitGenerator.processMediaStart()
        // verify
        var params = MediaCollectionHelper.extractMediaParams(mediaContext: mediaContext)
        params[MediaConstants.MediaCollection.Media.DOWNLOADED] = false
        let metadata = MediaCollectionHelper.extractMediaMetadata(mediaContext: mediaContext)
        let expectedHit = MediaHit.init(eventType: "sessionStart", params: params, metadata: metadata, QOEData: emptyQOEData, playhead: expectedPlayhead, ts: expectedTimestamp)
        let generatedHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedHit, generatedHit)
    }
    
    func testMediaStartWithConfig() {
        // setup
        let config: [String: Any] = [MediaConstants.Configuration.DOWNLOADED_CONTENT: true, MediaConstants.Configuration.CHANNEL: "test-channel"]
        hitGenerator = MediaCollectionHitGenerator.init(context: mediaContext, hitProcessor: hitProcessor, config: config, timestamp: expectedTimestamp)
        // test
        hitGenerator.processMediaStart()
        // verify
        var params = MediaCollectionHelper.extractMediaParams(mediaContext: mediaContext)
        params[MediaConstants.MediaCollection.Media.DOWNLOADED] = true
        params[MediaConstants.MediaCollection.Media.CHANNEL] = "test-channel"
        let metadata = MediaCollectionHelper.extractMediaMetadata(mediaContext: mediaContext)
        let expectedHit = MediaHit.init(eventType: "sessionStart", params: params, metadata: metadata, QOEData: emptyQOEData, playhead: expectedPlayhead, ts: expectedTimestamp)
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
        let expectedHit = MediaHit.init(eventType: "sessionStart", params: params, metadata: metadata, QOEData: emptyQOEData, playhead: expectedPlayhead, ts: expectedTimestamp)
        let generatedHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedHit, generatedHit)
    }
    
    func testMediaComplete() {
        // test
        hitGenerator.processMediaComplete()
        // verify
        let expectedHit = MediaHit.init(eventType: "sessionComplete", params: emptyParams, metadata: emptyMetadata, QOEData: emptyQOEData, playhead: expectedPlayhead, ts: expectedTimestamp)
        let generatedHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedHit, generatedHit)
    }
    
    func testMediaSkip() {
        // test
        hitGenerator.processMediaSkip()
        // verify
        let expectedHit = MediaHit.init(eventType: "sessionEnd", params: emptyParams, metadata: emptyMetadata, QOEData: emptyQOEData, playhead: expectedPlayhead, ts: expectedTimestamp)
        let generatedHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedHit, generatedHit)
    }
    
    func testAdBreakStart() {
        // test
        hitGenerator.processAdBreakStart()
        // verify
        let expectedHit = MediaHit.init(eventType: "adBreakStart", params: emptyParams, metadata: emptyMetadata, QOEData: emptyQOEData, playhead: expectedPlayhead, ts: expectedTimestamp)
        let generatedHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedHit, generatedHit)
    }
    
    func testAdBreakComplete() {
        // test
        hitGenerator.processAdBreakComplete()
        // verify
        let expectedHit = MediaHit.init(eventType: "adBreakComplete", params: emptyParams, metadata: emptyMetadata, QOEData: emptyQOEData, playhead: expectedPlayhead, ts: expectedTimestamp)
        let generatedHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedHit, generatedHit)
    }
    
    func testAdBreakSkip() {
        // test
        hitGenerator.processAdBreakSkip()
        // verify
        let expectedHit = MediaHit.init(eventType: "adBreakComplete", params: emptyParams, metadata: emptyMetadata, QOEData: emptyQOEData, playhead: expectedPlayhead, ts: expectedTimestamp)
        let generatedHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedHit, generatedHit)
    }
    
    func testAdStart() {
        // test
        hitGenerator.processAdStart()
        // verify
        let expectedHit = MediaHit.init(eventType: "adStart", params: emptyParams, metadata: emptyMetadata, QOEData: emptyQOEData, playhead: expectedPlayhead, ts: expectedTimestamp)
        let generatedHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedHit, generatedHit)
    }
    
    func testAdComplete() {
        // test
        hitGenerator.processAdComplete()
        // verify
        let expectedHit = MediaHit.init(eventType: "adComplete", params: emptyParams, metadata: emptyMetadata, QOEData: emptyQOEData, playhead: expectedPlayhead, ts: expectedTimestamp)
        let generatedHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedHit, generatedHit)
    }
    
    func testAdSkip() {
        // test
        hitGenerator.processAdSkip()
        // verify
        let expectedHit = MediaHit.init(eventType: "adSkip", params: emptyParams, metadata: emptyMetadata, QOEData: emptyQOEData, playhead: expectedPlayhead, ts: expectedTimestamp)
        let generatedHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedHit, generatedHit)
    }
    
    func testChapterStart() {
        // test
        hitGenerator.processChapterStart()
        // verify
        let expectedHit = MediaHit.init(eventType: "chapterStart", params: emptyParams, metadata: emptyMetadata, QOEData: emptyQOEData, playhead: expectedPlayhead, ts: expectedTimestamp)
        let generatedHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedHit, generatedHit)
    }
    
    func testChapterComplete() {
        // test
        hitGenerator.processChapterComplete()
        // verify
        let expectedHit = MediaHit.init(eventType: "chapterComplete", params: emptyParams, metadata: emptyMetadata, QOEData: emptyQOEData, playhead: expectedPlayhead, ts: expectedTimestamp)
        let generatedHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedHit, generatedHit)
    }
    
    func testChapterSkip() {
        // test
        hitGenerator.processChapterSkip()
        // verify
        let expectedHit = MediaHit.init(eventType: "chapterSkip", params: emptyParams, metadata: emptyMetadata, QOEData: emptyQOEData, playhead: expectedPlayhead, ts: expectedTimestamp)
        let generatedHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedHit, generatedHit)
    }
    
    func testProcessIdleStart() {
        // test
        hitGenerator.processSessionAbort()
        // verify
        let expectedHit = MediaHit.init(eventType: "sessionEnd", params: emptyParams, metadata: emptyMetadata, QOEData: emptyQOEData, playhead: expectedPlayhead, ts: expectedTimestamp)
        let generatedHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedHit, generatedHit)
    }
    
    func testProcessIdleComplete() {
        // setup
        let adBreakInfo = AdBreakInfo()
        mediaContext.setAdBreakInfo(adBreakInfo: adBreakInfo)

        let adInfo = AdInfo()
        let adMetadata = ["k1": "v1", "a.media.ad.advertisier":"advertiser"]
        mediaContext.setAdInfo(adInfo: adInfo, metadata: adMetadata)

        let chapterInfo = ChapterInfo()
        let chapterMetadata = ["k1": "v1"]
        mediaContext.setChapterInfo(chapterInfo: chapterInfo, metadata: chapterMetadata)
        
        var params = MediaCollectionHelper.extractMediaParams(mediaContext: mediaContext)
        params[MediaConstants.MediaCollection.Media.DOWNLOADED] = true
        params[MediaConstants.MediaCollection.Media.RESUME] = true
        let metadata = MediaCollectionHelper.extractMediaMetadata(mediaContext: mediaContext)
        
        mediaContext.enterState(MediaPlaybackState.Play)
        
        let config = [MediaConstants.Configuration.DOWNLOADED_CONTENT: true]
        self.hitGenerator = MediaCollectionHitGenerator.init(context: mediaContext, hitProcessor: hitProcessor, config: config, timestamp: expectedTimestamp)
        // test
        hitGenerator.processSessionRestart()
        // verify number hits
        XCTAssertEqual(5, hitProcessor.getHitCountFromActiveSession())
        // verify media start hit
        let expectedMediaStartHit = MediaHit.init(eventType: "sessionStart", params: params, metadata: metadata, QOEData: emptyQOEData, playhead: expectedPlayhead, ts: expectedTimestamp)
        let mediaStartHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedMediaStartHit, mediaStartHit)
        // verify chapter start hit
        let expectedChapterStartHit = MediaHit.init(eventType: "chapterStart", params: emptyParams, metadata: emptyMetadata, QOEData: emptyQOEData, playhead: expectedPlayhead, ts: expectedTimestamp)
        let chapterStartHit = hitProcessor.getHitFromActiveSession(index: 1)
        XCTAssertEqual(expectedChapterStartHit, chapterStartHit)
        // verify ad break start hit
        let expectedAdBreakStartHit = MediaHit.init(eventType: "adBreakStart", params: emptyParams, metadata: emptyMetadata, QOEData: emptyQOEData, playhead: expectedPlayhead, ts: expectedTimestamp)
        let adBreakStartHit = hitProcessor.getHitFromActiveSession(index: 2)
        XCTAssertEqual(adBreakStartHit, expectedAdBreakStartHit)
        // verify ad start
        let expectedAdStartHit = MediaHit.init(eventType: "adStart", params: emptyParams, metadata: emptyMetadata, QOEData: emptyQOEData, playhead: expectedPlayhead, ts: expectedTimestamp)
        let adStartHit = hitProcessor.getHitFromActiveSession(index: 3)
        XCTAssertEqual(adStartHit, expectedAdStartHit)
        // verify play
        let expectedPlayHit = MediaHit.init(eventType: "play", params: emptyParams, metadata: emptyMetadata, QOEData: emptyQOEData, playhead: expectedPlayhead, ts: expectedTimestamp)
        let playHit = hitProcessor.getHitFromActiveSession(index: 4)
        XCTAssertEqual(expectedPlayHit, playHit)
    }
    
    func testProcessIdleCompleteOnline() {
        // setup
        let adBreakInfo = AdBreakInfo()
        mediaContext.setAdBreakInfo(adBreakInfo: adBreakInfo)

        let adInfo = AdInfo()
        let adMetadata = ["k1": "v1", "a.media.ad.advertisier":"advertiser"]
        mediaContext.setAdInfo(adInfo: adInfo, metadata: adMetadata)

        let chapterInfo = ChapterInfo()
        let chapterMetadata = ["k1": "v1"]
        mediaContext.setChapterInfo(chapterInfo: chapterInfo, metadata: chapterMetadata)
        
        var params = MediaCollectionHelper.extractMediaParams(mediaContext: mediaContext)
        params[MediaConstants.MediaCollection.Media.DOWNLOADED] = false
        params[MediaConstants.MediaCollection.Media.RESUME] = true
        let metadata = MediaCollectionHelper.extractMediaMetadata(mediaContext: mediaContext)
        mediaContext.enterState(MediaPlaybackState.Play)
        let config = [MediaConstants.Configuration.DOWNLOADED_CONTENT: false]
        self.hitGenerator = MediaCollectionHitGenerator.init(context: mediaContext, hitProcessor: hitProcessor, config: config, timestamp: expectedTimestamp)
        // test
        hitGenerator.processSessionRestart()
        // verify number hits
        XCTAssertEqual(5, hitProcessor.getHitCountFromActiveSession())
        // verify media start hit
        let expectedMediaStartHit = MediaHit.init(eventType: "sessionStart", params: params, metadata: metadata, QOEData: emptyQOEData, playhead: expectedPlayhead, ts: expectedTimestamp)
        let mediaStartHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedMediaStartHit, mediaStartHit)
        // verify chapter start hit
        let expectedChapterStartHit = MediaHit.init(eventType: "chapterStart", params: emptyParams, metadata: emptyMetadata, QOEData: emptyQOEData, playhead: expectedPlayhead, ts: expectedTimestamp)
        let chapterStartHit = hitProcessor.getHitFromActiveSession(index: 1)
        XCTAssertEqual(expectedChapterStartHit, chapterStartHit)
        // verify ad break start hit
        let expectedAdBreakStartHit = MediaHit.init(eventType: "adBreakStart", params: emptyParams, metadata: emptyMetadata, QOEData: emptyQOEData, playhead: expectedPlayhead, ts: expectedTimestamp)
        let adBreakStartHit = hitProcessor.getHitFromActiveSession(index: 2)
        XCTAssertEqual(adBreakStartHit, expectedAdBreakStartHit)
        // verify ad start
        let expectedAdStartHit = MediaHit.init(eventType: "adStart", params: emptyParams, metadata: emptyMetadata, QOEData: emptyQOEData, playhead: expectedPlayhead, ts: expectedTimestamp)
        let adStartHit = hitProcessor.getHitFromActiveSession(index: 3)
        XCTAssertEqual(adStartHit, expectedAdStartHit)
        // verify play
        let expectedPlayHit = MediaHit.init(eventType: "play", params: emptyParams, metadata: emptyMetadata, QOEData: emptyQOEData, playhead: expectedPlayhead, ts: expectedTimestamp)
        let playHit = hitProcessor.getHitFromActiveSession(index: 4)
        XCTAssertEqual(expectedPlayHit, playHit)
    }
    
    func testProcessIdleCompleteStateTrackingResumesAfterIdle() {
        // setup
        let stateInfo = StateInfo()
        stateInfo.create(name: "fullscreen")
        mediaContext.enterState(MediaPlaybackState.Play)
        _ = mediaContext.startState(stateInfo)
        var params = MediaCollectionHelper.extractMediaParams(mediaContext: mediaContext)
        params[MediaConstants.MediaCollection.Media.DOWNLOADED] = true
        params[MediaConstants.MediaCollection.Media.RESUME] = true
        let metadata = MediaCollectionHelper.extractMediaMetadata(mediaContext: mediaContext)
        let config = [MediaConstants.Configuration.DOWNLOADED_CONTENT: true]
        self.hitGenerator = MediaCollectionHitGenerator.init(context: mediaContext, hitProcessor: hitProcessor, config: config, timestamp: expectedTimestamp)
        // test
        hitGenerator.processSessionRestart()
        // verify number hits
        XCTAssertEqual(3, hitProcessor.getHitCountFromActiveSession())
        // verify media start hit
        let expectedMediaStartHit = MediaHit.init(eventType: "sessionStart", params: params, metadata: metadata, QOEData: emptyQOEData, playhead: expectedPlayhead, ts: expectedTimestamp)
        let mediaStartHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedMediaStartHit, mediaStartHit)
        // verify state start hit
        let startParams = ["state.name": "fullscreen"]
        let expectedStateStartHit = MediaHit.init(eventType: "stateStart", params: startParams, metadata: emptyMetadata, QOEData: emptyQOEData, playhead: expectedPlayhead, ts: expectedTimestamp)
        let stateStartHit = hitProcessor.getHitFromActiveSession(index: 1)
        XCTAssertEqual(expectedStateStartHit, stateStartHit)
        // verify play
        let expectedPlayHit = MediaHit.init(eventType: "play", params: emptyParams, metadata: emptyMetadata, QOEData: emptyQOEData, playhead: expectedPlayhead, ts: expectedTimestamp)
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
        let config = [MediaConstants.Configuration.DOWNLOADED_CONTENT: true]
        self.hitGenerator = MediaCollectionHitGenerator.init(context: mediaContext, hitProcessor: hitProcessor, config: config, timestamp: expectedTimestamp)
        // test
        hitGenerator.processSessionRestart()
        // verify number hits
        XCTAssertEqual(2, hitProcessor.getHitCountFromActiveSession())
        // verify media start hit
        let expectedMediaStartHit = MediaHit.init(eventType: "sessionStart", params: params, metadata: metadata, QOEData: emptyQOEData, playhead: expectedPlayhead, ts: expectedTimestamp)
        let mediaStartHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedMediaStartHit, mediaStartHit)
        // verify play
        let expectedPlayHit = MediaHit.init(eventType: "play", params: emptyParams, metadata: emptyMetadata, QOEData: emptyQOEData, playhead: expectedPlayhead, ts: expectedTimestamp)
        let playHit = hitProcessor.getHitFromActiveSession(index: 1)
        XCTAssertEqual(expectedPlayHit, playHit)
    }
    
    func testProcessIdleCompleteStateTrackingResumesAfterIdle2() {
        // setup
        let stateInfo = StateInfo()
        stateInfo.create(name: "fullscreen")
        mediaContext.enterState(MediaPlaybackState.Play)
        _ = mediaContext.startState(stateInfo)
        _ = mediaContext.endState(stateInfo)
        _ = mediaContext.startState(stateInfo)
        var params = MediaCollectionHelper.extractMediaParams(mediaContext: mediaContext)
        params[MediaConstants.MediaCollection.Media.DOWNLOADED] = true
        params[MediaConstants.MediaCollection.Media.RESUME] = true
        let metadata = MediaCollectionHelper.extractMediaMetadata(mediaContext: mediaContext)
        let config = [MediaConstants.Configuration.DOWNLOADED_CONTENT: true]
        self.hitGenerator = MediaCollectionHitGenerator.init(context: mediaContext, hitProcessor: hitProcessor, config: config, timestamp: expectedTimestamp)
        // test
        hitGenerator.processSessionRestart()
        // verify number hits
        XCTAssertEqual(3, hitProcessor.getHitCountFromActiveSession())
        // verify media start hit
        let expectedMediaStartHit = MediaHit.init(eventType: "sessionStart", params: params, metadata: metadata, QOEData: emptyQOEData, playhead: expectedPlayhead, ts: expectedTimestamp)
        let mediaStartHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedMediaStartHit, mediaStartHit)
        // verify state start hit
        let startParams = ["state.name": "fullscreen"]
        let expectedStateStartHit = MediaHit.init(eventType: "stateStart", params: startParams, metadata: emptyMetadata, QOEData: emptyQOEData, playhead: expectedPlayhead, ts: expectedTimestamp)
        let stateStartHit = hitProcessor.getHitFromActiveSession(index: 1)
        XCTAssertEqual(expectedStateStartHit, stateStartHit)
        // verify play
        let expectedPlayHit = MediaHit.init(eventType: "play", params: emptyParams, metadata: emptyMetadata, QOEData: emptyQOEData, playhead: expectedPlayhead, ts: expectedTimestamp)
        let playHit = hitProcessor.getHitFromActiveSession(index: 2)
        XCTAssertEqual(expectedPlayHit, playHit)
    }
    
    func testProcessPlaybackStateDifferentStates() {
        // setup
        var params = MediaCollectionHelper.extractMediaParams(mediaContext: mediaContext)
        params[MediaConstants.MediaCollection.Media.DOWNLOADED] = true
        params[MediaConstants.MediaCollection.Media.RESUME] = true
        let config = [MediaConstants.Configuration.DOWNLOADED_CONTENT: true]
        self.hitGenerator = MediaCollectionHitGenerator.init(context: mediaContext, hitProcessor: hitProcessor, config: config, timestamp: expectedTimestamp)
        // test
        hitGenerator.processPlayback(doFlush: false)
        XCTAssertEqual(0, hitProcessor.getHitCount(sessionID: self.expectedSessionId))
        // play hit
        mediaContext.enterState(MediaPlaybackState.Play)
        hitGenerator.processPlayback(doFlush: false)
        XCTAssertEqual(1, hitProcessor.getHitCountFromActiveSession())
        let expectedPlayHit = MediaHit.init(eventType: "play", params: emptyParams, metadata: emptyMetadata, QOEData: emptyQOEData, playhead: expectedPlayhead, ts: expectedTimestamp)
        let playHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedPlayHit, playHit)
        hitProcessor.clearHitsFromActiveSession()
        // buffer start hit
        mediaContext.enterState(MediaPlaybackState.Buffer)
        hitGenerator.setMediaContext(mediaContext)
        hitGenerator.processPlayback(doFlush: false)
        XCTAssertEqual(1, hitProcessor.getHitCountFromActiveSession())
        let expectedBufferStartHit = MediaHit.init(eventType: "bufferStart", params: emptyParams, metadata: emptyMetadata, QOEData: emptyQOEData, playhead: expectedPlayhead, ts: expectedTimestamp)
        let bufferStartHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedBufferStartHit, bufferStartHit)
        hitProcessor.clearHitsFromActiveSession()
        // buffer end hit (will be play)
        mediaContext.exitState(MediaPlaybackState.Buffer)
        hitGenerator.setMediaContext(mediaContext)
        hitGenerator.processPlayback(doFlush: false)
        XCTAssertEqual(1, hitProcessor.getHitCountFromActiveSession())
        let expectedBufferEndHit = MediaHit.init(eventType: "play", params: emptyParams, metadata: emptyMetadata, QOEData: emptyQOEData, playhead: expectedPlayhead, ts: expectedTimestamp)
        let bufferEndHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedBufferEndHit, bufferEndHit)
        hitProcessor.clearHitsFromActiveSession()
        // start seek hit
        mediaContext.enterState(MediaPlaybackState.Seek)
        hitGenerator.setMediaContext(mediaContext)
        hitGenerator.processPlayback(doFlush: false)
        XCTAssertEqual(1, hitProcessor.getHitCountFromActiveSession())
        let expectedSeekStartHit = MediaHit.init(eventType: "pauseStart", params: emptyParams, metadata: emptyMetadata, QOEData: emptyQOEData, playhead: expectedPlayhead, ts: expectedTimestamp)
        let seekStartHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedSeekStartHit, seekStartHit)
        hitProcessor.clearHitsFromActiveSession()
        // exit seek hit
        mediaContext.exitState(MediaPlaybackState.Seek)
        hitGenerator.setMediaContext(mediaContext)
        hitGenerator.processPlayback(doFlush: false)
        XCTAssertEqual(1, hitProcessor.getHitCountFromActiveSession())
        let expectedSeekExitHit = MediaHit.init(eventType: "play", params: emptyParams, metadata: emptyMetadata, QOEData: emptyQOEData, playhead: expectedPlayhead, ts: expectedTimestamp)
        let seekExitHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedSeekExitHit, seekExitHit)
        hitProcessor.clearHitsFromActiveSession()
        // pause hit
        mediaContext.enterState(MediaPlaybackState.Pause)
        hitGenerator.setMediaContext(mediaContext)
        hitGenerator.processPlayback(doFlush: false)
        XCTAssertEqual(1, hitProcessor.getHitCountFromActiveSession())
        let expectedPauseHit = MediaHit.init(eventType: "pauseStart", params: emptyParams, metadata: emptyMetadata, QOEData: emptyQOEData, playhead: expectedPlayhead, ts: expectedTimestamp)
        let pauseHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedPauseHit, pauseHit)
        hitProcessor.clearHitsFromActiveSession()
    }
    
    func testProcessStateStartFullscreen() {
        // setup
        let stateInfo = StateInfo()
        stateInfo.create(name: "fullscreen")
        // test
        hitGenerator.processStateStart(stateInfo: stateInfo)
        // verify state start hit
        XCTAssertEqual(1, hitProcessor.getHitCount(sessionID: self.expectedSessionId))
        let startParams = ["state.name": "fullscreen"]
        let expectedStateStartHit = MediaHit.init(eventType: "stateStart", params: startParams, metadata: emptyMetadata, QOEData: emptyQOEData, playhead: expectedPlayhead, ts: expectedTimestamp)
        let stateStartHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedStateStartHit, stateStartHit)
    }
    
    func testProcessStateEndFullscreen() {
        // setup
        let stateInfo = StateInfo()
        stateInfo.create(name: "fullscreen")
        // test
        hitGenerator.processStateEnd(stateInfo: stateInfo)
        // verify state start hit
        XCTAssertEqual(1, hitProcessor.getHitCount(sessionID: self.expectedSessionId))
        let startParams = ["state.name": "fullscreen"]
        let expectedStateEndHit = MediaHit.init(eventType: "stateEnd", params: startParams, metadata: emptyMetadata, QOEData: emptyQOEData, playhead: expectedPlayhead, ts: expectedTimestamp)
        let stateEndHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedStateEndHit, stateEndHit)
    }
    
    func testProcessPlaybackStateSameStateOnline() {
        // setup
        mediaContext.enterState(MediaPlaybackState.Play)
        let config = [MediaConstants.Configuration.DOWNLOADED_CONTENT: false]
        self.hitGenerator = MediaCollectionHitGenerator.init(context: mediaContext, hitProcessor: hitProcessor, config: config, timestamp: expectedTimestamp)
        var params = MediaCollectionHelper.extractMediaParams(mediaContext: mediaContext)
        params[MediaConstants.MediaCollection.Media.DOWNLOADED] = false
        // verify play hit
        hitGenerator.processPlayback(doFlush: false)
        XCTAssertEqual(1, hitProcessor.getHitCountFromActiveSession())
        let expectedPlayHit = MediaHit.init(eventType: "play", params: emptyParams, metadata: emptyMetadata, QOEData: emptyQOEData, playhead: expectedPlayhead, ts: expectedTimestamp)
        let playHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedPlayHit, playHit)
        hitProcessor.clearHitsFromActiveSession()
        // second play hit should not be sent
        hitGenerator.processPlayback(doFlush: false)
        XCTAssertEqual(0, hitProcessor.getHitCount(sessionID: self.expectedSessionId))
        // set timestamp greater than session interval to allow a new play hit to be sent
        hitGenerator.setRefTS(ts: 100)
        hitGenerator.processPlayback(doFlush: false)
        XCTAssertEqual(1, hitProcessor.getHitCountFromActiveSession())
    }
    
    func testProcessPlaybackSameStateInit() {
        // no hit due to the current state == previous state and offline ping interval not elapsed
        hitGenerator.processPlayback(doFlush: false)
        XCTAssertEqual(0, hitProcessor.getHitCountFromActiveSession())
        // no hit due to timestamp being lower than default offline ping interval
        hitGenerator.setRefTS(ts: 10)
        hitGenerator.processPlayback(doFlush: false)
        XCTAssertEqual(0, hitProcessor.getHitCountFromActiveSession())
        // expect 1 hit due to timestamp >= the default offline ping interval
        hitGenerator.setRefTS(ts: 50)
        hitGenerator.processPlayback(doFlush: false)
        XCTAssertEqual(1, hitProcessor.getHitCountFromActiveSession())
        let expectedPingHit = MediaHit.init(eventType: "ping", params: emptyParams, metadata: emptyMetadata, QOEData: emptyQOEData, playhead: expectedPlayhead, ts: 50)
        let pingHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedPingHit, pingHit)
    }
    
    func testProcessPlaybackSameStateInitOnline() {
        // setup
        let config = [MediaConstants.Configuration.DOWNLOADED_CONTENT: false]
        self.hitGenerator = MediaCollectionHitGenerator.init(context: mediaContext, hitProcessor: hitProcessor, config: config, timestamp: expectedTimestamp)
        // no hit due to the current state == previous state and online ping interval not elapsed
        hitGenerator.processPlayback(doFlush: false)
        XCTAssertEqual(0, hitProcessor.getHitCountFromActiveSession())
        // expect 1 hit due to timestamp >= default online ping interval
        hitGenerator.setRefTS(ts: 10)
        hitGenerator.processPlayback(doFlush: false)
        XCTAssertEqual(1, hitProcessor.getHitCountFromActiveSession())
        var expectedPingHit = MediaHit.init(eventType: "ping", params: emptyParams, metadata: emptyMetadata, QOEData: emptyQOEData, playhead: expectedPlayhead, ts: 10)
        var pingHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedPingHit, pingHit)
        // expect another hit due to timestamp >= the default online ping interval
        hitGenerator.setRefTS(ts: 50)
        hitGenerator.processPlayback(doFlush: false)
        XCTAssertEqual(2, hitProcessor.getHitCountFromActiveSession())
        expectedPingHit = MediaHit.init(eventType: "ping", params: emptyParams, metadata: emptyMetadata, QOEData: emptyQOEData, playhead: expectedPlayhead, ts: 50)
        pingHit = hitProcessor.getHitFromActiveSession(index: 1)
        XCTAssertEqual(expectedPingHit, pingHit)
    }
    
    func testprocessPlaybackSameStateTimeout() {
        // trigger play hit
        mediaContext.enterState(MediaPlaybackState.Play)
        hitGenerator.processPlayback(doFlush: false)
        XCTAssertEqual(1, hitProcessor.getHitCountFromActiveSession())
        let expectedPlayHit = MediaHit.init(eventType: "play", params: emptyParams, metadata: emptyMetadata, QOEData: emptyQOEData, playhead: expectedPlayhead, ts: 0)
        let playHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedPlayHit, playHit)
        hitProcessor.clearHitsFromActiveSession()
        // expect ping hit due to timestamp >= default online ping interval but current state == previous state
        hitGenerator.setRefTS(ts: 51)
        hitGenerator.processPlayback(doFlush: false)
        XCTAssertEqual(1, hitProcessor.getHitCountFromActiveSession())
        let expectedPingHit = MediaHit.init(eventType: "ping", params: emptyParams, metadata: emptyMetadata, QOEData: emptyQOEData, playhead: expectedPlayhead, ts: 51)
        let pingHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedPingHit, pingHit)
    }
    
    func testprocessPlaybackFlush() {
        // trigger play hit
        mediaContext.enterState(MediaPlaybackState.Play)
        hitGenerator.processPlayback(doFlush: false)
        XCTAssertEqual(1, hitProcessor.getHitCountFromActiveSession())
        let expectedPlayHit = MediaHit.init(eventType: "play", params: emptyParams, metadata: emptyMetadata, QOEData: emptyQOEData, playhead: expectedPlayhead, ts: 0)
        let playHit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedPlayHit, playHit)
        hitProcessor.clearHitsFromActiveSession()
        // expect play hit due to flush
        hitGenerator.setRefTS(ts: 10)
        hitGenerator.processPlayback(doFlush: true)
        XCTAssertEqual(1, hitProcessor.getHitCountFromActiveSession())
        let expectedPlayHit2 = MediaHit.init(eventType: "play", params: emptyParams, metadata: emptyMetadata, QOEData: emptyQOEData, playhead: expectedPlayhead, ts: 10)
        let playHit2 = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedPlayHit2, playHit2)
    }
    
    func testprocessBitrateChange() {
        // trigger bitrate change hit
        hitGenerator.processBitrateChange()
        // verify
        XCTAssertEqual(1, hitProcessor.getHitCountFromActiveSession())
        let expectedHit = MediaHit.init(eventType: "bitrateChange", params: emptyParams, metadata: emptyMetadata, QOEData: emptyQOEData, playhead: expectedPlayhead, ts: 0)
        let hit = hitProcessor.getHitFromActiveSession(index: 0)
        XCTAssertEqual(expectedHit, hit)
    }
    
    func testGenerateHitAfterMediaSession() {
        // test
        hitGenerator.endMediaSession()
        hitGenerator.processPlayback(doFlush: false)
        // verify no hit because tracking is stopped
        XCTAssertEqual(0, hitProcessor.getHitCountFromActiveSession())
    }
    
    func testGenerateHitAfterMediaSession2() {
        // test
        hitGenerator.endMediaSession()
        hitGenerator.generateHit(eventType: MediaConstants.EventName.PLAY, params: emptyParams, metadata: emptyMetadata, QOEData: emptyQOEData)
        // verify no hit because tracking is stopped
        XCTAssertEqual(0, hitProcessor.getHitCountFromActiveSession())
    }
    
    func testGetPlaybackStateMediaContextState() {
        let states = [MediaPlaybackState.Init, MediaPlaybackState.Play, MediaPlaybackState.Pause, MediaPlaybackState.Seek, MediaPlaybackState.Buffer, MediaPlaybackState.Stall]
        
        for state in states {
            mediaContext.enterState(state)
            hitGenerator.setMediaContext(mediaContext)
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
