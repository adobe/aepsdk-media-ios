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

class Timeout: BaseScenarioTest {
    private typealias EventType = MediaConstants.MediaCollection.EventType
    private typealias Media = MediaConstants.MediaCollection.Media
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

    override func setUp() {
        setup()
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
        let expectedHitsEventSession0: [MediaHit] = [
            //session 0
            MediaHit(eventType: EventType.SESSION_START, playhead: 0, ts: 0, params: expectedSessionStartParams, customMetadata: mediaMetadata),
            MediaHit(eventType: EventType.PLAY, playhead: 0, ts: 0),
            MediaHit(eventType: EventType.PLAY, playhead: 1, ts: 1000),
            MediaHit(eventType: EventType.PING, playhead: 11, ts: 11000),
            MediaHit(eventType: EventType.PING, playhead: 86381, ts: 86381000),
            MediaHit(eventType: EventType.PING, playhead: 86391, ts: 86391000),
            MediaHit(eventType: EventType.SESSION_END, playhead: 86400, ts: 86400000)
        ]

        let expectedHitsEventSession1: [MediaHit] = [
//            //session 1
            MediaHit(eventType: EventType.SESSION_START, playhead: 86400, ts: 86400000, params: expectedSessionStartParams2, customMetadata: mediaMetadata),
            MediaHit(eventType: EventType.PLAY, playhead: 86400, ts: 86400000),
            MediaHit(eventType: EventType.PLAY, playhead: 86401, ts: 86401000),
            MediaHit(eventType: EventType.PING, playhead: 86411, ts: 86411000),
            MediaHit(eventType: EventType.SESSION_COMPLETE, playhead: 86420, ts: 86420000)
        ]

        let actualHitListSession0: [Int] = [0,1,2,3,8640,8641,8642]
        let actualHitListSession1: [Int] = [0,1,2,3,4]

        //verify
        checkHits(expectedHits: expectedHitsEventSession0, sessionId: "0", actualHitIndexList: actualHitListSession0)
        checkHits(expectedHits: expectedHitsEventSession1, sessionId: "1", actualHitIndexList: actualHitListSession1)
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
        let expectedHitsEventSession0: [MediaHit] = [
            //session 0
            MediaHit(eventType: EventType.SESSION_START, playhead: 0, ts: 0, params: expectedDownloadSessionStartParams, customMetadata: mediaMetadata),
            MediaHit(eventType: EventType.PLAY, playhead: 0, ts: 0),
            MediaHit(eventType: EventType.PLAY, playhead: 1, ts: 1000),
            MediaHit(eventType: EventType.PING, playhead: 51, ts: 51000),
            MediaHit(eventType: EventType.PING, playhead: 86351, ts: 86351000),
            MediaHit(eventType: EventType.SESSION_END, playhead: 86400, ts: 86400000)
        ]

        let expectedHitsEventSession1: [MediaHit] = [
            //session 1
            MediaHit(eventType: EventType.SESSION_START, playhead: 86400, ts: 86400000, params: expectedDownloadSessionStartParams2, customMetadata: mediaMetadata),
            MediaHit(eventType: EventType.PLAY, playhead: 86400, ts: 86400000),
            MediaHit(eventType: EventType.PLAY, playhead: 86401, ts: 86401000),
            MediaHit(eventType: EventType.PING, playhead: 86451, ts: 86451000),
            MediaHit(eventType: EventType.SESSION_COMPLETE, playhead: 86460, ts: 86460000)
        ]

        let actualHitListSession0: [Int] = [0,1,2,3,1729,1730]
        let actualHitListSession1: [Int] = [0,1,2,3,4]

        //verify
        checkHits(expectedHits: expectedHitsEventSession0, sessionId: "0", actualHitIndexList: actualHitListSession0)
        checkHits(expectedHits: expectedHitsEventSession1, sessionId: "1", actualHitIndexList: actualHitListSession1)
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

        let actualHitList: [Int] = [0,1,2,3,182,183]

        //verify
        checkHits(expectedHits: expectedHitsEvent, sessionId: "0", actualHitIndexList: actualHitList)
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

        let actualHitList: [Int] = [0,1,2,3,38,39]

        //verify
        checkHits(expectedHits: expectedHitsEvent, sessionId: "0", actualHitIndexList: actualHitList)
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
        let expectedHitsEventSession0: [MediaHit] = [
            MediaHit(eventType: EventType.SESSION_START, playhead: 0, ts: 0, params: expectedSessionStartParams, customMetadata: mediaMetadata),
            MediaHit(eventType: EventType.PLAY, playhead: 0, ts: 0),
            MediaHit(eventType: EventType.PLAY, playhead: 1, ts: 1000),
            MediaHit(eventType: EventType.PAUSE_START, playhead: 3, ts: 3000),
            MediaHit(eventType: EventType.STATE_START, playhead: 3, ts: 603000, params:expectedCloseCaptionParam),
            MediaHit(eventType: EventType.STATE_END, playhead: 3, ts: 1203000, params:expectedCloseCaptionParam),
            MediaHit(eventType: EventType.PING, playhead: 3, ts: 1793000),
            MediaHit(eventType: EventType.SESSION_END, playhead: 3, ts: 1803000),
        ]

        let expectedHitsEventSession1: [MediaHit] = [
            MediaHit(eventType: EventType.SESSION_START, playhead: 3, ts: 1803000, params: expectedSessionStartParams2, customMetadata: mediaMetadata),
            MediaHit(eventType: EventType.PLAY, playhead: 3, ts: 1803000),
            MediaHit(eventType: EventType.PLAY, playhead: 3, ts: 1804000),
            MediaHit(eventType: EventType.SESSION_COMPLETE, playhead:3 , ts: 1806000),
        ]


        let actualHitListSession0: [Int] = [0,1,2,3,64,125,184,185]
        let actualHitListSession1: [Int] = [0,1,2,3]

        //verify
        checkHits(expectedHits: expectedHitsEventSession0, sessionId: "0", actualHitIndexList: actualHitListSession0)
        checkHits(expectedHits: expectedHitsEventSession1, sessionId: "1", actualHitIndexList: actualHitListSession1)
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
        let expectedHitsEventSession0: [MediaHit] = [
            MediaHit(eventType: EventType.SESSION_START, playhead: 0, ts: 0, params: expectedDownloadSessionStartParams, customMetadata: mediaMetadata),
            MediaHit(eventType: EventType.PLAY, playhead: 0, ts: 0),
            MediaHit(eventType: EventType.PLAY, playhead: 1, ts: 1000),
            MediaHit(eventType: EventType.PAUSE_START, playhead: 3, ts: 3000),
            MediaHit(eventType: EventType.STATE_START, playhead: 3, ts: 603000, params:expectedCloseCaptionParam),
            MediaHit(eventType: EventType.STATE_END, playhead: 3, ts: 1203000, params:expectedCloseCaptionParam),
            MediaHit(eventType: EventType.PING, playhead: 3, ts: 1753000),
            MediaHit(eventType: EventType.SESSION_END, playhead: 3, ts: 1803000),
        ]

        let expectedHitsEventSession1: [MediaHit] = [
            MediaHit(eventType: EventType.SESSION_START, playhead: 3, ts: 1803000, params: expectedDownloadSessionStartParams2, customMetadata: mediaMetadata),
            MediaHit(eventType: EventType.PLAY, playhead: 3, ts: 1803000),
            MediaHit(eventType: EventType.PLAY, playhead: 3, ts: 1804000),
            MediaHit(eventType: EventType.SESSION_COMPLETE, playhead:3 , ts: 1806000),
        ]

        let actualHitListSession0: [Int] = [0,1,2,3,16,29,40,41]
        let actualHitListSession1: [Int] = [0,1,2,3]

        //verify
        checkHits(expectedHits: expectedHitsEventSession0, sessionId: "0", actualHitIndexList: actualHitListSession0)
        checkHits(expectedHits: expectedHitsEventSession1, sessionId: "1", actualHitIndexList: actualHitListSession1)
    }
}

