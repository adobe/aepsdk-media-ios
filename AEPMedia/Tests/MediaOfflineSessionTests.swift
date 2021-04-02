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

import Foundation
import XCTest
import AEPServices
import AEPCore
@testable import AEPMedia

class MediaOfflineSessionTests: XCTestCase {
    
    var dispatchQueue = DispatchQueue(label: "dispatchQueue")
    
    func testQueueMediaHit() {
        //Setup
        let sessionId = "sessionid"
        let eventType = "event_type"
        let mediaDBService = MockMediaDBService()
        let mediaHit = MediaHit(eventType: eventType, playhead: 0.0, ts: 0)
        let mediaSession: MediaSession = MediaOfflineSession(id: sessionId, state: MediaState(), dispatchQueue: dispatchQueue, mediaDBService: mediaDBService)
        
        //Action
        mediaSession.queue(hit: mediaHit)
        
        Thread.sleep(forTimeInterval: 1)
        
        //Assert
        XCTAssertEqual(mediaDBService.persistedHits[sessionId]?.count ?? 0, 1)
        XCTAssertEqual(mediaDBService.persistedHits[sessionId]?[0].eventType ?? "", eventType)
        
    }
    
    func testEndSession() {
        //Setup
        let sessionId = "sessionid"
        let eventType = "event_type"
        let mockMediaDBService = MockMediaDBService()
        let mediaHit = MediaHit(eventType: eventType, playhead: 0.0, ts: 0)
        mockMediaDBService.persistedHits[sessionId] = [mediaHit]
        let mockNetworking = MockNetworking()
        ServiceProvider.shared.networkService = mockNetworking
        
        let sharedData = [MediaConstants.Configuration.SHARED_STATE_NAME: [
            MediaConstants.Configuration.GLOBAL_CONFIG_PRIVACY: PrivacyStatus.optedIn.rawValue,
            MediaConstants.Configuration.EXPERIENCE_CLOUD_ORGID:"orgid",
            MediaConstants.Configuration.ANALYTICS_TRACKING_SERVER: "analytics_tracking_Server",
            MediaConstants.Configuration.MEDIA_COLLECTION_SERVER: "media_collection_Server",
            MediaConstants.Configuration.ANALYTICS_RSID: "analytics_rsid"],
        MediaConstants.Identity.SHARED_STATE_NAME: [MediaConstants.Identity.MARKETING_VISITOR_ID: "ecid"]]
        let state = MediaState()
        state.update(dataMap: sharedData)
        
        let mediaSession: MediaSession = MediaOfflineSession(id: sessionId, state: state, dispatchQueue: dispatchQueue, mediaDBService: mockMediaDBService)
        
        //Action
        mediaSession.end()
        
        Thread.sleep(forTimeInterval: 2)
        
        //Assert
        XCTAssertTrue(mockNetworking.hasNetworkRequestReceived)
        XCTAssertFalse((mediaSession as! MediaOfflineSession).isSessionActive)
    }
    
    func testAbortSession() {
        //Setup
        var hasSessionEnded: Bool = false
        let sessionId = "sessionid"
        let eventType = "event_type"
        let mediaDBService = MockMediaDBService()

        let mediaHit = MediaHit(eventType: eventType, playhead: 0.0, ts: 0)
        mediaDBService.persistedHits[sessionId] = [mediaHit]
        
        let mediaSession: MediaSession = MediaOfflineSession(id: sessionId, state: MediaState(), dispatchQueue: dispatchQueue, mediaDBService: mediaDBService)
        
        //Action
        mediaSession.abort {
            hasSessionEnded = true
        }
        
        Thread.sleep(forTimeInterval: 1)
        
        //Assert
        XCTAssertTrue(hasSessionEnded)
        XCTAssertFalse((mediaSession as! MediaOfflineSession).isSessionActive)
        XCTAssertEqual(mediaDBService.persistedHits.count, 0)
    }
    
    
}


