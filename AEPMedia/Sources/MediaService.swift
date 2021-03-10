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

class MediaService : MediaProcessor {
    
    private let LOG_TAG = "MediaService"
    private let TIMER_REPEAT_INTERVAL = 0.5
    
    private var mediaSessions: [String: MediaSession] = [:]
    private var mediaState: MediaState
    private var dispatchQueue = DispatchQueue(label: "MediaService.DispatchQueue")
    private var mediaDBService: MediaDBService
    
    init(mediaState: MediaState) {
        self.mediaState = mediaState
        mediaDBService = MediaDBService()
        initCachedSessions()
    }
    
    private func initCachedSessions() {
        let cachedSessionIds = mediaDBService.getCachedSessionIds()
        cachedSessionIds.forEach { sessionId in
            mediaSessions[sessionId] = MediaOfflineSession(id: sessionId, state: mediaState, processingQueue: dispatchQueue, mediaDBService: mediaDBService)
        }
    }
    
    func createSession(state: MediaState) -> String? {
        
        guard mediaState.privacyStatus != .optedOut else {
            Log.debug(label: LOG_TAG, "Could not start new media session. Privacy is opted out.")
            return nil
        }
        
        let isDownloaded = false //TODO: Need to update how we determine isDownloaded
        let sessionId = UUID().uuidString
        var session: MediaSession
        if isDownloaded {
            session = MediaOfflineSession(id: sessionId, state: state, processingQueue: dispatchQueue, mediaDBService: mediaDBService)
        } else {
            session = MediaRealTimeSession(id: sessionId, state: state, processingQueue: dispatchQueue)
        }
        
        mediaSessions[sessionId] = session
        Log.trace(label: LOG_TAG, "Created a new session \(sessionId)")
        return sessionId
    }
    
    func processHit(sessionId: String?, hit : MediaHit) {
        
        guard let sessionId = sessionId, !sessionId.isEmpty else {
            Log.debug(label: LOG_TAG, "\(#function) Null or empty session id passed.")
            return
        }
        
        guard mediaSessions.keys.contains(sessionId) else {
            Log.debug(label: LOG_TAG, "\(#function) Could not end media session. Invalid session id \(sessionId).")
            return
        }
        
        Log.trace(label: LOG_TAG, "\(#function) - Session (\(sessionId) Queueing hit %s.")
        let session = mediaSessions[sessionId]
        session?.queue(hit: hit)
    }
    
    func endSession(sessionId: String) {
        
        guard mediaSessions.keys.contains(sessionId) else {
            Log.debug(label: LOG_TAG, "Could not end media session. Invalid session id \(sessionId).")
            return
        }
        
        mediaSessions[sessionId]?.end {
            self.mediaSessions.removeValue(forKey: sessionId)
            Log.trace(label: self.LOG_TAG, "Successfully ends the session (\(sessionId))")
        }
        
        Log.trace(label: LOG_TAG, "Scheduled end of the session (\(sessionId))")
    }
    
    func abort(sessionId: String) {
        
        guard mediaSessions.keys.contains(sessionId) else {
            Log.debug(label: LOG_TAG, "\(#function) Unable to abort session (\(sessionId)). Session is missing.")
            return
        }
        
        mediaSessions[sessionId]?.abort()
        mediaSessions.removeValue(forKey: sessionId)
        Log.trace(label: LOG_TAG, "\(#function) Successfully aborted session (\(sessionId)).")
    }
    
    func abortAllSession() {
        for (_, session) in mediaSessions {
            session.abort()
        }
    }
}
