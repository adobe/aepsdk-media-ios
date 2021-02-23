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

class MockMediaHitProcessor: MediaHitProcessor {
    private var sessionEnded = false
    private var processedHits: [Int: [MediaHit]] = [:]
    private var currentSessionId: Int = -1
    private var isSessionStartCalled = false
    
    override func startSession() -> Int {
        isSessionStartCalled = true
        currentSessionId += 1
        processedHits[currentSessionId] = []
        return currentSessionId
    }
    
    override func endSession(sessionID: Int) {
        sessionEnded = true
    }
    
    override func processHit(sessionID: Int, hit: MediaHit) {
        processedHits[sessionID]?.append(hit)
    }
    
    func getHitFromActiveSession(index: Int) -> MediaHit? {
        return getHit(sessionID: currentSessionId, index: index)
    }
    
    func getHitCountFromActiveSession() -> Int {
        return getHitCount(sessionID: currentSessionId)
    }
    
    private func getHit(sessionID: Int, index: Int) -> MediaHit? {
        guard let hits = processedHits[sessionID], hits.count != 0 else {
            return nil
        }
        
        if index >= hits.count {
            return nil
        }
        
        return hits[index]
    }
    
    func getHitCount(sessionID: Int) -> Int {
        return processedHits[sessionID]?.count ?? 0
    }
    
    func clearHitsFromActiveSession() {
        if processedHits[currentSessionId] != nil {
            processedHits[currentSessionId]?.removeAll()
        }
    }
}
