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
    
    #if DEBUG
    var mediaSessions: [String: MediaSession] = [:]
    #else
    private var mediaSessions: [String: MediaSession] = [:]
    #endif
    private var mediaState: MediaState
    private var dispatchQueue = DispatchQueue(label: "MediaService.DispatchQueue")
    private var mediaDBService: MediaDBService
    
    init(mediaState: MediaState, mediaDBService: MediaDBService = MediaDBService()) {
        self.mediaState = mediaState
        self.mediaDBService = mediaDBService
        initCachedSessions()
    }
    
    ///Reads the cached offline session in DB, create `MediaSession` objects for them and initiate the reporting of `MediaSessions.`
    private func initCachedSessions() {
        let cachedSessionIds = mediaDBService.getCachedSessionIds()
        cachedSessionIds.forEach { sessionId in
            let mediaOfflineSession = MediaOfflineSession(id: sessionId, state: mediaState, processingQueue: dispatchQueue, mediaDBService: mediaDBService)
            mediaSessions[sessionId] = mediaOfflineSession
            mediaOfflineSession.end {
                self.mediaSessions.removeValue(forKey: sessionId)
            }
        }
    }
    
    func createSession() -> String? {
        
        guard mediaState.privacyStatus != .optedOut else {
            Log.debug(label: LOG_TAG, "Could not start new media session. Privacy is opted out.")
            return nil
        }
        
        let isDownloaded = false //TODO: Need to update how we determine isDownloaded
        let sessionId = UUID().uuidString
        var session: MediaSession
        if isDownloaded {
            session = MediaOfflineSession(id: sessionId, state: mediaState, processingQueue: dispatchQueue, mediaDBService: mediaDBService)
        } else {
            session = MediaRealTimeSession(id: sessionId, state: mediaState, processingQueue: dispatchQueue)
        }
        
        mediaSessions[sessionId] = session
        Log.trace(label: LOG_TAG, "Created a new session \(sessionId)")
        return sessionId
    }
    
    /// Queues the `MediaHit` hit in session `sessionId`
    ///- Parameters:
    ///    - sessionId: UniqueId of session to which `MediaHit` belongs.
    ///    - hit: `Object` of type `MediaHit`
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
    
    /// Ends the session `sessionId`. In case of Offline session, sends the report to MediaAnalytics collection server.
    ///
    /// - Parameter sessionId: Unique session id for session to end.
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
    
    /// Abort the session `sessionId`.
    ///
    /// - Parameter sessionId: Unique sessionId of session to be aborted.
    func abort(sessionId: String) {
        
        guard mediaSessions.keys.contains(sessionId) else {
            Log.debug(label: LOG_TAG, "\(#function) Unable to abort session (\(sessionId)). Session is missing.")
            return
        }
        
        mediaSessions[sessionId]?.abort {
            self.mediaSessions.removeValue(forKey: sessionId)
            Log.trace(label: self.LOG_TAG, "\(#function) Successfully aborted session (\(sessionId)).")
        }
        
        Log.trace(label: LOG_TAG, "\(#function) Scheduled session abort for Session (\(sessionId).")
    }
    
    /// Aborts all the active sessions.
    func abortAllSession() {
        for (sessionId, _) in mediaSessions {
            abort(sessionId: sessionId)
        }
    }
}
