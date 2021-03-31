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

class MediaService: MediaProcessor {

    private let LOG_TAG = "MediaService"
    private let dependencies = [MediaConstants.Configuration.SHARED_STATE_NAME, MediaConstants.Identity.SHARED_STATE_NAME, MediaConstants.Analytics.SHARED_STATE_NAME]
    #if DEBUG
        var mediaSessions: [String: MediaSession] = [:]
    #else
        private var mediaSessions: [String: MediaSession] = [:]
    #endif
    private var mediaState: MediaState
    private var dispatchQueue = DispatchQueue(label: "MediaService.DispatchQueue")
    private var mediaDBService: MediaDBService

    init(mediaDBService: MediaDBService? = nil) {
        self.mediaState = MediaState()
        if let mediaDBService = mediaDBService {
            self.mediaDBService = mediaDBService
        } else {
            self.mediaDBService = MediaDBService(serialQueue: dispatchQueue)
        }

        initPersistedSessions()
    }

    ///Reads the persisted offline session in DB, create `MediaSession` objects for them and initiate the reporting of `MediaSessions.`
    private func initPersistedSessions() {
        let persistedSessionIds = mediaDBService.getPersistedSessionIds()
        persistedSessionIds.forEach { sessionId in
            let mediaOfflineSession = MediaOfflineSession(id: sessionId, state: mediaState, dispatchQueue: dispatchQueue, mediaDBService: mediaDBService)
            mediaSessions[sessionId] = mediaOfflineSession
            mediaOfflineSession.end {
                self.mediaSessions.removeValue(forKey: sessionId)
            }
        }
    }

    func createSession(config: [String:Any]) -> String? {
        guard mediaState.privacyStatus != .optedOut else {
            Log.debug(label: LOG_TAG, "\(#function) - Could not start new media session. Privacy is opted out.")
            return nil
        }

        let isDownloaded = config[MediaConstants.TrackerConfig.DOWNLOADED_CONTENT] as? Bool ?? false
        let sessionId = UUID().uuidString
        var session: MediaSession
        if isDownloaded {
            session = MediaOfflineSession(id: sessionId, state: mediaState, dispatchQueue: dispatchQueue, mediaDBService: mediaDBService)
        } else {
            session = MediaRealTimeSession(id: sessionId, state: mediaState, dispatchQueue: dispatchQueue)
        }

        mediaSessions[sessionId] = session
        Log.trace(label: LOG_TAG, "\(#function) - Created a new session (\(sessionId))")
        return sessionId
    }

    /// Queues the `MediaHit` hit in session `sessionId`
    ///- Parameters:
    ///    - sessionId: UniqueId of session to which `MediaHit` belongs.
    ///    - hit: `Object` of type `MediaHit`
    func processHit(sessionId: String, hit: MediaHit) {
        guard mediaSessions.keys.contains(sessionId) else {
            Log.debug(label: LOG_TAG, "\(#function) - Can not process session (\(sessionId)). SessionId is invalid.")
            return
        }

        let session = mediaSessions[sessionId]
        session?.queue(hit: hit)
        Log.trace(label: LOG_TAG, "\(#function) - Successfully queued hit (\(hit.eventType) for Session (\(sessionId)).")
    }

    /// Ends the session `sessionId`. In case of Offline session, sends the report to MediaAnalytics collection server.
    ///
    /// - Parameter sessionId: Unique session id for session to end.
    func endSession(sessionId: String) {

        guard mediaSessions.keys.contains(sessionId) else {
            Log.debug(label: LOG_TAG, "\(#function) - Can not end media session (\(sessionId)). Invalid session id.")
            return
        }

        mediaSessions[sessionId]?.end {
            self.mediaSessions.removeValue(forKey: sessionId)
            Log.trace(label: self.LOG_TAG, "\(#function) - Successfully ended media session (\(sessionId))")
        }

        Log.trace(label: LOG_TAG, "\(#function) - Scheduled end of the media session (\(sessionId))")
    }

    /// Abort the session `sessionId`.
    ///
    /// - Parameter sessionId: Unique sessionId of session to be aborted.
    func abort(sessionId: String) {

        guard mediaSessions.keys.contains(sessionId) else {
            Log.debug(label: LOG_TAG, "\(#function) - can not abort media session (\(sessionId)). SessionId is invalid.")
            return
        }

        mediaSessions[sessionId]?.abort {
            self.mediaSessions.removeValue(forKey: sessionId)
            Log.trace(label: self.LOG_TAG, "\(#function) - Successfully aborted media session (\(sessionId)).")
        }

        Log.trace(label: LOG_TAG, "\(#function) - Scheduled session abort for Session (\(sessionId).")
    }

    /// Aborts all the active sessions.
    func abortAllSessions() {
        for (sessionId, _) in mediaSessions {
            abort(sessionId: sessionId)
        }
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
}
