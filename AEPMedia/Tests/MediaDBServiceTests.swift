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
import Foundation
@testable import AEPCore
@testable import AEPMedia

class MediaDBServiceTests: XCTestCase {
    private var mediaDbService: MediaDBService!
    private var fakeMediaHitsDatabase: FakeMediaHitsDatabase!
    private var queue = DispatchQueue(label: "MediaDBServiceTests")
    
    override func setUp() {
        fakeMediaHitsDatabase = FakeMediaHitsDatabase()
        mediaDbService = MediaDBService(serialQueue: queue, mediaHitsDatabase: fakeMediaHitsDatabase)
    }
    
    func testPersistHitsForSameSessionId() {
        // setup
        var addedHits: [MediaHit] = []
        let sessionId = UUID().uuidString
        // test
        for i in 1 ... 3 {
            let hit = MediaHit(eventType: "sessionStart", playhead: Double(100 * i), ts: Date().timeIntervalSince1970)
            mediaDbService.persistHit(hit: hit, sessionId: sessionId)
            addedHits.append(hit)
        }
        // verify
        let retrievedHits = mediaDbService.getHits(sessionId: sessionId)
        for i in 0 ... 2 {
            XCTAssertEqual(retrievedHits[i], addedHits[i])
        }
    }
    
    func testPersistHitsForDifferentSessionIdsThenDeleteHitsForOneSession() {
        // setup
        var addedHits: [MediaHit] = []
        var sessionIds: [String] = []
        // test
        var sessionId = UUID().uuidString
        sessionIds.append(sessionId)
        for i in 1 ... 5 {
            let hit = MediaHit(eventType: "sessionStart", playhead: Double(100 * i), ts: Date().timeIntervalSince1970)
            mediaDbService.persistHit(hit: hit, sessionId: sessionId)
            addedHits.append(hit)
            
        }
        sessionId = UUID().uuidString
        sessionIds.append(sessionId)
        for i in 1 ... 5 {
            let hit = MediaHit(eventType: "chapterStart", playhead: Double(100 * i), ts: Date().timeIntervalSince1970)
            mediaDbService.persistHit(hit: hit, sessionId: sessionId)
            addedHits.append(hit)
        }
        sessionId = UUID().uuidString
        sessionIds.append(sessionId)
        for i in 1 ... 5 {
            let hit = MediaHit(eventType: "sessionComplete", playhead: Double(100 * i), ts: Date().timeIntervalSince1970)
            mediaDbService.persistHit(hit: hit, sessionId: sessionId)
            addedHits.append(hit)
        }
        mediaDbService.deleteHits(sessionId: sessionIds[2])
        // verify
        for i in 0 ... 4 {
            let retrievedHits = mediaDbService.getHits(sessionId: sessionIds[0])
            XCTAssertEqual(retrievedHits[i], addedHits[i])
        }
        for i in 5 ... 9 {
            let retrievedHits = mediaDbService.getHits(sessionId: sessionIds[1])
            XCTAssertEqual(retrievedHits[i-5], addedHits[i])
        }
        XCTAssertEqual([], mediaDbService.getHits(sessionId: sessionIds[2]))
    }
    
    func testGetPersistedSessionIds() {
        // setup
        var sessionIds: Set<String> = []
        // test
        for i in 1 ... 10 {
            let sessionId = UUID().uuidString
            sessionIds.insert(sessionId)
            let hit = MediaHit(eventType: "sessionStart", playhead: Double(100 * i), ts: Date().timeIntervalSince1970)
            mediaDbService.persistHit(hit: hit, sessionId: sessionId)
        }
        // verify
        let retrievedSesssionIds = mediaDbService.getPersistedSessionIds()
        XCTAssertEqual(retrievedSesssionIds, sessionIds)
    }
}
