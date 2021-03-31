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
import AEPServices

class MediaHitsDatabaseTests: XCTestCase {
    
    private var hitsDatabase: MediaHitsDatabase!
    private let databaseFilePath = FileManager.SearchPathDirectory.cachesDirectory
    private let fileName = "MediaOfflineDatabaseTests"
    private let params = ["key": "value", "true": true] as [String: Any]
    private let metadata = ["isUserLoggedIn": "false", "tvStation": "SampleTVStation"] as [String: String]
    private let qoeData = ["qoe.startuptime": 0, "qoe.fps": 24, "qoe.droppedframes": 10, "qoe.bitrate": 60000] as [String: Any]
    
    override func setUp() {
        MediaHitsDatabaseTests.removeDatabaseFileIfExists(fileName)
        let dispatchQueue = DispatchQueue.init(label: fileName)
        hitsDatabase = MediaHitsDatabase(databaseName: fileName, databaseFilePath: databaseFilePath, serialQueue: dispatchQueue)
    }
    
    internal static func removeDatabaseFileIfExists(_ fileName: String) {
        let fileURL = try! FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent(fileName)
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try! FileManager.default.removeItem(at: fileURL)
        }
    }
    
    private func createHitFromData(data: Data) -> MediaHit? {
        var hit: MediaHit?
        if let retrievedHit = try? JSONDecoder().decode(MediaHit.self, from: data) {
            hit = retrievedHit
        }
        return hit
    }
    
    func testCreateDatabaseWithInvalidDatabaseName() throws {
        // setup
        let dispatchQueue = DispatchQueue.init(label: fileName)
        hitsDatabase = MediaHitsDatabase(databaseName: "", databaseFilePath: databaseFilePath, serialQueue: dispatchQueue)
        // verify
        XCTAssertNil(hitsDatabase)
    }
    
    func testDatabaseAdd() throws {
        // setup and test
        let sessionId = UUID().uuidString
        var addedHits: [MediaHit] = []
        for i in 1 ... 3 {
            let mediaHit = MediaHit(eventType: MediaConstants.Media.EVENT_TYPE, playhead: Double(i) * 50.0, ts: Double(i) * 100.0, params: params, customMetadata: metadata, qoeData: qoeData)
            let data = try JSONEncoder().encode(mediaHit)
            _ = hitsDatabase.add(sessionId: sessionId, data: data)
            addedHits.append(mediaHit)
        }
        // verify
        XCTAssertEqual(3, hitsDatabase.count())
        guard let retrievedData = hitsDatabase.getDataFor(sessionId: sessionId) else {
            XCTFail("Failed to retrieve entities from the database")
            return
        }
        var index = 0
        for data in retrievedData {
            let retrievedHit = createHitFromData(data: data)
            XCTAssertEqual(retrievedHit, addedHits[index])
            index += 1
        }
    }
    
    func testDatabaseAddWithNonWholeNumbers() throws {
        // setup and test
        let sessionId = UUID().uuidString
        var addedHits: [MediaHit] = []
        for i in 1 ... 3 {
            let mediaHit = MediaHit(eventType: MediaConstants.Media.EVENT_TYPE, playhead: Double(i) * 50.123456789, ts: Date().timeIntervalSince1970, params: params, customMetadata: metadata, qoeData: qoeData)
            let data = try JSONEncoder().encode(mediaHit)
            _ = hitsDatabase.add(sessionId: sessionId, data: data)
            addedHits.append(mediaHit)
        }
        // verify that non whole number playhead and timestamp values are valid
        XCTAssertEqual(3, hitsDatabase.count())
        guard let retrievedData = hitsDatabase.getDataFor(sessionId: sessionId) else {
            XCTFail("Failed to retrieve entities from the database")
            return
        }
        var index = 0
        for data in retrievedData {
            let retrievedHit = createHitFromData(data: data)
            XCTAssertEqual(retrievedHit, addedHits[index])
            index += 1
        }
    }
    
    func testDatabaseClear() throws {
        // setup and test
        let sessionId = UUID().uuidString
        for i in 1 ... 10 {
            let mediaHit = MediaHit(eventType: MediaConstants.Media.EVENT_TYPE, playhead: Double(i) * 50.0, ts: Double(i) * 100.0, params: params, customMetadata: metadata, qoeData: qoeData)
            let data = try JSONEncoder().encode(mediaHit)
            _ = hitsDatabase.add(sessionId: sessionId, data: data)
        }
        // verify
        XCTAssertEqual(10, hitsDatabase.count())
        XCTAssertTrue(hitsDatabase.clear())
        XCTAssertEqual(0, hitsDatabase.count())
    }
    
    func testDatabaseDeleteForSessionId() throws {
        // setup and test
        let sessionId = UUID().uuidString
        var addedHits: [MediaHit] = []
        for i in 1 ... 10 {
            let mediaHit = MediaHit(eventType: MediaConstants.Media.EVENT_TYPE, playhead: Double(i) * 50.0, ts: Double(i) * 100.0, params: params, customMetadata: metadata, qoeData: qoeData)
            let data = try JSONEncoder().encode(mediaHit)
            _ = hitsDatabase.add(sessionId: sessionId, data: data)
            addedHits.append(mediaHit)
        }
        XCTAssertEqual(10, hitsDatabase.count())
        let anotherSessionId = UUID().uuidString
        for i in 11 ... 20 {
            let mediaHit = MediaHit(eventType: MediaConstants.Media.EVENT_TYPE, playhead: Double(i) * 50.0, ts: Double(i) * 100.0, params: params, customMetadata: metadata, qoeData: qoeData)
            let data = try JSONEncoder().encode(mediaHit)
            _ = hitsDatabase.add(sessionId: anotherSessionId, data: data)
        }
        // verify
        XCTAssertEqual(20, hitsDatabase.count())
        XCTAssertTrue(hitsDatabase.deleteDataFor(sessionId: anotherSessionId))
        XCTAssertEqual(10, hitsDatabase.count())
        guard let retrievedData = hitsDatabase.getDataFor(sessionId: sessionId) else {
            XCTFail("Failed to retrieve entities from the database")
            return
        }
        var index = 0
        for data in retrievedData {
            let retrievedHit = createHitFromData(data: data)
            XCTAssertEqual(retrievedHit, addedHits[index])
            index += 1
        }
    }
    
    func testGetAllSessionIds() throws {
        // setup and test
        var addedSessions: Set<String> = []
        var secondSetOfAddedSessions: Set<String> = []
        for i in 1 ... 10 {
            let sessionId = UUID().uuidString
            let mediaHit = MediaHit(eventType: MediaConstants.Media.EVENT_TYPE, playhead: Double(i) * 50.0, ts: Double(i) * 100.0, params: params, customMetadata: metadata, qoeData: qoeData)
            let data = try JSONEncoder().encode(mediaHit)
            _ = hitsDatabase.add(sessionId: sessionId, data: data)
            addedSessions.insert(sessionId)
        }
        XCTAssertEqual(10, hitsDatabase.count())
        for i in 11 ... 20 {
            let anotherSessionId = UUID().uuidString
            let mediaHit = MediaHit(eventType: MediaConstants.Media.EVENT_TYPE, playhead: Double(i) * 50.0, ts: Double(i) * 100.0, params: params, customMetadata: metadata, qoeData: qoeData)
            let data = try JSONEncoder().encode(mediaHit)
            _ = hitsDatabase.add(sessionId: anotherSessionId, data: data)
            secondSetOfAddedSessions.insert(anotherSessionId)
        }
        // verify
        XCTAssertEqual(20, hitsDatabase.count())
        let retrievedSessions = hitsDatabase.getAllSessions()
        let allSessions = addedSessions.union(secondSetOfAddedSessions)
        XCTAssertEqual(allSessions, retrievedSessions)
    }
}
