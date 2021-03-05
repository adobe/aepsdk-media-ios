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

class MediaSession {
    
    private let LOG_TAG = "MediaSession"
    var id: String
    var mediaState: MediaState
    var isSessionActive: Bool
    var eventsHandler: MediaSessionEventsHandler?
    
    init(id: String, mediaState: MediaState) {
        self.id = id
        self.mediaState = mediaState
        isSessionActive = true
    }
    
    func isReadyToSendHit() -> Bool {
         
        guard mediaState.privacyStatus == .optedIn else {
            return false
        }
        
        //TODO: implement rest of the conditions.
        
        return true
    }
    
    func queue(hit: MediaHit?) {
        guard let hit = hit else {
            Log.debug(label: LOG_TAG, "\(#function) - Unable to queue hit. MediaHit passed is nil.")
            return
        }
        
        guard isSessionActive else {
            Log.debug(label: LOG_TAG, "\(#function) - Unable to queue hit. Media Session is inactive.")
            return
        }
        
        eventsHandler?.queue(hit: hit)
    }
    
    func process() {
        
        guard isSessionActive else {
            Log.debug(label: LOG_TAG, "\(#function) - Unable to process session. Session (\(id)) is inactive")
            return
        }
        
        eventsHandler?.processSession()
    }

    func end() {
        
        guard isSessionActive else {
            Log.debug(label: LOG_TAG, "\(#function) - Unable to end session. Session (\(id)) is inactive")
            return
        }
        
        eventsHandler?.endSession()
    }

    func abort() {
        
        guard isSessionActive else {
            Log.debug(label: LOG_TAG, "\(#function) - Unable to abort session. Session (\(id)) is inactive")
            return
        }
        
        eventsHandler?.abortSession()
    }
}


protocol MediaSessionEventsHandler {
    
    func processSession()
    func endSession()
    func abortSession()
    func queue(hit: MediaHit)
}
