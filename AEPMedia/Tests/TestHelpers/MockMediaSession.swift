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

class MockMediaSession: MediaSession {

    var LOG_TAG: String = ""
    var hits: [MediaHit] = []
    var hasQueueHitCalled = false
    var hasSessionEndCalled = false
    var hasSesionAbortCalled = false

    override init(id: String, state: MediaState, dispatchQueue: DispatchQueue) {
        super.init(id: id, state: state, dispatchQueue: dispatchQueue)
    }

    override func handleSessionEnd() {
        hasSessionEndCalled = true
        sessionEndHandler?()
    }

    override func handleSessionAbort() {
        hasSesionAbortCalled = true
        sessionEndHandler?()
    }

    override func handleQueueMediaHit(hit: MediaHit) {
        hasQueueHitCalled = true
        hits.append(hit)
    }
}
