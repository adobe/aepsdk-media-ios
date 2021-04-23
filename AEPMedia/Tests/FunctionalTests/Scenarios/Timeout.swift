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

class Timeout: XCTestCase {
    private typealias EventType = MediaConstants.MediaCollection.EventType
    private typealias Media = MediaConstants.MediaCollection.Media

    var fakeMediaService: FakeMediaHitProcessor!
    var mediaEventTracker: MediaEventTracking!
    var mediaTracker: MediaEventGenerator!
    private typealias State = MediaConstants.MediaCollection.State

    let standardStateCC = StateInfo(stateName: MediaConstants.PlayerState.CLOSED_CAPTION)!
    let expectedCloseCaptionParam: [String: Any] = [
        State.NAME: "closedCaptioning"
    ]
    
    let mediaInfoWithDefaultPreroll = MediaInfo(id: "mediaID", name: "mediaName", streamType: "vod", mediaType: MediaType.Video, length: 30.0)!
    let mediaMetadata = ["media.show": "sampleshow", "key1": "value1", "key2": "мểŧẳđαţả"]
    
    let expectedSessionStartParams: [String: Any]  = [
        Media.ID: "mediaID",
        Media.NAME: "mediaName",
        Media.LENGTH: 30.0,
        Media.CONTENT_TYPE: "vod",
        Media.STREAM_TYPE: "video",
        Media.RESUME: false,
        Media.DOWNLOADED: false,
    ]
    
    let expectedSessionStartParams2: [String: Any]  = [
        Media.ID: "mediaID",
        Media.NAME: "mediaName",
        Media.LENGTH: 30.0,
        Media.CONTENT_TYPE: "vod",
        Media.STREAM_TYPE: "video",
        Media.RESUME: true,
        Media.DOWNLOADED: false,
    ]
    
    let expectedDownloadSessionStartParams: [String: Any]  = [
        Media.ID: "mediaID",
        Media.NAME: "mediaName",
        Media.LENGTH: 30.0,
        Media.CONTENT_TYPE: "vod",
        Media.STREAM_TYPE: "video",
        Media.RESUME: false,
        Media.DOWNLOADED: true,
    ]
    
    let expectedDownloadSessionStartParams2: [String: Any]  = [
        Media.ID: "mediaID",
        Media.NAME: "mediaName",
        Media.LENGTH: 30.0,
        Media.CONTENT_TYPE: "vod",
        Media.STREAM_TYPE: "video",
        Media.RESUME: true,
        Media.DOWNLOADED: true,
    ]

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
    
    func checkHit(expectedHits: [MediaHit], actualHits: [MediaHit]) {
        let actualHitsCount = actualHits.count
        XCTAssertEqual(expectedHits.count, actualHitsCount, "No of expected hits (\(expectedHits.count)) not equal to actual hits (\(actualHitsCount))")

        for i in 0...expectedHits.count-1 {
            XCTAssertEqual(expectedHits[i], actualHits[i])
        }
    }
    
    func testSessionIdle_RealTimeTracker() {
        // test
        mediaTracker.trackSessionStart(info: mediaInfoWithDefaultPreroll.toMap(), metadata: mediaMetadata)
        mediaTracker.trackPlay()
        //wait for 24 hours
        waitFor(time: 86400000, updatePlayhead: true)
        //wait for 20 seconds
        waitFor(time: 20000, updatePlayhead: true)
        mediaTracker.trackComplete()
        
        //Hits to verify
        let expectedHitsEvent: [MediaHit] = [
            //session 0
            MediaHit(eventType: EventType.SESSION_START, playhead: 0, ts: 0, params: expectedSessionStartParams, customMetadata: mediaMetadata),
            MediaHit(eventType: EventType.PLAY, playhead: 0, ts: 0),
            MediaHit(eventType: EventType.PLAY, playhead: 1, ts: 1000),
            MediaHit(eventType: EventType.PING, playhead: 11, ts: 11000),
            MediaHit(eventType: EventType.PING, playhead: 86381, ts: 86381000),
            MediaHit(eventType: EventType.PING, playhead: 86391, ts: 86391000),
            MediaHit(eventType: EventType.SESSION_END, playhead: 86400, ts: 86400000),
            
            //session 1
            MediaHit(eventType: EventType.SESSION_START, playhead: 86400, ts: 86400000, params: expectedSessionStartParams2, customMetadata: mediaMetadata),
            MediaHit(eventType: EventType.PLAY, playhead: 86400, ts: 86400000),
            MediaHit(eventType: EventType.PLAY, playhead: 86401, ts: 86401000),
            MediaHit(eventType: EventType.PING, playhead: 86411, ts: 86411000),
            MediaHit(eventType: EventType.SESSION_COMPLETE, playhead: 86420, ts: 86420000)
        ]
        
        let actualHitList: [MediaHit] = [
            fakeMediaService.getHit(sessionId: "0", index: 0)!,
            fakeMediaService.getHit(sessionId: "0", index: 1)!,
            fakeMediaService.getHit(sessionId: "0", index: 2)!,
            fakeMediaService.getHit(sessionId: "0", index: 3)!,
            fakeMediaService.getHit(sessionId: "0", index: 8640)!,
            fakeMediaService.getHit(sessionId: "0", index: 8641)!,
            fakeMediaService.getHit(sessionId: "0", index: 8642)!,
            fakeMediaService.getHit(sessionId: "1", index: 0)!,
            fakeMediaService.getHit(sessionId: "1", index: 1)!,
            fakeMediaService.getHit(sessionId: "1", index: 2)!,
            fakeMediaService.getHit(sessionId: "1", index: 3)!,
            fakeMediaService.getHit(sessionId: "1", index: 4)!
        ]

        //verify
        checkHit(expectedHits: expectedHitsEvent, actualHits: actualHitList)
    }
        
    func testSessionIdle_DownloadTracker() {
        // setup
        createTracker(downloaded: true)

        // test
        mediaTracker.trackSessionStart(info: mediaInfoWithDefaultPreroll.toMap(), metadata: mediaMetadata)
        mediaTracker.trackPlay()
        //wait for 24 hours
        waitFor(time: 86400000, updatePlayhead: true)
        //wait for 60 seconds
        waitFor(time: 60000, updatePlayhead: true)
        mediaTracker.trackComplete()
        
        //Hits to verify
        let expectedHitsEvent: [MediaHit] = [
            //session 0
            MediaHit(eventType: EventType.SESSION_START, playhead: 0, ts: 0, params: expectedDownloadSessionStartParams, customMetadata: mediaMetadata),
            MediaHit(eventType: EventType.PLAY, playhead: 0, ts: 0),
            MediaHit(eventType: EventType.PLAY, playhead: 1, ts: 1000),
            MediaHit(eventType: EventType.PING, playhead: 51, ts: 51000),
            MediaHit(eventType: EventType.PING, playhead: 86351, ts: 86351000),
            MediaHit(eventType: EventType.SESSION_END, playhead: 86400, ts: 86400000),
            
            //session 1
            MediaHit(eventType: EventType.SESSION_START, playhead: 86400, ts: 86400000, params: expectedDownloadSessionStartParams2, customMetadata: mediaMetadata),
            MediaHit(eventType: EventType.PLAY, playhead: 86400, ts: 86400000),
            MediaHit(eventType: EventType.PLAY, playhead: 86401, ts: 86401000),
            MediaHit(eventType: EventType.PING, playhead: 86451, ts: 86451000),
            MediaHit(eventType: EventType.SESSION_COMPLETE, playhead: 86460, ts: 86460000)
        ]
        
        let actualHitList: [MediaHit] = [
            fakeMediaService.getHit(sessionId: "0", index: 0)!,
            fakeMediaService.getHit(sessionId: "0", index: 1)!,
            fakeMediaService.getHit(sessionId: "0", index: 2)!,
            fakeMediaService.getHit(sessionId: "0", index: 3)!,
            fakeMediaService.getHit(sessionId: "0", index: 1729)!,
            fakeMediaService.getHit(sessionId: "0", index: 1730)!,
            fakeMediaService.getHit(sessionId: "1", index: 0)!,
            fakeMediaService.getHit(sessionId: "1", index: 1)!,
            fakeMediaService.getHit(sessionId: "1", index: 2)!,
            fakeMediaService.getHit(sessionId: "1", index: 3)!,
            fakeMediaService.getHit(sessionId: "1", index: 4)!
        ]
        
        //verify
        checkHit(expectedHits: expectedHitsEvent, actualHits: actualHitList)
    }
    
    func testIdleTimeOut_RealTimeTracker() {
        // test idel timeout after 30 mins
        mediaTracker.trackSessionStart(info: mediaInfoWithDefaultPreroll.toMap(), metadata: mediaMetadata)
        mediaTracker.trackPlay()
        waitFor(time: 3000, updatePlayhead: true)
        mediaTracker.trackPause()
        //wait for 30 mins
        waitFor(time: 1800000, updatePlayhead: false)
        
        
        //Hits to verify
        let expectedHitsEvent: [MediaHit] = [
            MediaHit(eventType: EventType.SESSION_START, playhead: 0, ts: 0, params: expectedSessionStartParams, customMetadata: mediaMetadata),
            MediaHit(eventType: EventType.PLAY, playhead: 0, ts: 0),
            MediaHit(eventType: EventType.PLAY, playhead: 1, ts: 1000),
            MediaHit(eventType: EventType.PAUSE_START, playhead: 3, ts: 3000),
            MediaHit(eventType: EventType.PING, playhead: 3, ts: 1793000),
            MediaHit(eventType: EventType.SESSION_END, playhead: 3, ts: 1803000),
        ]
        
        let actualHitList: [MediaHit] = [
            fakeMediaService.getHit(sessionId: "0", index: 0)!,
            fakeMediaService.getHit(sessionId: "0", index: 1)!,
            fakeMediaService.getHit(sessionId: "0", index: 2)!,
            fakeMediaService.getHit(sessionId: "0", index: 3)!,
            fakeMediaService.getHit(sessionId: "0", index: 182)!,
            fakeMediaService.getHit(sessionId: "0", index: 183)!,
        ]
        
        //verify
        checkHit(expectedHits: expectedHitsEvent, actualHits: actualHitList)
    }
    
    func testIdleTimeOut_DownloadTracker() {
        // setup
        createTracker(downloaded: true)
        
        // test
        mediaTracker.trackSessionStart(info: mediaInfoWithDefaultPreroll.toMap(), metadata: mediaMetadata)
        mediaTracker.trackPlay()
        waitFor(time: 3000, updatePlayhead: true)
        mediaTracker.trackPause()
        //wait for 30 mins
        waitFor(time: 1800000, updatePlayhead: false)
        
        
        //Hits to verify
        let expectedHitsEvent: [MediaHit] = [
            MediaHit(eventType: EventType.SESSION_START, playhead: 0, ts: 0, params: expectedDownloadSessionStartParams, customMetadata: mediaMetadata),
            MediaHit(eventType: EventType.PLAY, playhead: 0, ts: 0),
            MediaHit(eventType: EventType.PLAY, playhead: 1, ts: 1000),
            MediaHit(eventType: EventType.PAUSE_START, playhead: 3, ts: 3000),
            MediaHit(eventType: EventType.PING, playhead: 3, ts: 1753000),
            MediaHit(eventType: EventType.SESSION_END, playhead: 3, ts: 1803000),
        ]
        
        let actualHitList: [MediaHit] = [
            fakeMediaService.getHit(sessionId: "0", index: 0)!,
            fakeMediaService.getHit(sessionId: "0", index: 1)!,
            fakeMediaService.getHit(sessionId: "0", index: 2)!,
            fakeMediaService.getHit(sessionId: "0", index: 3)!,
            fakeMediaService.getHit(sessionId: "0", index: 38)!,
            fakeMediaService.getHit(sessionId: "0", index: 39)!,
        ]
        
        //verify
        checkHit(expectedHits: expectedHitsEvent, actualHits: actualHitList)
    }
    
    func testIdleTimeOut_SessionEndAndPlay_RealTimeTracker() {
        // test idel timeout after 30 mins and issue a play event, new session start
        mediaTracker.trackSessionStart(info: mediaInfoWithDefaultPreroll.toMap(), metadata: mediaMetadata)
        mediaTracker.trackPlay()
        waitFor(time: 3000, updatePlayhead: true)
        mediaTracker.trackPause()
        //wait for 30 mins
        waitFor(time: 600000, updatePlayhead: false)
        mediaTracker.trackEvent(event: MediaEvent.StateStart, info: standardStateCC.toMap())
        waitFor(time: 600000, updatePlayhead: false)
        mediaTracker.trackEvent(event: MediaEvent.StateEnd, info: standardStateCC.toMap())
        waitFor(time: 600000, updatePlayhead: false)
        mediaTracker.trackPlay()
        waitFor(time: 3000, updatePlayhead: false)
        mediaTracker.trackComplete()
        
        //Hits to verify
        let expectedHitsEvent: [MediaHit] = [
            MediaHit(eventType: EventType.SESSION_START, playhead: 0, ts: 0, params: expectedSessionStartParams, customMetadata: mediaMetadata),
            MediaHit(eventType: EventType.PLAY, playhead: 0, ts: 0),
            MediaHit(eventType: EventType.PLAY, playhead: 1, ts: 1000),
            MediaHit(eventType: EventType.PAUSE_START, playhead: 3, ts: 3000),
            MediaHit(eventType: EventType.STATE_START, playhead: 3, ts: 603000, params:expectedCloseCaptionParam),
            MediaHit(eventType: EventType.STATE_END, playhead: 3, ts: 1203000, params:expectedCloseCaptionParam),
            MediaHit(eventType: EventType.PING, playhead: 3, ts: 1793000),
            MediaHit(eventType: EventType.SESSION_END, playhead: 3, ts: 1803000),
            
            MediaHit(eventType: EventType.SESSION_START, playhead: 3, ts: 1803000, params: expectedSessionStartParams2, customMetadata: mediaMetadata),
            MediaHit(eventType: EventType.PLAY, playhead: 3, ts: 1803000),
            MediaHit(eventType: EventType.PLAY, playhead: 3, ts: 1804000),
            MediaHit(eventType: EventType.SESSION_COMPLETE, playhead:3 , ts: 1806000),
        ]
        
        let actualHitList: [MediaHit] = [
            fakeMediaService.getHit(sessionId: "0", index: 0)!,
            fakeMediaService.getHit(sessionId: "0", index: 1)!,
            fakeMediaService.getHit(sessionId: "0", index: 2)!,
            fakeMediaService.getHit(sessionId: "0", index: 3)!,
            fakeMediaService.getHit(sessionId: "0", index: 64)!,
            fakeMediaService.getHit(sessionId: "0", index: 125)!,
            fakeMediaService.getHit(sessionId: "0", index: 184)!,
            fakeMediaService.getHit(sessionId: "0", index: 185)!,
            
            fakeMediaService.getHit(sessionId: "1", index: 0)!,
            fakeMediaService.getHit(sessionId: "1", index: 1)!,
            fakeMediaService.getHit(sessionId: "1", index: 2)!,
            fakeMediaService.getHit(sessionId: "1", index: 3)!,
        ]
        
        //verify
        checkHit(expectedHits: expectedHitsEvent, actualHits: actualHitList)
    }
    
    func testIdleTimeOut_SessionEndAndPlay_DownloadTracker() {
        // test idel timeout after 30 mins and issue a play event, new session start
        // setup
        createTracker(downloaded: true)
        
        //test
        mediaTracker.trackSessionStart(info: mediaInfoWithDefaultPreroll.toMap(), metadata: mediaMetadata)
        mediaTracker.trackPlay()
        waitFor(time: 3000, updatePlayhead: true)
        mediaTracker.trackPause()
        //wait for 30 mins
        waitFor(time: 600000, updatePlayhead: false)
        mediaTracker.trackEvent(event: MediaEvent.StateStart, info: standardStateCC.toMap())
        waitFor(time: 600000, updatePlayhead: false)
        mediaTracker.trackEvent(event: MediaEvent.StateEnd, info: standardStateCC.toMap())
        waitFor(time: 600000, updatePlayhead: false)
        mediaTracker.trackPlay()
        waitFor(time: 3000, updatePlayhead: false)
        mediaTracker.trackComplete()
        
        //Hits to verify
        let expectedHitsEvent: [MediaHit] = [
            MediaHit(eventType: EventType.SESSION_START, playhead: 0, ts: 0, params: expectedDownloadSessionStartParams, customMetadata: mediaMetadata),
            MediaHit(eventType: EventType.PLAY, playhead: 0, ts: 0),
            MediaHit(eventType: EventType.PLAY, playhead: 1, ts: 1000),
            MediaHit(eventType: EventType.PAUSE_START, playhead: 3, ts: 3000),
            MediaHit(eventType: EventType.STATE_START, playhead: 3, ts: 603000, params:expectedCloseCaptionParam),
            MediaHit(eventType: EventType.STATE_END, playhead: 3, ts: 1203000, params:expectedCloseCaptionParam),
            MediaHit(eventType: EventType.PING, playhead: 3, ts: 1753000),
            MediaHit(eventType: EventType.SESSION_END, playhead: 3, ts: 1803000),
            
            MediaHit(eventType: EventType.SESSION_START, playhead: 3, ts: 1803000, params: expectedDownloadSessionStartParams2, customMetadata: mediaMetadata),
            MediaHit(eventType: EventType.PLAY, playhead: 3, ts: 1803000),
            MediaHit(eventType: EventType.PLAY, playhead: 3, ts: 1804000),
            MediaHit(eventType: EventType.SESSION_COMPLETE, playhead:3 , ts: 1806000),
        ]
        
        let actualHitList: [MediaHit] = [
            fakeMediaService.getHit(sessionId: "0", index: 0)!,
            fakeMediaService.getHit(sessionId: "0", index: 1)!,
            fakeMediaService.getHit(sessionId: "0", index: 2)!,
            fakeMediaService.getHit(sessionId: "0", index: 3)!,
            fakeMediaService.getHit(sessionId: "0", index: 16)!,
            fakeMediaService.getHit(sessionId: "0", index: 29)!,
            fakeMediaService.getHit(sessionId: "0", index: 40)!,
            fakeMediaService.getHit(sessionId: "0", index: 41)!,
            
            fakeMediaService.getHit(sessionId: "1", index: 0)!,
            fakeMediaService.getHit(sessionId: "1", index: 1)!,
            fakeMediaService.getHit(sessionId: "1", index: 2)!,
            fakeMediaService.getHit(sessionId: "1", index: 3)!,
        ]
        
        //verify
        checkHit(expectedHits: expectedHitsEvent, actualHits: actualHitList)
    }
}

