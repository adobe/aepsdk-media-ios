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

class FakeMediaHitProcessor: MediaProcessor {

    private var sessionEnded = false
    private var processedHits: [String: [MediaHit]] = [:]
    private var currentSessionId: String = "-1"
    private var isSessionStartCalled = false
    
    func createSession(config: [String : Any]) -> String? {
        isSessionStartCalled = true
        var intSessionId = (Int(currentSessionId) ?? 0)
        intSessionId += 1
        currentSessionId = "\(intSessionId)"
        processedHits[currentSessionId] = []
        // for testing failed session creation
        if let forcedFail = config["testFail"] as? Bool, forcedFail == true {
            return nil
        }
        return currentSessionId
    }
    
    func endSession(sessionId: String) {
        sessionEnded = true
    }
    
    func processHit(sessionId: String, hit: MediaHit) {
        processedHits[sessionId]?.append(hit)
    }
    
    func getHitFromActiveSession(index: Int) -> MediaHit? {
        return getHit(sessionId: currentSessionId, index: index)
    }
    
    private func getHit(sessionId: String, index: Int) -> MediaHit? {
        guard let hits = processedHits[sessionId], hits.count != 0 else {
            return nil
        }
        
        if index >= hits.count {
            return nil
        }
        
        return hits[index]
    }
    
    func getHitCountFromActiveSession() -> Int {
        return getHitCount(sessionId: currentSessionId)
    }
    
    func getHitCount(sessionId: String) -> Int {
        return processedHits[sessionId]?.count ?? 0
    }
    
    func clearHitsFromActiveSession() {
        if processedHits[currentSessionId] != nil {
            processedHits[currentSessionId]?.removeAll()
        }
    }
}

class MockMediaSession : MediaSession {
    func processHit(hit: MediaHit) {
        //stub
    }

    func end() {
        //stub
    }

    func abort() {
        //stub
    }
}
