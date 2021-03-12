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

class MockMediaSession : MediaSession, MediaSessionEventsHandler {
    
    var LOG_TAG: String = ""
    var hits: [MediaHit] = []
    var hasQueueHitCalled = false
    var hasSessionEndCalled = false
    var hasSesionAbortCalled = false
    
    override init(id: String, mediaState: MediaState, processingQueue: DispatchQueue) {
        super.init(id: id, mediaState: mediaState, processingQueue: processingQueue)
        self.eventsHandler = self
    }
    
    func endSession() {
        hasSessionEndCalled = true
        sessionEndHandler?()
    }
    
    func abortSession() {
        hasSesionAbortCalled = true
        sessionEndHandler?()
    }
    
    func queueMediaHit(hit: MediaHit) {
        hasQueueHitCalled = true
        hits.append(hit)
    }
}
