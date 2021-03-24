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
            
    private let LOG_TAG = "MediaOfflineSession"
    private static let MAX_ALLOWED_FAILURE = 2 //The maximun number of times SDK retries to send hit on failure, after that drop the hit.
    private var mediaDBService: MediaDBService
    private var isReportingSession: Bool
    private var failureCount = 0
    
    ///Initializer for `MediaSession`
    ///- Parameters:
    ///    - id: Unique `MediaSession id`
    ///    - state: `MediaState` object
    ///    - dispatchQueue: `DispatchQueue` used for handling response after processing `MediaHit`
    ///    - dispatchQueue: `DispatchQueue` used for handling response after processing `MediaHit`
    ///    - mediaDBService: `MediaDBService` object used for persisting hits in the database
    init(id: String, state: MediaState, dispatchQueue: DispatchQueue, mediaDBService: MediaDBService) {
        self.mediaDBService = mediaDBService
        isReportingSession = false
        super.init(id: id, mediaState: state, dispatchQueue: dispatchQueue)
    }
    
    override func handleQueueMediaHit(hit: MediaHit) {
        mediaDBService.persistHit(hit: hit, sessionId: id)
        Log.debug(label: LOG_TAG, "\(#function) - Persisting hit for session (\(id)) with event type (\(hit.eventType))")
    }
    
    override func handleSessionEnd() {
        reportSession()
        isSessionActive = false
        Log.debug(label: LOG_TAG, "\(#function) - Session (\(id)) is ended")
    }
    
    override func handleSessionAbort() {
        mediaDBService.deleteHits(sessionId: id)
        isSessionActive = false
        Log.trace(label: LOG_TAG, "\(#function) - Session (\(id)) is aborted.")
        sessionEndHandler?()
    }
        
    ///Create media collection report for session and send to Media Collection Server.
    private func reportSession() {
        guard !isReportingSession else {
            Log.debug(label: LOG_TAG, "\(#function) - Exiting as we are currently sending session report (\(id)")
            return
        }
        
        guard isReadyToSendHit() else {
            Log.debug(label: LOG_TAG, "\(#function) - Exiting as session (\(id) is not ready for sending hits")
            return
        }
        
        let hits = mediaDBService.getHits(sessionId: id)
        guard !hits.isEmpty else {
            Log.debug(label: LOG_TAG, "\(#function) - Unable to report session (\(id)), No persisted hits found")
            handleInvalidSession()
            return
        }
        
        let url = MediaCollectionReportHelper.getTrackingURL(url: mediaState.getMediaCollectionServer())
        let body = MediaCollectionReportHelper.generateHitReport(state: mediaState, hit: hits)
        
        guard !url.isEmpty, !body.isEmpty else {
            Log.debug(label: LOG_TAG, "\(#function) - Could not generate downloaded content report from persisted hits for session (\(id)), Clearing persisted pings")
            handleInvalidSession()
            return
        }
        
        isReportingSession = true
        if let url = URL.init(string: url) {
            let networkService = ServiceProvider.shared.networkService
            let networkrequest = NetworkRequest(url: url, httpMethod: .post, connectPayload: body, httpHeaders: MediaConstants.Networking.HIT_HEADERS, connectTimeout: MediaConstants.Networking.HTTP_TIMEOUT_SECONDS, readTimeout: MediaConstants.Networking.HTTP_TIMEOUT_SECONDS)
                     
            networkService.connectAsync(networkRequest: networkrequest) { connection in
                self.dispatchQueue.async {
                    if connection.error == nil {
                        let statusCode = connection.response?.statusCode ?? MediaConstants.Networking.INVALID_RESPONSE
                        if !MediaConstants.Networking.HTTP_SUCCESS_RANGE.contains(statusCode) {
                            Log.debug(label: self.LOG_TAG, "\(#function) - Session (\(self.id)) reporting failed. HTTP request failed with response code (\(statusCode))")
                            self.onSessionReportFailure()
                        } else {
                            Log.trace(label: self.LOG_TAG, "\(#function) - Session (\(self.id) successfully reported")
                            self.onSessionReportSuccess()
                        }
                    } else if let error = connection.error as? URLError, error.code == URLError.Code.notConnectedToInternet {
                        self.onSessionReportFailure()   //Reporting error due to no internet connection
                    } else {
                        self.onSessionReportFailure()
                    }
                }
            }
        } else {
            Log.debug(label: LOG_TAG, "\(#function) - Failed to report session (\(id)). Unable to create URL.")
            handleInvalidSession()
        }
    }
    
    ///Clears the persisted session hits after session is successfully reported to Media collection server.
    private func onSessionReportSuccess() {
        Log.trace(label: LOG_TAG, "\(#function) - Clearing persisted pings for Session (\(self.id))")
        isReportingSession = false
        clearSession()
    }
    
    ///Handles the response when session reporting is failed
    private func onSessionReportFailure() {
        isReportingSession = false
        if failureCount >= MediaOfflineSession.MAX_ALLOWED_FAILURE {
            Log.trace(label: LOG_TAG, "\(#function) - Clearing persisted pings for Session (\(self.id)).")
            clearSession()
        } else {
            failureCount += 1
            dispatchQueue.asyncAfter(deadline: .now() + .seconds(MediaSession.DURATION_BETWEEN_HITS_ON_FAILURE)) {
                self.reportSession()
            }
        }
    }
    
    ///Handles if the session is invalid for ex: session reporting url is invalid
    private func handleInvalidSession() {
        Log.trace(label: LOG_TAG, "\(#function) - Clearing persisted pings for Session (\(self.id)).")
        isReportingSession = false
        clearSession()
    }
    
    private func clearSession() {
        mediaDBService.deleteHits(sessionId: id)
        sessionEndHandler?()
    }
}
