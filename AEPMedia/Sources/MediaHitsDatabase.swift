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

class MediaHitsDatabase {
    private static let LOG_TAG = "MediaHitsDatabase"

    private let databaseName: String
    private let databaseFilePath: FileManager.SearchPathDirectory
    private let serialQueue: DispatchQueue
    private static let TABLE_NAME: String = "TB_MEDIA_ANALYTICS_OFFLINE_HITS"
    private let TB_KEY_SESSION_ID = "sessionId"
    private let TB_KEY_DATA = "data"

    /// Creates a  new `MediaHitsDatabase` with a database file path and a serial dispatch queue
    /// If it fails to create database or table, a `nil` will be returned.
    /// - Parameters:
    ///   - databaseName: the database name used to create SQLite database
    ///   - databaseFilePath: the SQLite database file will be stored in this directory, the default value is `.cachesDirectory`
    ///   - serialQueue: a serial dispatch queue used to perform database operations
    init?(databaseName: String, databaseFilePath: FileManager.SearchPathDirectory = .cachesDirectory, serialQueue: DispatchQueue) {
        self.databaseName = databaseName
        self.databaseFilePath = databaseFilePath
        self.serialQueue = serialQueue
        guard createTableIfNotExists(tableName: Self.TABLE_NAME) else {
            Log.warning(label: Self.LOG_TAG, "Failed to initialize MediaHitsDatabase with database name '\(databaseName)'.")
            return nil
        }
    }

    func add(sessionId: String, data: Data) -> Bool {
        return serialQueue.sync {
            let dataString = String(data: data, encoding: .utf8) ?? ""
            let insertRowStatement = """
            INSERT INTO \(Self.TABLE_NAME) (sessionId, data) VALUES ("\(sessionId)", '\(dataString)');
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

    func getDataFor(sessionId: String) -> [Data]? {
        return serialQueue.sync {
            let queryRowStatement = """
            SELECT id,sessionId,data FROM \(Self.TABLE_NAME) WHERE sessionId='\(sessionId)';
            """
            guard let connection = connect() else {
                return nil
            }
            defer {
                disconnect(database: connection)
            }
            guard let result = SQLiteWrapper.query(database: connection, sql: queryRowStatement) else {
                Log.trace(label: Self.LOG_TAG, "Query returned no records: \(queryRowStatement).")
                return nil
            }

            var retrievedData: [Data] = []
            let results = result.map({dataFromSQLRow(row: $0)}).compactMap({$0})
            for result in results {
                retrievedData.append(result)
            }
            return retrievedData
        }
    }

    func deleteDataFor(sessionId: String) -> Bool {
        return serialQueue.sync {
            guard let connection = connect() else {
                return false
            }
            defer {
                disconnect(database: connection)
            }
            let deleteRowStatement = """
            DELETE FROM \(Self.TABLE_NAME) WHERE sessionId='\(sessionId)';
            """
            guard SQLiteWrapper.execute(database: connection, sql: deleteRowStatement) else {
                Log.warning(label: Self.LOG_TAG, "Failed to delete record for \(sessionId) from database: \(self.databaseName).")
                return false
            }
            return true
        }
    }

    func clear() -> Bool {
        return serialQueue.sync {
            let dropTableStatement = """
            DELETE FROM \(Self.TABLE_NAME);
            """
            guard let connection = connect() else {
                return false
            }
            defer {
                disconnect(database: connection)
            }
            guard SQLiteWrapper.execute(database: connection, sql: dropTableStatement) else {
                Log.warning(label: Self.LOG_TAG, "Failed to clear table '\(Self.TABLE_NAME)' in database: \(self.databaseName).")
                return false
            }

            return true
        }
    }

    func count() -> Int {
        return serialQueue.sync {
            let queryRowStatement = """
            SELECT count(id) FROM \(Self.TABLE_NAME);
            """
            guard let connection = connect() else {
                return 0
            }
            defer {
                disconnect(database: connection)
            }
            guard let result = SQLiteWrapper.query(database: connection, sql: queryRowStatement), let countAsString = result.first?.first?.value else {
                Log.trace(label: Self.LOG_TAG, "Query returned no records: \(queryRowStatement).")
                return 0
            }

            return Int(countAsString) ?? 0
        }
    }

    private func connect() -> OpaquePointer? {
        if let database = SQLiteWrapper.connect(databaseFilePath: databaseFilePath, databaseName: databaseName) {
            return database
        }
        Log.warning(label: Self.LOG_TAG, "Failed to connect to database: \(databaseName).")
        return nil
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
        if SQLiteWrapper.tableExists(database: connection, tableName: Self.TABLE_NAME) {
            return true
        } else {
            let createTableStatement = """
            CREATE TABLE "\(tableName)" (
                "id"          INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE,
                "sessionId"   TEXT NOT NULL,
                "data"        TEXT
            );
            """

            guard SQLiteWrapper.execute(database: connection, sql: createTableStatement) else {
                Log.warning(label: Self.LOG_TAG, "Failed to create table '\(tableName)'.")
                return false
            }

            Log.trace(label: Self.LOG_TAG, "Successfully created table '\(tableName)'.")
            return true
        }
    }

    private func dataFromSQLRow(row: [String: String]) -> Data? {
        guard let dataString = row[TB_KEY_DATA] else {
            Log.trace(label: Self.LOG_TAG, "Database record did not have valid data.")
            return nil
        }

        guard !dataString.isEmpty else {
            return nil
        }
        return dataString.data(using: .utf8)
    }

}
