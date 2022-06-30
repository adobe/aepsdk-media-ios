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

class MediaServiceTest: XCTestCase {

    func testInitPersistedSessions() {

        // setup
        let persistedSessionIds: Set<String> = ["sessionId1", "sessionId2"]
        let mockDBService = MockMediaDBService()
        mockDBService.persistedSessionIds = persistedSessionIds

        // Action
        let mediaService = MediaService(mediaDBService: mockDBService)
        mediaService.readyToProcess(dispatchFn: {_ in })
        Thread.sleep(forTimeInterval: 0.25)

        // Assert
        XCTAssertTrue(mockDBService.getPersistedSessionIdsCalled)

    }

    func testCreateSession() {

        // setup
        let mockDBService = MockMediaDBService()
        let emptyConfig = [String: Any]()

        // Action
        let mediaService: MediaService = MediaService(mediaDBService: mockDBService)

        let sessionId = mediaService.createSession(config: emptyConfig)

        // Assert
        XCTAssertNotNil(sessionId)
        XCTAssertTrue(mediaService.mediaSessions.keys.contains(sessionId!))
        XCTAssertNotNil(mediaService.mediaSessions[sessionId!])

    }

    func testProcessHit() {
        // setup
        let mockDBService = MockMediaDBService()
        let eventType = "test_event"
        let mediaHit = MediaHit(eventType: eventType, playhead: 0.0, ts: 0)
        let emptyConfig = [String: Any]()

        // Action
        let mediaService = MediaService(mediaDBService: mockDBService)

        let sessionId = mediaService.createSession(config: emptyConfig)
        let mockMediaSession = MockMediaSession(id: sessionId!, state: MediaState(), dispatchQueue: DispatchQueue(label: ""))
        mediaService.mediaSessions[sessionId!] = mockMediaSession
        mediaService.processHit(sessionId: sessionId!, hit: mediaHit)
        Thread.sleep(forTimeInterval: 0.25)

        // Assert
        XCTAssertTrue(mockMediaSession.hasQueueHitCalled)
        XCTAssertTrue(mockMediaSession.hits.contains { hit in
            hit.eventType == eventType
        })
    }

    func testEndSession() {
        // setup
        let mockDBService = MockMediaDBService()
        let emptyConfig = [String: Any]()

        // Action
        let mediaService = MediaService(mediaDBService: mockDBService)

        let sessionId = mediaService.createSession(config: emptyConfig)
        let mockMediaSession = MockMediaSession(id: sessionId!, state: MediaState(), dispatchQueue: DispatchQueue(label: ""))
        mediaService.mediaSessions[sessionId!] = mockMediaSession
        mediaService.endSession(sessionId: sessionId!)
        Thread.sleep(forTimeInterval: 0.25)

        // Assert
        XCTAssertTrue(mockMediaSession.hasSessionEndCalled)
        XCTAssertFalse(mediaService.mediaSessions.keys.contains(sessionId!))
    }

    func testAbortSession() {
        // setup
        let mockDBService = MockMediaDBService()

        // Action
        let mediaService = MediaService(mediaDBService: mockDBService)
        let emptyConfig = [String: Any]()

        let sessionId = mediaService.createSession(config: emptyConfig)
        let mockMediaSession = MockMediaSession(id: sessionId!, state: MediaState(), dispatchQueue: DispatchQueue(label: ""))
        mediaService.mediaSessions[sessionId!] = mockMediaSession

        let event = Event(name: "", type: "", source: "", data: nil)
        mediaService.updateMediaState(event: event) { (state: String, _: Event, _: Bool) -> SharedStateResult? in
            if state == MediaConstants.Configuration.SHARED_STATE_NAME {
                let configSharedState = [MediaConstants.Configuration.GLOBAL_CONFIG_PRIVACY: PrivacyStatus.optedOut.rawValue]
                return SharedStateResult(status: .set, value: configSharedState)
            } else {
                return nil
            }
        }
        Thread.sleep(forTimeInterval: 0.25)

        // Assert
        XCTAssertTrue(mockMediaSession.hasSesionAbortCalled)
        XCTAssertFalse(mediaService.mediaSessions.keys.contains(sessionId!))
    }
}
