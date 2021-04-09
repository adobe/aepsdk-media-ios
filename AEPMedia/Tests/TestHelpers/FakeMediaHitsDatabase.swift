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

import AEPCore
@testable import AEPMedia

class FakeMediaHitsDatabase: MediaHitsDatabase {
    var addedData: [String: [Data]] = [:]
    var sessionIds: Set<String> = []
    private var queue = DispatchQueue(label: "FakeMediaHitsDatabase")

    init?() {
        super.init(databaseName: "FakeMediaHitsDatabase", serialQueue: queue)
    }

    override func add(sessionId: String, data: Data) -> Bool {
        if addedData[sessionId] == nil {
            addedData[sessionId] = [data]
        } else {
            addedData[sessionId]?.append(data)
        }
        sessionIds.insert(sessionId)
        return true
    }

    override func deleteDataFor(sessionId: String) -> Bool {
        addedData[sessionId]?.removeAll()
        sessionIds = sessionIds.filter {$0 != sessionId}
        return true
    }

    override func getDataFor(sessionId: String) -> [Data]? {
        return addedData[sessionId]
    }

    override func getAllSessions() -> Set<String> {
        return sessionIds
    }
}
