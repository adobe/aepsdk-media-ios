/*
 Copyright 2021 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0
 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES  REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

import XCTest
@testable import AEPMedia
import AEPServices

class MediaRealTimeSessionTests: XCTestCase {

    func testQueueHit() {
        //prepare
        let sessionId = "sessionId"
        let collectionServerUrl = "https://fakeurl.com"
        let eventType = MediaConstants.MediaCollection.EventType.SESSION_START
        let mediaHit = MediaHit(eventType: eventType, playhead: 0.0, ts: 0)
        let mediaState = MediaState()
        let sharedData = [MediaConstants.Configuration.SHARED_STATE_NAME: [MediaConstants.Configuration.MEDIA_COLLECTION_SERVER: collectionServerUrl]]
        mediaState.update(dataMap: sharedData)
        let mediaSession: MediaSession = MediaRealTimeSession(id: sessionId, state: mediaState, dispatchQueue: DispatchQueue(label: ""))
        ServiceProvider.shared.networkService = MockNetworking()

        //Action
        mediaSession.queue(hit: mediaHit)
        Thread.sleep(forTimeInterval: 1)

        //Assert
        XCTAssertTrue((mediaSession as! MediaRealTimeSession).hits.contains { hit in
            return hit.eventType == eventType
        })

        XCTAssertTrue((ServiceProvider.shared.networkService as! MockNetworking).connectAsyncCalled)
    }

    func testEndSession() {
        //prepare
        let sessionId = "sessionId"
        let mediaState = MediaState()
        let mediaSession = MediaRealTimeSession(id: sessionId, state: mediaState, dispatchQueue: DispatchQueue(label: ""))

        //Action
        mediaSession.end()
        Thread.sleep(forTimeInterval: 1)

        //Assert
        XCTAssertFalse(mediaSession.isSessionActive)
    }

    func testAbortSession() {
        //prepare
        let sessionId = "sessionId"
        let eventType = MediaConstants.MediaCollection.EventType.SESSION_START
        let mediaHit = MediaHit(eventType: eventType, playhead: 0.0, ts: 0)
        let mediaState = MediaState()
        let mediaSession = MediaRealTimeSession(id: sessionId, state: mediaState, dispatchQueue: DispatchQueue(label: ""))
        mediaSession.hits = [mediaHit]
        XCTAssertTrue(mediaSession.hits.count > 0)

        //Action
        mediaSession.abort()
        Thread.sleep(forTimeInterval: 1)

        //Assert
        XCTAssertFalse(mediaSession.isSessionActive)
        XCTAssertTrue(mediaSession.hits.count == 0)
    }

    //TODO Add more test cases for testing success/failure handling of networking when we have MediaState class.
}
