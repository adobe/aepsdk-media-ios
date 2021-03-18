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

class MediaOfflineDBTests: XCTestCase {
    
    private var offlineDb: MediaOfflineDB!
    private let databaseFilePath = FileManager.SearchPathDirectory.cachesDirectory
    private let fileName = "MediaOfflineDBTests"
    private let params = ["key": "value", "true": true] as [String: Any]
    private let metadata = ["isUserLoggedIn": "false", "tvStation": "SampleTVStation"] as [String: String]
    private let qoeData = ["qoe.startuptime": 0, "qoe.fps": 24, "qoe.droppedframes": 10, "qoe.bitrate": 60000] as [String: Any]
    
    override func setUp() {
        MediaOfflineDBTests.removeDbFileIfExists(fileName)
        let dispatchQueue = DispatchQueue.init(label: fileName)
        offlineDb = MediaOfflineDB(databaseName: fileName, databaseFilePath: databaseFilePath, serialQueue: dispatchQueue)
    }
    
    override func tearDown() {}
    
    internal static func removeDbFileIfExists(_ fileName: String) {
        let fileURL = try! FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent(fileName)
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try! FileManager.default.removeItem(at: fileURL)
        }
    }
    
    private func getHitFromDataEntity(entity: DataEntity) -> MediaHit? {
        var hit: MediaHit?
        if let data = entity.data, let jsonData = try? JSONDecoder().decode([String: AnyCodable].self, from: data), let dict = AnyCodable.toAnyDictionary(dictionary: jsonData) {
            let eventType = dict["eventType"] as? String ?? ""
            let playhead = dict["playhead"] as? Double ?? 0
            let ts = dict["timestamp"] as? TimeInterval ?? TimeInterval(0)
            let params = dict["params"] as? [String: Any] ?? [:]
            let metadata = dict["metadata"] as? [String: String] ?? [:]
            let qoeData = dict["qoeData"] as? [String: Any] ?? [:]
            hit = MediaHit.init(eventType: eventType, playhead: playhead, ts: ts, params: params, customMetadata: metadata, qoeData: qoeData)
        }
        return hit
    }
    
    func testDBAdd() throws {
        // setup and test
        let sessionId = UUID().uuidString
        var addedHits: [MediaHit] = []
        var count = 0
        repeat {
            let eventId = UUID().uuidString
            let mediaHit = MediaHit(eventType: MediaConstants.Media.EVENT_TYPE, playhead: 0, ts: 0, params: params, customMetadata: metadata, qoeData: qoeData)
            let data = try JSONEncoder().encode(mediaHit)
            let entity = DataEntity(uniqueIdentifier: eventId, timestamp: Date(), data: data)
            _ = offlineDb.add(sessionId: sessionId, dataEntity: entity)
            addedHits.append(mediaHit)
            count += 1
        } while count < 3
        // verify
        XCTAssertEqual(3, offlineDb.count())
        guard let entities = offlineDb.getEntitiesFor(sessionId: sessionId) else {
            XCTFail("Failed to retrieve entities from the database")
            return
        }
        count = 0
        for entity in entities {
            let retrievedHit = getHitFromDataEntity(entity: entity.entity)
            XCTAssertEqual(retrievedHit, addedHits[count])
            count += 1
        }
    }
    
    func testDBClear() throws {
        let sessionId = UUID().uuidString
        var addedEntities: [String: DataEntity] = [:]
        var count = 0
        repeat {
            let eventId = UUID().uuidString
            let mediaHit = MediaHit(eventType: MediaConstants.Media.EVENT_TYPE, playhead: 0, ts: 0, params: params, customMetadata: metadata, qoeData: qoeData)
            let data = try JSONEncoder().encode(mediaHit)
            let entity = DataEntity(uniqueIdentifier: eventId, timestamp: Date(), data: data)
            _ = offlineDb.add(sessionId: sessionId, dataEntity: entity)
            addedEntities[eventId] = entity
            count += 1
        } while count < 10
        let entities = offlineDb.getEntitiesFor(sessionId: sessionId)
        let peeked = offlineDb.peek(n: 3)!
        XCTAssertEqual(3, peeked.count)
        XCTAssertEqual(10, offlineDb.count())
        XCTAssertTrue(offlineDb.clear())
        XCTAssertEqual(0, offlineDb.count())
    }
    
    func testDBDelete() throws {
        let sessionId = UUID().uuidString
        var addedEntities: [String: DataEntity] = [:]
        var count = 0
        repeat {
            let eventId = UUID().uuidString
            let mediaHit = MediaHit(eventType: MediaConstants.Media.EVENT_TYPE, playhead: 0, ts: 0, params: params, customMetadata: metadata, qoeData: qoeData)
            let data = try JSONEncoder().encode(mediaHit)
            let entity = DataEntity(uniqueIdentifier: eventId, timestamp: Date(), data: data)
            _ = offlineDb.add(sessionId: sessionId, dataEntity: entity)
            addedEntities[eventId] = entity
            count += 1
        } while count < 10
        XCTAssertEqual(10, offlineDb.count())
        let anotherSessionId = UUID().uuidString
        repeat {
            let eventId = UUID().uuidString
            let mediaHit = MediaHit(eventType: MediaConstants.Media.EVENT_TYPE, playhead: 0, ts: 0, params: params, customMetadata: metadata, qoeData: qoeData)
            let data = try JSONEncoder().encode(mediaHit)
            let entity = DataEntity(uniqueIdentifier: eventId, timestamp: Date(), data: data)
            _ = offlineDb.add(sessionId: anotherSessionId, dataEntity: entity)
            addedEntities[eventId] = entity
            count += 1
        } while count < 20
        XCTAssertEqual(20, offlineDb.count())
        XCTAssertTrue(offlineDb.deleteEntitiesFor(sessionId: anotherSessionId))
        XCTAssertEqual(10, offlineDb.count())
    }
}
