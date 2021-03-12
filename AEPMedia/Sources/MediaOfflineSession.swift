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

class MediaOfflineSession : MediaSession, MediaSessionEventsHandler {        
            
    var LOG_TAG = "MediaOfflineSession"
    private var mediaDBService: MediaDBService
    private var isReportingSession: Bool    
    private let MAX_ALLOWED_FAILURE: Int8 = 2
    private var failureCount = 0
    private var sessionState: MediaSessionState    
                    
    init(id: String, state: MediaState, processingQueue dispatchQueue: DispatchQueue, mediaDBService: MediaDBService) {
        self.mediaDBService = mediaDBService
        isReportingSession = false
        sessionState = .Active
        super.init(id: id, mediaState: state, processingQueue: dispatchQueue)
        eventsHandler = self
    }
    
    func queueMediaHit(hit: MediaHit) {
        mediaDBService.persistHit(hit: hit, sessionId: id)
        Log.debug(label: LOG_TAG, "\(#function) - Session (\(id)) persisted hit (\(hit.eventType)).")
    }
                    
    func endSession() {
        reportSession()
        Log.debug(label: LOG_TAG, "\(#function) - Session (\(id)) is ended")
        isSessionActive = false
    }
    
    func abortSession() {
        mediaDBService.deleteHits(sessionId: id)
        isSessionActive = false
        sessionEndHandler?()
        Log.trace(label: LOG_TAG, "\(#function) - Session (\(id)) is aborted.")
    }
    
    private func reportSession() {
        guard !isReportingSession else {
            Log.debug(label: LOG_TAG, "\(#function) - Exiting as we are currently sending session report (\(id).")
            return
        }
        
        guard isReadyToSendHit() else {
            Log.debug(label: LOG_TAG, "\(#function) - Exiting as session (\(id) is not ready for sending hits.")
            return
        }
        
        let hits = mediaDBService.getHits(sessionId: id)
        let url = MediaCollectionReportHelper.getTrackingURL(url: mediaState.getMediaCollectionServer())
        let body = MediaCollectionReportHelper.generateHitReport(state: mediaState, hit: hits)
        
        guard !url.isEmpty, !body.isEmpty else {
            Log.debug(label: LOG_TAG, "\(#function) - Could not generate downloaded content report from persisted hits for session (\(id)). Clearing persisted pings.")
            sessionState = .Invalid
            onSessionReportFailure()
            return
        }
        
        if let url = URL.init(string: url) {
            isReportingSession = true
            let networkService = ServiceProvider.shared.networkService
            let networkrequest = NetworkRequest(url: url, httpMethod: .post, connectPayload: body, httpHeaders: [String:String](), connectTimeout: MediaConstants.Networking.HTTP_TIMEOUT_SECONDS, readTimeout: MediaConstants.Networking.HTTP_TIMEOUT_SECONDS)
         
            networkService.connectAsync(networkRequest: networkrequest) { connection in
                self.dispatchQueue.async {
                    if connection.error == nil {
                        let statusCode = connection.response?.statusCode ?? -1
                        if !MediaConstants.Networking.HTTP_SUCCESS_RANGE.contains(statusCode) {
                            Log.debug(label: self.LOG_TAG, "\(#function) - Session (\(self.id)) reporting failed. HTTP request failed with response code (\(statusCode))")
                            self.sessionState = .Failed
                        } else {
                            self.sessionState = .Reported
                            Log.trace(label: self.LOG_TAG, "\(#function) - Session (\(self.id) Successfully reported.")
                        }
                    } else if let error = connection.error as? URLError, error.code == URLError.Code.notConnectedToInternet {
                        self.sessionState = .Failed
                        self.onSessionReportFailure()
                        //TODO: Do we need to handle no internet connection in some other way?
                    } else {
                        self.sessionState = .Failed
                        self.onSessionReportFailure()
                    }
                }
            }
        } else {
            Log.debug(label: LOG_TAG, "\(#function) - Failed to report session (\(id). Unable to get URL.")
            sessionState = .Invalid
            onSessionReportFailure()
        }
    }
    
    private func onSessionReportSuccess() {
        isReportingSession = false
        if shouldClearSession() {
            Log.trace(label: LOG_TAG, "\(#function) - Clearing persisted pings for Session (\(self.id)).")
            mediaDBService.deleteHits(sessionId: id)
            sessionEndHandler?()
        }
    }
    
    private func onSessionReportFailure() {
        isReportingSession = false
        if shouldClearSession() {
            Log.trace(label: LOG_TAG, "\(#function) - Clearing persisted pings for Session (\(self.id)).")
            mediaDBService.deleteHits(sessionId: id)
            sessionEndHandler?()
        } else {
            failureCount += 1
            dispatchQueue.asyncAfter(deadline: .now() + .seconds(MediaSession.DURATION_BETWEEN_HITS_ON_FAILURE)) {
                self.reportSession()
            }
        }
    }
    
    private func shouldClearSession() -> Bool {
        
        if (sessionState == .Reported || sessionState == .Invalid) {
            return true
        }
        
        if (sessionState == .Failed) {
            return failureCount >= MAX_ALLOWED_FAILURE
        }
        
        return false
    }
}
