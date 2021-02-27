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

class MediaOfflineSession : MediaSession {
    
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
    
    private let id: String
    private var state: MediaState
    private let LOG_TAG = "MediaOfflineSession"
    private var mediaDBService: MediaDBService
    private var isReportingSession: Bool
    private var isSessionActive: Bool
    private let MAX_ALLOWED_FAILURE: UInt8 = 2
    private var failureCount = 0
    private var sessionState: MediaSessionState
    
                    
    init(id: String, state: MediaState) {
        self.id = id
        self.state = state
        self.mediaDBService = MediaDBService()
        self.isReportingSession = false
        self.isSessionActive = true
        sessionState = .Active
    }
    
    func queue(hit: MediaHit?) {
        
        guard let hit = hit else {
            Log.debug(label: LOG_TAG, "\(#function) - Session \(id) hit is null.")
            return
        }
        
        guard isSessionActive else {
            Log.debug(label: LOG_TAG, "\(#function) - Session \(id) not Active.")
            return
        }
        
        mediaDBService.persistHit(hit: hit, sessionId: id)
        Log.debug(label: LOG_TAG, "\(#function) - Session \(id) persisting hit \(hit.eventType).")
    }
    
    func process() {
        
    }
                    
    func end() {
        guard isSessionActive else {
            Log.debug(label: LOG_TAG, "\(#function) - Session \(id) is inactive")
            return
        }
        
        reportSession()
        Log.debug(label: LOG_TAG, "\(#function) - Session \(id) is ended")
        isSessionActive = false
    }
    
    func abort() {
        
        guard isSessionActive else {
            Log.debug(label: LOG_TAG, "\(#function) - Session \(id) is inactive")
            return
        }
        
        mediaDBService.deleteSessionHits(sessionId: id)
        isSessionActive = false
        Log.debug(label: LOG_TAG, "\(#function) - Session \(id) is aborted.")
    }
    
    private func reportSession() {
        guard !isReportingSession else {
            Log.trace(label: LOG_TAG, "\(#function) - Exiting as we are currently sending session report.")
            return
        }
        
        guard MediaSessionHelper.isReadyToSendHit(state: state) else {
            Log.trace(label: LOG_TAG, "\(#function) - Exiting as session is not ready for sending hits.")
            return
        }
        
        var hits = mediaDBService.getHits(sessionId: id)
        let url = MediaSessionHelper.getTrackingURL(url: state.getMediaCollectionServer())
        let body = MediaSessionHelper.generateHitReport(state: state, hit: hits)
        
        guard !url.isEmpty, !body.isEmpty else {
            Log.debug(label: LOG_TAG, "\(#function) - Could not generate downloaded content report from persisted hits for session \(id). Clearing persisted pings.")
            if shouldClearSession() {
                mediaDBService.deleteSessionHits(sessionId: id)
                sessionState = .Invalid
                return
            }
        }
        
        
        if let url = URL.init(string: url) {
            isReportingSession = true
            let networkService = ServiceProvider.shared.networkService
            let networkrequest = NetworkRequest(url: url, httpMethod: .post, connectPayload: body, httpHeaders: [String:String](), connectTimeout: MediaConstants.Networking.HTTP_TIMEOUT_SECONDS, readTimeout: MediaConstants.Networking.HTTP_TIMEOUT_SECONDS)
         
        networkService.connectAsync(networkRequest: networkrequest) { connection in
            self.isReportingSession = false;
            if connection.error == nil {
                let statusCode = connection.response?.statusCode ?? -1
                if MediaConstants.Networking.HTTP_SUCCESS_RANGE.contains(statusCode) {
                    Log.debug(label: self.LOG_TAG, "\(#function) - \(self.id) Http failed with response code (\(statusCode))")
                    
                    self.sessionState = .Reported
                    
                    
                    if self.shouldClearSession() {
                        Log.trace(label: self.LOG_TAG, "ReportSessions - Clearing persisted pings for session \(self.id).")
                        self.mediaDBService.deleteSessionHits(sessionId: self.id)
                        return
                    }
                }
                    
                else {
                    Log.trace(label: self.LOG_TAG, "\(#function) \(self.id) Media collection endpoint returns nil location header.")
                }
            } else if let error = connection.error as? URLError, error.code == URLError.Code.notConnectedToInternet {
                self.sessionState = .Failed
                //TODO handle no internet connection here.
            } else {
                self.sessionState = .Failed
                //TODO handle all other errors here.
            }
        }
    }
    }
    
    private func shouldClearSession() -> Bool {
        
        if (sessionState == .Reported || sessionState == .Invalid) {
            return true;
        }
        
        if (sessionState == .Failed) {
            return failureCount > MAX_ALLOWED_FAILURE;
        }
        
        return false
    }
}
