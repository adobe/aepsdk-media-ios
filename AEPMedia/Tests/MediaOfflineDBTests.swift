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
    
    private var mediaDb: MediaOfflineDB!
    private let databaseFilePath = FileManager.SearchPathDirectory.cachesDirectory
    private let fileName = "MediaOfflineDBTests"
    
    private struct EventEntity: Codable {
        var id: UUID
        var timestamp: Date
        var name: String
    }
    
    override func setUp() {
        MediaOfflineDBTests.removeDbFileIfExists(fileName)
        let dispatchQueue = DispatchQueue.init(label: fileName)
        mediaDb = MediaOfflineDB(databaseName: fileName, databaseFilePath: databaseFilePath, serialQueue: dispatchQueue)
    }
    
    override func tearDown() {}
    
    internal static func removeDbFileIfExists(_ fileName: String) {
        let fileURL = try! FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent(fileName)
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try! FileManager.default.removeItem(at: fileURL)
        }
    }
    
    func testDBClear() throws {
        let sessionId = UUID().uuidString
        var events: [EventEntity] = []
        for i in 1 ... 10 {
            let event = EventEntity(id: UUID(), timestamp: Date(), name: "event00\(i)")
            events.append(event)
            let data = try JSONEncoder().encode(event)
            let entity = DataEntity(uniqueIdentifier: event.id.uuidString, timestamp: event.timestamp, data: data)
            _ = mediaDb.add(dataEntity: entity, sessionId: sessionId)
        }
        let entities = mediaDb.getHits(sessionId: sessionId)
        let peeked = mediaDb.peek(n: 3)!
        XCTAssertEqual(3, peeked.count)
        XCTAssertEqual(10, mediaDb.count())
        XCTAssertTrue(mediaDb.clear())
        XCTAssertEqual(0, mediaDb.count())
    }
    
    func testDBDelete() throws {
        let sessionId = UUID().uuidString
        var events: [EventEntity] = []
        for i in 1 ... 10 {
            let event = EventEntity(id: UUID(), timestamp: Date(), name: "event00\(i)")
            events.append(event)
            let data = try JSONEncoder().encode(event)
            let entity = DataEntity(uniqueIdentifier: event.id.uuidString, timestamp: event.timestamp, data: data)
            _ = mediaDb.add(dataEntity: entity, sessionId: sessionId)
        }
        let entities = mediaDb.getHits(sessionId: sessionId)
        let peeked = mediaDb.peek(n: 3)!
        XCTAssertEqual(3, peeked.count)
        XCTAssertEqual(10, mediaDb.count())
        let sessionId2 = UUID().uuidString
        events = []
        for i in 10 ... 19 {
            let event = EventEntity(id: UUID(), timestamp: Date(), name: "event00\(i)")
            events.append(event)
            let data = try JSONEncoder().encode(event)
            let entity = DataEntity(uniqueIdentifier: event.id.uuidString, timestamp: event.timestamp, data: data)
            _ = mediaDb.add(dataEntity: entity, sessionId: sessionId2)
        }
        XCTAssertEqual(20, mediaDb.count())
        XCTAssertTrue(mediaDb.delete(sessionId: sessionId2))
        XCTAssertEqual(10, mediaDb.count())
    }
}
