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

class MediaServiceTest: XCTestCase {

    func testInitCachedSessions() {
        
        //setup
        let cachedSessionIds = ["sessionId1","sessionId2"]
        let mockDBService = MockMediaDBService()
        mockDBService.cachedSessionId = cachedSessionIds
        
        //Action
        let mediaService: MediaService = MediaService(mediaState: MediaState(), mediaDBService:mockDBService)
        
        //Assert
        XCTAssertTrue(mediaService.mediaSessions.keys.contains(cachedSessionIds[0]))
        XCTAssertTrue(mediaService.mediaSessions.keys.contains(cachedSessionIds[1]))
        
    }
    
    func testCreateSession() {
        
        //setup
        let mockDBService = MockMediaDBService()
        let emptyConfig = [String:Any]()
        
        //Action
        let mediaService: MediaService = MediaService(mediaState: MediaState(), mediaDBService:mockDBService)
        
        let sessionId = mediaService.createSession(config: emptyConfig)
        
        //Assert
        XCTAssertNotNil(sessionId)
        XCTAssertTrue(mediaService.mediaSessions.keys.contains(sessionId!))
        XCTAssertNotNil(mediaService.mediaSessions[sessionId!])
        
    }
    
    func testProcessHit() {
        //setup
        let mockDBService = MockMediaDBService()
        let eventType = "test_event"
        let mediaHit = MediaHit(eventType: eventType, params: nil, customMetada: nil, qoeData: nil, playhead: 0.0, ts: TimeInterval())
        let emptyConfig = [String:Any]()
        
        //Action
        let mediaService = MediaService(mediaState: MediaState(), mediaDBService:mockDBService)
        
        let sessionId = mediaService.createSession(config: emptyConfig)
        let mockMediaSession = MockMediaSession(id: sessionId!, mediaState: MediaState(), processingQueue: DispatchQueue(label: ""))
        mediaService.mediaSessions[sessionId!] = mockMediaSession
        mediaService.processHit(sessionId: sessionId!, hit: mediaHit)
        Thread.sleep(until: .init(timeIntervalSinceNow: 1))
        
        //Assert
        XCTAssertTrue(mockMediaSession.hasQueueHitCalled)
        XCTAssertTrue(mockMediaSession.hits.contains { hit in
            hit.eventType == eventType
        })
    }
    
    func testEndSession() {
        //setup
        let mockDBService = MockMediaDBService()
        let emptyConfig = [String:Any]()
                
        //Action
        let mediaService = MediaService(mediaState: MediaState(), mediaDBService:mockDBService)
        
        let sessionId = mediaService.createSession(config: emptyConfig)
        let mockMediaSession = MockMediaSession(id: sessionId!, mediaState: MediaState(), processingQueue: DispatchQueue(label: ""))
        mediaService.mediaSessions[sessionId!] = mockMediaSession
        mediaService.endSession(sessionId: sessionId!)
        Thread.sleep(until: .init(timeIntervalSinceNow: 1))
        
        //Assert
        XCTAssertTrue(mockMediaSession.hasSessionEndCalled)
        XCTAssertFalse(mediaService.mediaSessions.keys.contains(sessionId!))
    }
    
    func testAbortSession() {
        //setup
        let mockDBService = MockMediaDBService()
                
        //Action
        let mediaService = MediaService(mediaState: MediaState(), mediaDBService: mockDBService)
        let emptyConfig = [String:Any]()
        
        let sessionId = mediaService.createSession(config: emptyConfig)
        let mockMediaSession = MockMediaSession(id: sessionId!, mediaState: MediaState(), processingQueue: DispatchQueue(label: ""))
        mediaService.mediaSessions[sessionId!] = mockMediaSession
        mediaService.abort(sessionId: sessionId!)
        Thread.sleep(until: .init(timeIntervalSinceNow: 1))
        
        //Assert
        XCTAssertTrue(mockMediaSession.hasSesionAbortCalled)
        XCTAssertFalse(mediaService.mediaSessions.keys.contains(sessionId!))
    }
}
