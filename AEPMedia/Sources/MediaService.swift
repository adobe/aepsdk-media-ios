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
import AEPCore
import AEPServices

// TODO: replace with final implementation
class MediaService : MediaProcessor {
    
    private let LOG_TAG = "MediaService"
    
    private var mediaState: MediaState
    private let dependencies = [MediaConstants.Configuration.SHARED_STATE_NAME, MediaConstants.Identity.SHARED_STATE_NAME, MediaConstants.Analytics.SHARED_STATE_NAME]
    
    init() {
        self.mediaState = MediaState()
    }
    
    func createSession(config: [String : Any]) -> String? {
        return ""
    }
    
    func processHit(sessionId: String, hit: MediaHit) {
        
    }
    
    func endSession(sessionId: String) {
        
    }
    
    func updateMediaState(event: Event, getSharedState: (String, Event, Bool) -> SharedStateResult?) {
        var sharedStates = [String: [String: Any]?]()
        for extensionName in dependencies {
            sharedStates[extensionName] = getSharedState(extensionName, event, true)?.value
        }
        mediaState.update(dataMap: sharedStates)
        if mediaState.getPrivacyStatus() == .optedOut {
            abortAllSessions()
        }
    }
    
    func abort() {
    
    }
    
    func abortAllSessions() {
    
    }
}
