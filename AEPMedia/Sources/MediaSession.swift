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
    
    enum MediaSessionState {
        // Session absent in our store / exceeded retries.
        case Invalid
        // Session is currently being tracked.
        case Active
        // Session is complete and waiting to be reported.
        case Complete
        // Session is reported to backend and we will clear the hits from db.
        case Reported
        // Session failed to report to backend. We will clear the hits from db if we exceed retries.
        case Failed
    }
    static let DURATION_BETWEEN_HITS_ON_FAILURE: UInt64 = 30 * 1000_000_000  //Convert 30 seconds into nanoseconds.
        
    var id: String
    var mediaState: MediaState
    var isSessionActive: Bool
    var eventsHandler: MediaSessionEventsHandler?
    var dispatchQueue: DispatchQueue
    var sessionEndHandler: (() -> Void)?
    
    init(id: String, mediaState: MediaState, processingQueue: DispatchQueue) {
        self.id = id
        self.mediaState = mediaState
        isSessionActive = true
        dispatchQueue = processingQueue
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
            Log.debug(label: eventsHandler?.LOG_TAG ?? "", "\(#function) - Unable to queue hit. MediaHit passed is nil.")
            return
        }
        
        guard isSessionActive else {
            Log.debug(label: eventsHandler?.LOG_TAG ?? "", "\(#function) - Unable to queue hit. Media Session is inactive.")
            return
        }
        
        dispatchQueue.async {
            self.eventsHandler?.queueMediaHit(hit: hit)
        }
    }

    func end(onSessionEnd sessionEndHandler: (() -> Void)? = nil) {
        
        guard isSessionActive else {
            Log.debug(label: eventsHandler?.LOG_TAG ?? "", "\(#function) - Unable to end session. Session (\(id)) is inactive")
            return
        }
        
        self.sessionEndHandler = sessionEndHandler
        dispatchQueue.async {
            self.eventsHandler?.endSession()
        }
    }

    func abort(onSessionEnd sessionEndHandler: (() -> Void)? = nil) {
        
        guard isSessionActive else {
            Log.debug(label: eventsHandler?.LOG_TAG ?? "", "\(#function) - Unable to abort session. Session (\(id)) is inactive")
            return
        }
        
        self.sessionEndHandler = sessionEndHandler
        dispatchQueue.async {
            self.eventsHandler?.abortSession()
        }
    }
}

/**
 Declares the functions that handles Media hit related events in Media session.
 */
protocol MediaSessionEventsHandler {
    
    var LOG_TAG: String {get}
    func endSession()
    func abortSession()
    func queueMediaHit(hit: MediaHit)
}
