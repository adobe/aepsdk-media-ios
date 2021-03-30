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
import AEPServices

class MediaDBService {
    private static let LOG_TAG = "MediaDBService"

    #if DEBUG
        var mediaHitsDatabase: MediaHitsDatabase?
    #else
        private var mediaHitsDatabase: MediaHitsDatabase?
    #endif
    private var sessionIds: [String] = []

    /// Creates a  new `MediaDBService` which manages a `MediaHitsDatabase` to persist offline Media hits.
    /// - Parameters:
    ///   - serialQueue: a serial dispatch queue used to perform database operations
    init(serialQueue: DispatchQueue) {
        self.mediaHitsDatabase = MediaHitsDatabase(databaseName: MediaConstants.DATABASE_NAME, serialQueue: serialQueue)
    }

    /// Persists an offline `MediaHit` in the `MediaHitsDatabase`.
    /// - Parameters:
    ///   - hit: the `MediaHit` to be persisted
    ///   - sessionId: a `String` containing the session id of the hit to be added
    func persistHit(hit: MediaHit, sessionId: String) {
        guard let data = try? JSONEncoder().encode(hit) else {
            Log.error(label: Self.LOG_TAG, "Failed to encode hit for event type: \(hit.eventType).")
            return
        }

        if let success = mediaHitsDatabase?.add(sessionId: sessionId, data: data), success == true {
            Log.trace(label: Self.LOG_TAG, "Successfully added hit for event type: \(hit.eventType).")
            if !sessionIds.contains(sessionId) {
                sessionIds.append(sessionId)
            }
        } else {
            Log.error(label: Self.LOG_TAG, "Failed to add hit for event type: \(hit.eventType).")
        }
    }

    /// Deletes hits in the `MediaHitsDatabase` for the given session id.
    /// - Parameter sessionId: a `String` containing the session id of the hits to be deleted from the database
    func deleteHits(sessionId id: String) {
        if let success = mediaHitsDatabase?.deleteDataFor(sessionId: id), success == true {
            Log.trace(label: Self.LOG_TAG, "Deleted hits for session id: \(id).")
            sessionIds = sessionIds.filter {$0 != id}
        } else {
            Log.error(label: Self.LOG_TAG, "Failed to delete hits for session id: \(id).")
        }
    }

    /// Retrieves hits in the `MediaHitsDatabase` for the given session id.
    /// - Parameter sessionId: a `String` containing the session id of the hits to be retrieved from the database
    /// - Returns: an array of `MediaHit` objects which match the given session id
    func getHits(sessionId id: String) -> [MediaHit] {
        var retrievedHits: [MediaHit] = []
        Log.trace(label: Self.LOG_TAG, "Retrieving hits for session id: \(id).")
        let retrievedData = mediaHitsDatabase?.getDataFor(sessionId: id) ?? []
        for data in retrievedData {
            if let hit = try? JSONDecoder().decode(MediaHit.self, from: data) {
                retrievedHits.append(hit)
            }
        }
        return retrievedHits
    }

    /// Retrieves the session id's currently persisted in the `MediaHitsDatabase`.
    /// - Returns: an array of `Strings` containing the session id's of hits currently stored in the database
    func getPersistedSessionIds() -> [String] {
        return sessionIds
    }
}
