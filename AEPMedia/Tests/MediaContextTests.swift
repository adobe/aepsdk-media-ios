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
@testable import AEPCore
@testable import AEPMedia

class MediaContextTests: XCTestCase {
    static let emptyMetadata: [String:String] = [:]
    static let metadata:[String:String] = [
        "k1":"v1"
    ]
    var mediaContext:MediaContext?
 
    override func setUp() {
        let mediaInfo = MediaInfo(id: "id", name: "name", streamType: "vod", mediaType: MediaType.Video, length: 30.0)
        mediaContext = MediaContext(mediaInfo: mediaInfo!, metadata: Self.metadata)
    }
    
    // MARK: MediaContext unit tests
    
    func testMedia() {
        let mediaInfo = MediaInfo(id: "id", name: "name", streamType: "vod", mediaType: MediaType.Video, length: 30.0)!
        let mediaContext = MediaContext(mediaInfo: mediaInfo, metadata: Self.metadata)
        XCTAssertNotNil(mediaContext.getMediaInfo())
        XCTAssertEqual(mediaInfo, mediaContext.getMediaInfo())
        XCTAssertEqual(Self.metadata, mediaContext.getMetadata())
    }
    
    func testAdBreak() {
        XCTAssertFalse(mediaContext!.isInAdBreak())
        
        mediaContext?.setAdBreak(info:nil)
        XCTAssertFalse(mediaContext!.isInAdBreak())
        
        let adBreakInfo = AdBreakInfo(name: "name", position: 1, startTime: 1.1)!
        mediaContext?.setAdBreak(info:adBreakInfo)
        
        XCTAssertTrue(mediaContext!.isInAdBreak())
        XCTAssertNotNil(mediaContext?.getAdBreakInfo())
        XCTAssertEqual(adBreakInfo, mediaContext?.getAdBreakInfo())
        
        mediaContext?.clearAdBreakInfo()
        XCTAssertFalse(mediaContext!.isInAdBreak())
        XCTAssertNil(mediaContext?.getAdBreakInfo())
    }
    
    func testAd() {
        XCTAssertFalse(mediaContext!.isInAd())
        
        mediaContext?.setAd(info:nil, metadata: Self.metadata)
        XCTAssertFalse(mediaContext!.isInAd())
        
        let adInfo = AdInfo(id: "id", name: "name", position: 2, length: 30.0)!
        mediaContext?.setAd(info:adInfo, metadata: Self.metadata)
        
        XCTAssertTrue(mediaContext!.isInAd())
        XCTAssertNotNil(mediaContext?.getAdInfo())
        XCTAssertEqual(adInfo, mediaContext?.getAdInfo())
        XCTAssertEqual(Self.metadata, mediaContext?.getAdMetadata())
        
        mediaContext?.clearAdInfo()
        XCTAssertFalse(mediaContext!.isInAd())
        XCTAssertNil(mediaContext?.getAdInfo())
    }
    
    func testChapter() {
        XCTAssertFalse(mediaContext!.isInChapter())
        
        mediaContext?.setChapter(info:nil, metadata: Self.metadata)
        XCTAssertFalse(mediaContext!.isInChapter())
        
        let chapterInfo = ChapterInfo(name: "name", position: 1, startTime: 1.2, length: 30.0)!
        mediaContext?.setChapter(info:chapterInfo, metadata: Self.metadata)
        XCTAssertEqual(Self.metadata, mediaContext?.getChapterMetadata())
        
        XCTAssertTrue(mediaContext!.isInChapter())
        XCTAssertNotNil(mediaContext?.getChapterInfo())
        XCTAssertEqual(chapterInfo, mediaContext?.getChapterInfo())
        
        mediaContext?.clearChapterInfo()
        XCTAssertFalse(mediaContext!.isInChapter())
        XCTAssertNil(mediaContext?.getChapterInfo())
    }
    
    func testQoE() {
        XCTAssertNil(mediaContext?.getQoEInfo())
        
        mediaContext?.setQoE(info:nil)
        XCTAssertNil(mediaContext?.getQoEInfo())
        
        let qoeInfo = QoEInfo(bitrate: 1.1, droppedFrames: 2.2, fps: 3.3, startupTime: 4.4)
        mediaContext?.setQoE(info:qoeInfo)
        
        XCTAssertNotNil(mediaContext?.getQoEInfo())
        XCTAssertEqual(qoeInfo, mediaContext?.getQoEInfo())
    }
    
    func testPlayhead() {
        XCTAssertEqual(0, mediaContext?.getPlayhead())
        
        mediaContext?.setPlayhead(value: 1.12)
        
        XCTAssertEqual(1.12, mediaContext?.getPlayhead())
    }
    
    func testBufferState() {
        let state = MediaContext.MediaPlaybackState.Buffer
        
        XCTAssertFalse(mediaContext!.isInMediaPlaybackState(state: state))
        
        mediaContext?.enter(state: state)
        
        XCTAssertTrue(mediaContext!.isInMediaPlaybackState(state: state))
        
        mediaContext?.exit(state: state)
        
        XCTAssertFalse(mediaContext!.isInMediaPlaybackState(state: state))
    }
    
    func testSeekState() {
        let state = MediaContext.MediaPlaybackState.Seek
        
        XCTAssertFalse(mediaContext!.isInMediaPlaybackState(state: state))
        
        mediaContext?.enter(state: state)
        
        XCTAssertTrue(mediaContext!.isInMediaPlaybackState(state: state))
        
        mediaContext?.exit(state: state)
        
        XCTAssertFalse(mediaContext!.isInMediaPlaybackState(state: state))
    }
    
    func testPlaybackStates() {
        XCTAssertTrue(mediaContext!.isInMediaPlaybackState(state: MediaContext.MediaPlaybackState.Init))

        mediaContext?.exit(state: MediaContext.MediaPlaybackState.Init) //Should not exit Init
        
        XCTAssertTrue(mediaContext!.isInMediaPlaybackState(state: MediaContext.MediaPlaybackState.Init))
        
        var state = MediaContext.MediaPlaybackState.Pause
        mediaContext?.enter(state: state)
        XCTAssertTrue(mediaContext!.isInMediaPlaybackState(state: state))
        mediaContext?.exit(state: state) //Should not exit Pause
        XCTAssertTrue(mediaContext!.isInMediaPlaybackState(state: state))
        
        state = MediaContext.MediaPlaybackState.Play
        mediaContext?.enter(state: state)
        XCTAssertTrue(mediaContext!.isInMediaPlaybackState(state: state))
        mediaContext?.exit(state: state) //Should not exit Play
        XCTAssertTrue(mediaContext!.isInMediaPlaybackState(state: state))
        
        state = MediaContext.MediaPlaybackState.Stall
        mediaContext?.enter(state: state)
        XCTAssertTrue(mediaContext!.isInMediaPlaybackState(state: state))
        mediaContext?.exit(state: state) //Should not exit Stall
        XCTAssertTrue(mediaContext!.isInMediaPlaybackState(state: state))
        
        // Should not enter Init state again
        mediaContext?.enter(state: MediaContext.MediaPlaybackState.Init)
        XCTAssertTrue(mediaContext!.isInMediaPlaybackState(state: MediaContext.MediaPlaybackState.Stall))
    }
    
    func testIdleState() {
        XCTAssertTrue(mediaContext!.isIdle())
        
        mediaContext?.enter(state: MediaContext.MediaPlaybackState.Buffer)
        XCTAssertTrue(mediaContext!.isIdle())
        
        mediaContext?.enter(state: MediaContext.MediaPlaybackState.Seek)
        XCTAssertTrue(mediaContext!.isIdle())
        
        mediaContext?.enter(state: MediaContext.MediaPlaybackState.Pause)
        XCTAssertTrue(mediaContext!.isIdle())
        
        mediaContext?.enter(state: MediaContext.MediaPlaybackState.Stall)
        XCTAssertTrue(mediaContext!.isIdle())
        
        mediaContext?.enter(state: MediaContext.MediaPlaybackState.Play)
        mediaContext?.exit(state: MediaContext.MediaPlaybackState.Seek)
        mediaContext?.exit(state: MediaContext.MediaPlaybackState.Buffer)
        XCTAssertFalse(mediaContext!.isIdle())
    }
    
    func testSimpleStateTracking1() {
        let customState = StateInfo(stateName: "testCustomState")
        
        XCTAssertFalse(mediaContext!.isInState(info: customState!))
        XCTAssertFalse(mediaContext!.hasTrackedState(info: customState!))
        
        XCTAssertTrue(mediaContext!.startState(info: customState!))
        XCTAssertTrue(mediaContext!.isInState(info: customState!))
        
        XCTAssertFalse(mediaContext!.startState(info: customState!))
        XCTAssertTrue(mediaContext!.endState(info: customState!))
        
        XCTAssertFalse(mediaContext!.isInState(info: customState!))
        XCTAssertTrue(mediaContext!.hasTrackedState(info: customState!))
        XCTAssertFalse(mediaContext!.endState(info: customState!))
    }
    
    func testSimpleStateTracking2() {
        let customState = StateInfo(stateName: "testCustomState")
        
        XCTAssertFalse(mediaContext!.endState(info: customState!))
        XCTAssertFalse(mediaContext!.isInState(info: customState!))
        XCTAssertFalse(mediaContext!.hasTrackedState(info: customState!))
        
        XCTAssertTrue(mediaContext!.startState(info: customState!))
        XCTAssertTrue(mediaContext!.isInState(info: customState!))
        
        XCTAssertTrue(mediaContext!.endState(info: customState!))
        XCTAssertFalse(mediaContext!.isInState(info: customState!))
        XCTAssertTrue(mediaContext!.hasTrackedState(info: customState!))
    }
    
    func testStateTrackingLimit1() {
        for i in 1...MediaConstants.StateInfo.STATE_LIMIT {
            let customState = StateInfo(stateName: "testCustomState\(i)")
            XCTAssertTrue(mediaContext!.startState(info: customState!))
            XCTAssertTrue(mediaContext!.isInState(info: customState!))
        }
        
        let customState = StateInfo(stateName: "testCustomState")
        XCTAssertFalse(mediaContext!.startState(info: customState!))
        XCTAssertFalse(mediaContext!.isInState(info: customState!))
    }
    
    func testStateTrackingLimit2() {
        for i in 1...MediaConstants.StateInfo.STATE_LIMIT {
            let customState = StateInfo(stateName: "testCustomState\(i)")
            XCTAssertTrue(mediaContext!.startState(info: customState!))
            XCTAssertTrue(mediaContext!.isInState(info: customState!))
        }
        XCTAssertTrue(mediaContext!.didReachMaxStateLimit())
        
        let customState = StateInfo(stateName: "testCustomState")
        XCTAssertFalse(mediaContext!.startState(info: customState!))
        XCTAssertFalse(mediaContext!.isInState(info: customState!))
        
        let customState1 = StateInfo(stateName: "testCustomState1") // First State created in the for loop above
        
        XCTAssertTrue(mediaContext!.isInState(info: customState1!))
        XCTAssertTrue(mediaContext!.endState(info: customState1!))
        XCTAssertFalse(mediaContext!.isInState(info: customState1!))
        XCTAssertTrue(mediaContext!.startState(info: customState1!))
        XCTAssertTrue(mediaContext!.isInState(info: customState1!))
        XCTAssertTrue(mediaContext!.hasTrackedState(info: customState1!))
        
    }
    
    func testStateTrackingLimitWithClear() {
        for i in 1...MediaConstants.StateInfo.STATE_LIMIT {
            let customState = StateInfo(stateName: "testCustomState\(i)")
            XCTAssertTrue(mediaContext!.startState(info: customState!))
            XCTAssertTrue(mediaContext!.isInState(info: customState!))
        }
        
        XCTAssertTrue(mediaContext!.didReachMaxStateLimit())
        mediaContext?.clearStates()
        XCTAssertFalse(mediaContext!.didReachMaxStateLimit())
        
        let customState = StateInfo(stateName: "testCustomState")
        XCTAssertTrue(mediaContext!.startState(info: customState!))
        XCTAssertTrue(mediaContext!.isInState(info: customState!))
    }
    
    func testGetActiveStates() {
        let state1 = StateInfo(stateName: "customState1")
        let state2 = StateInfo(stateName: "customState2")
        let state3 = StateInfo(stateName: "customState3")
        
        XCTAssertTrue(mediaContext!.startState(info: state1!))
        XCTAssertTrue(mediaContext!.startState(info: state2!))
        XCTAssertTrue(mediaContext!.startState(info: state3!))
        
        XCTAssertTrue(mediaContext!.endState(info: state1!))
        
        let activeStates = mediaContext?.getActiveTrackeStates()
        XCTAssertEqual(2, activeStates?.count)
    }
}
