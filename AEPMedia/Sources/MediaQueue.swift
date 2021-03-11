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

import Foundation
import AEPServices

class MediaQueue {
    
    private let databaseName: String
    private let databaseFilePath: FileManager.SearchPathDirectory
    private static let TABLE_NAME: String = "TB_MEDIA_ANALYTICS_DATA_ENTITY"
    private let serialQueue: DispatchQueue
    private let TB_KEY_EVENT_IDENTIFIER = "eventIdentifier"
    private let TB_KEY_SESSION_ID = "sessionId"
    private let TB_KEY_EVENT_TYPE = "eventType"
    private let TB_KEY_PARAMS = "params"
    private let TB_KEY_METADATA = "metadata"
    private let TB_KEY_QOE = "qoe"
    private let TB_KEY_PLAYHEAD = "playhead"
    private let TB_KEY_TIMESTAMP = "timestamp"
    private var isClosed = false

    private let LOG_PREFIX = "MediaQueue"

    /// Creates a  new `MediaQueue` with a database file path and a serial dispatch queue
    /// If it fails to create database or table, a `nil` will be returned.
    /// - Parameters:
    ///   - databaseName: the database name used to create SQLite database
    ///   - databaseFilePath: the SQLite database file will be stored in this directory, the default value is `.cachesDirectory`
    ///   - serialQueue: a serial dispatch queue used to perform database operations
    init?(databaseName: String, databaseFilePath: FileManager.SearchPathDirectory = .cachesDirectory, serialQueue: DispatchQueue) {
        self.databaseName = databaseName
        self.databaseFilePath = databaseFilePath
        self.serialQueue = serialQueue
        guard createTableIfNotExists(tableName: MediaQueue.TABLE_NAME) else {
            Log.warning(label: LOG_PREFIX, "Failed to initialize MediaQueue with database name '\(databaseName)'.")
            return nil
        }
    }
    
    func add(dbHit: MediaDBHit) -> Bool {
        if isClosed { return false}
        return serialQueue.sync {
            let insertRowStatement = """
            INSERT INTO \(MediaQueue.TABLE_NAME) (eventIdentifier, sessionId, eventType, params, metadata, qoe, playhead, timestamp)
            VALUES ("\(dbHit.eventIdentifier)", \(dbHit.sessionId), \(dbHit.eventType), \(dbHit.params), \(dbHit.metadata), \(dbHit.qoe), \(dbHit.playhead), \(dbHit.timestamp));
            """

            guard let connection = connect() else {
                return false
            }

            defer {
                disconnect(database: connection)
            }

            let result = SQLiteWrapper.execute(database: connection, sql: insertRowStatement)
            return result
        }
    }

    func peek(n: Int) -> [MediaDBHit]? {
        guard n > 0 else { return nil }
        if isClosed { return nil }
        return serialQueue.sync {
            let queryRowStatement = """
            SELECT id,eventIdentifier,sessionId,eventType,params,metadata,qoe,playhead,timestamp FROM \(MediaQueue.TABLE_NAME) ORDER BY id ASC LIMIT \(n);
            """
            guard let connection = connect() else {
                return nil
            }
            defer {
                disconnect(database: connection)
            }
            guard let result = SQLiteWrapper.query(database: connection, sql: queryRowStatement) else {
                Log.trace(label: LOG_PREFIX, "Query returned no records: \(queryRowStatement).")
                return nil
            }

            let entities = result.map({mediaDBHitFromSQLRow(row: $0)}).compactMap {$0}
            return entities
        }
    }
    
    func getHits(sessionId: String) -> [MediaDBHit]? {
        if isClosed { return nil}
        return serialQueue.sync {
            let queryRowStatement = """
            SELECT id,eventIdentifier,sessionId,eventType,params,metadata,qoe,playhead,timestamp FROM \(MediaQueue.TABLE_NAME) ORDER BY id ASC;
            """
            guard let connection = connect() else {
                return nil
            }
            defer {
                disconnect(database: connection)
            }
            guard let result = SQLiteWrapper.query(database: connection, sql: queryRowStatement) else {
                Log.trace(label: LOG_PREFIX, "Query returned no records: \(queryRowStatement).")
                return nil
            }

            let entities = result.map({mediaDBHitFromSQLRow(row: $0)}).compactMap {$0}
            return entities
        }
    }
    
    func delete(sessionId: String) -> Bool {
        if isClosed { return false}
        return serialQueue.sync {
            guard let connection = connect() else {
                return false
            }
            defer {
                disconnect(database: connection)
            }
            let deleteRowStatement = """
            DELETE FROM \(MediaQueue.TABLE_NAME) WHERE sessionId=\(sessionId);
            """
            guard SQLiteWrapper.execute(database: connection, sql: deleteRowStatement) else {
                Log.warning(label: LOG_PREFIX, "Failed to delete record for \(sessionId) from database: \(self.databaseName).")
                return false
            }
            return true
        }
    }
    
    private func connect() -> OpaquePointer? {
        if let database = SQLiteWrapper.connect(databaseFilePath: databaseFilePath, databaseName: databaseName) {
            return database
        } else {
            Log.warning(label: LOG_PREFIX, "Failed to connect to database: \(databaseName).")
            return nil
        }
    }
    
    private func disconnect(database: OpaquePointer) {
        SQLiteWrapper.disconnect(database: database)
    }
    
    private func createTableIfNotExists(tableName: String) -> Bool {
        guard let connection = connect() else {
            return false
        }
        defer {
            disconnect(database: connection)
        }
        if SQLiteWrapper.tableExists(database: connection, tableName: MediaQueue.TABLE_NAME) {
            return true
        } else {
            let createTableStatement = """
            CREATE TABLE "\(tableName)" (
                "id"                INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE,
                "eventIdentifier"   TEXT NOT NULL UNIQUE,
                "sessionId"         TEXT NOT NULL,
                "eventType"         TEXT NOT NULL,
                "params"            TEXT,
                "metadata"          TEXT,
                "qoe"               TEXT,
                "playhead"          INTEGER NOT NULL,
                "timestamp"         NTEGER NOT NULL
            );
            """

            let result = SQLiteWrapper.execute(database: connection, sql: createTableStatement)
            if result {
                Log.trace(label: LOG_PREFIX, "Successfully created table '\(tableName)'.")
            } else {
                Log.warning(label: LOG_PREFIX, "Failed to create table '\(tableName)'.")
            }

            return result
        }
    }
    
    private func mediaDBHitFromSQLRow(row: [String: String]) -> MediaDBHit? {
        guard let eventIdentifier = row[TB_KEY_EVENT_IDENTIFIER], let sessionId = row[TB_KEY_SESSION_ID], let eventType = row[TB_KEY_EVENT_TYPE], let params = row[TB_KEY_PARAMS], let metadata = row[TB_KEY_METADATA], let qoe = row[TB_KEY_QOE], let playhead = row[TB_KEY_PLAYHEAD], let timestamp = row[TB_KEY_TIMESTAMP] else {
            Log.trace(label: LOG_PREFIX, "Database record did not have valid data.")
            return nil
        }
        
        guard let convertedPlayhead = Double(playhead) else {
            Log.trace(label: LOG_PREFIX, "Database record had an invalid playhead: \(playhead).")
            return nil
        }
        
        guard let convertedTimestamp = TimeInterval(timestamp) else {
            Log.trace(label: LOG_PREFIX, "Database record had an invalid timestamp: \(timestamp).")
            return nil
        }

        return MediaDBHit(eventIdentifier: eventIdentifier, sessionId: sessionId, eventType: eventType, params: params, metadata: metadata, qoe: qoe, playhead: convertedPlayhead, timestamp: convertedTimestamp)
    }
    
}
