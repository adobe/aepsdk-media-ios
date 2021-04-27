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

class CustomStatePlayback: BaseScenarioTest {
    private typealias EventType = MediaConstants.MediaCollection.EventType
    private typealias Media = MediaConstants.MediaCollection.Media
    private typealias State = MediaConstants.MediaCollection.State

    let mediaInfo = MediaInfo(id: "mediaID", name: "mediaName", streamType: "aod", mediaType: MediaType.Audio, length: 30.0, prerollWaitingTime: 0)!
    let mediaMetadata = ["media.show": "sampleshow", "key1": "value1", "key2": "мểŧẳđαţả"]

    let customStateInfo = StateInfo(stateName: "customStateName")!
    let standardStateMute = StateInfo(stateName: MediaConstants.PlayerState.MUTE)!
    let standardStateFullScreen = StateInfo(stateName: MediaConstants.PlayerState.FULLSCREEN)!

    let semaphore = DispatchSemaphore(value: 0)

    override func setUp() {
        super.setup()
    }

    // tests
    func testCustomState_RealTimeTracker() {
        //test
        mediaTracker.trackSessionStart(info: mediaInfo.toMap(), metadata: mediaMetadata)
        mediaTracker.trackPlay()
        mediaTracker.trackEvent(event: MediaEvent.StateStart, info: customStateInfo.toMap())
        waitFor(time: 5000, updatePlayhead: true)
        mediaTracker.trackEvent(event: MediaEvent.StateEnd, info: customStateInfo.toMap())
        waitFor(time: 5000, updatePlayhead: true)
        mediaTracker.trackEvent(event: MediaEvent.StateStart, info: standardStateMute.toMap())
        mediaTracker.trackEvent(event: MediaEvent.StateStart, info: standardStateFullScreen.toMap())
        waitFor(time: 5000, updatePlayhead: true)
        mediaTracker.trackEvent(event: MediaEvent.StateEnd, info: standardStateMute.toMap())
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

        let expectedCustomStateParams: [String: Any] = [
            State.NAME: "customStateName"
        ]

        let expectedMuteStateParams: [String: Any] = [
            State.NAME: MediaConstants.PlayerState.MUTE
        ]

        let expectedFullScreenStateParams: [String: Any] = [
            State.NAME: MediaConstants.PlayerState.FULLSCREEN
        ]

        let expectedHits: [MediaHit] = [
            MediaHit(eventType: EventType.SESSION_START, playhead: 0, ts: 0, params: expectedSessionStartParams, customMetadata: mediaMetadata),
            MediaHit(eventType: EventType.PLAY, playhead: 0, ts: 0),
            MediaHit(eventType: EventType.STATE_START, playhead: 0, ts: 0, params: expectedCustomStateParams),
            MediaHit(eventType: EventType.PLAY, playhead: 1, ts: 1000),
            MediaHit(eventType: EventType.STATE_END, playhead: 5, ts: 5000, params: expectedCustomStateParams),
            MediaHit(eventType: EventType.STATE_START, playhead: 10, ts: 10000, params: expectedMuteStateParams),
            MediaHit(eventType: EventType.STATE_START, playhead: 10, ts: 10000, params: expectedFullScreenStateParams),
            MediaHit(eventType: EventType.PING, playhead: 11, ts: 11000),
            MediaHit(eventType: EventType.STATE_END, playhead: 15, ts: 15000, params: expectedMuteStateParams),
            MediaHit(eventType: EventType.SESSION_COMPLETE, playhead: 15, ts: 15000)
        ]

        //verify
        checkHits(expectedHits: expectedHits)
    }

    func testCustomState_DownloadedTracker() {
        //setup
        createTracker(downloaded: true)

        //test
        mediaTracker.trackSessionStart(info: mediaInfo.toMap(), metadata: mediaMetadata)
        mediaTracker.trackPlay()
        mediaTracker.trackEvent(event: MediaEvent.StateStart, info: customStateInfo.toMap())
        waitFor(time: 5000, updatePlayhead: true)
        mediaTracker.trackEvent(event: MediaEvent.StateEnd, info: customStateInfo.toMap())
        waitFor(time: 5000, updatePlayhead: true)
        mediaTracker.trackEvent(event: MediaEvent.StateStart, info: standardStateMute.toMap())
        mediaTracker.trackEvent(event: MediaEvent.StateStart, info: standardStateFullScreen.toMap())
        waitFor(time: 50000, updatePlayhead: true)
        mediaTracker.trackEvent(event: MediaEvent.StateEnd, info: standardStateMute.toMap())
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

        let expectedCustomStateParams: [String: Any] = [
            State.NAME: "customStateName"
        ]

        let expectedMuteStateParams: [String: Any] = [
            State.NAME: MediaConstants.PlayerState.MUTE
        ]

        let expectedFullScreenStateParams: [String: Any] = [
            State.NAME: MediaConstants.PlayerState.FULLSCREEN
        ]

        let expectedHits: [MediaHit] = [
            MediaHit(eventType: EventType.SESSION_START, playhead: 0, ts: 0, params: expectedSessionStartParams, customMetadata: mediaMetadata),
            MediaHit(eventType: EventType.PLAY, playhead: 0, ts: 0),
            MediaHit(eventType: EventType.STATE_START, playhead: 0, ts: 0, params: expectedCustomStateParams),
            MediaHit(eventType: EventType.PLAY, playhead: 1, ts: 1000),
            MediaHit(eventType: EventType.STATE_END, playhead: 5, ts: 5000, params: expectedCustomStateParams),
            MediaHit(eventType: EventType.STATE_START, playhead: 10, ts: 10000, params: expectedMuteStateParams),
            MediaHit(eventType: EventType.STATE_START, playhead: 10, ts: 10000, params: expectedFullScreenStateParams),
            MediaHit(eventType: EventType.PING, playhead: 51, ts: 51000),
            MediaHit(eventType: EventType.STATE_END, playhead: 60, ts: 60000, params: expectedMuteStateParams),
            MediaHit(eventType: EventType.SESSION_COMPLETE, playhead: 60, ts: 60000)
        ]

        //verify
        checkHits(expectedHits: expectedHits)
    }
}
