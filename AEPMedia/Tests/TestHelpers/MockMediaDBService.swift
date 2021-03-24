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
@testable import AEPMedia

class MockMediaDBService : MediaDBService {

    var cachedSessionId: [String] = []
    var persistedHits: [String: [MediaHit]] = [:]
    var getPersistedSessionIdsCalled = false

    override func getPersistedSessionIds() -> [String] {
        getPersistedSessionIdsCalled = true
        return cachedSessionId
    }

    override func persistHit(hit: MediaHit, sessionId: String) {
        if var hits = persistedHits[sessionId] {
            hits.append(hit)
        } else {
            let hits: [MediaHit] = [hit]
            persistedHits[sessionId] = hits
        }
    }

    override func getHits(sessionId id: String) -> [MediaHit] {        
        guard let hits = persistedHits[id] else {
            return [MediaHit]()
        }

        return hits
    }

    override func deleteHits(sessionId id: String) {
        persistedHits.removeValue(forKey: id)
    }
}
