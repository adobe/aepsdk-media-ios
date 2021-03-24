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

class MediaRealTimeSession : MediaSession {
    
    private let LOG_TAG = "MediaRealTimeSession"
    private static let MAX_ALLOWED_DURATION_BETWEEN_HITS: TimeInterval = 60
    private static let MAX_ALLOWED_FAILURE = 2 //The maximun number of times SDK retries to send hit on failure, after that drop the hit.
    
    #if DEBUG
        var hits: [MediaHit] = []
    #else
        private var hits: [MediaHit] = []
    #endif
    private var sessionId: String?    
    private var isSendingHit: Bool?
    private var sessionStartRetryCount: Int?
    private var lastRefTS: TimeInterval = 0
    private var sessionRetryCount = 0
    
    override func handleQueueMediaHit(hit: MediaHit) {
        hits.append(hit)
        trySendHit()
    }
    
    override func handleSessionEnd() {
        isSessionActive = false
        sessionEndHandler?()
    }
    
    override func handleSessionAbort() {
        isSessionActive = false
        hits.removeAll()
    }
    
    ///Sends the first `MediaHit` from the collected hits to Media Collection Server
    private func trySendHit() {
        guard !hits.isEmpty else {
            Log.trace(label: LOG_TAG, "\(#function) - MediaHit collection is empty")
            return
        }
        
        guard !(isSendingHit ?? false) else {
            Log.trace(label: LOG_TAG, "\(#function) - Returning early. Already sending a Media hit")
            return
        }
        
        guard let hit = hits.first else {
            Log.debug(label: LOG_TAG, "Returning early, first MediaHit is nil")
            return
        }
        let eventType = hit.eventType
        
        let isSessionStartHit = eventType == MediaConstants.EventName.SESSION_START
        if !isSessionStartHit && sessionId?.isEmpty ?? true {
            Log.trace(label: LOG_TAG, "\(#function) - Dropping event (\(eventType)) as session id is unavailable.")
            hits.removeFirst()
            return
        }
        
        if (isSessionStartHit) {
            lastRefTS = hit.timestamp
        }
        
        // We currently just log the error and don't do any error correction.
        // This should never happen. Might happen in some devices if app goes to sleep and timer stops ticking.
        let currRefTs = hit.timestamp
        let diff = currRefTs - lastRefTS
        
        if diff >= MediaRealTimeSession.MAX_ALLOWED_DURATION_BETWEEN_HITS {
            Log.warning(label: LOG_TAG, "trySendHit - (\(eventType)) TS difference from previous hit is \(diff) greater than 60 seconds.")
        }
        
        lastRefTS = currRefTs
        
        let (urlString, body) = generateHitUrlAndBody(isSessionStartHit, hit)
        isSendingHit = true
                
        if let url = URL.init(string: urlString) {
            let networkService = ServiceProvider.shared.networkService
            let networkrequest = NetworkRequest(url: url, httpMethod: .post, connectPayload: body, httpHeaders: MediaConstants.Networking.HIT_HEADERS, connectTimeout: MediaConstants.Networking.HTTP_TIMEOUT_SECONDS, readTimeout: MediaConstants.Networking.HTTP_TIMEOUT_SECONDS)
            networkService.connectAsync(networkRequest: networkrequest) { connection in
                self.dispatchQueue.async {
                    if connection.error == nil {
                        let statusCode = connection.response?.statusCode ?? MediaConstants.Networking.INVALID_RESPONSE
                        if !MediaConstants.Networking.HTTP_SUCCESS_RANGE.contains(statusCode) {
                            Log.debug(label: self.LOG_TAG, "\(#function) - \(eventType) Http failed with response code (\(statusCode))")
                            self.handleProcessingError()
                        } else {
                            if isSessionStartHit {
                                if let sessionResponseFragment = connection.responseHttpHeader(forKey: "Location"), !sessionResponseFragment.isEmpty {
                                    let mcSessionId = MediaCollectionReportHelper.extractSessionID(sessionResponseFragment: sessionResponseFragment)
                                    Log.trace(label: self.LOG_TAG, "\(#function) - \(eventType): Media collection endpoint created internal session with id (\(String(describing: mcSessionId)))")
                                
                                    if let mcSessionId = mcSessionId, mcSessionId.count > 0 {
                                        self.sessionId = mcSessionId
                                        self.handleProcessingSuccess()
                                    } else {
                                        self.handleProcessingError()
                                    }
                                }
                            } else {
                                self.handleProcessingSuccess()
                            }
                        }
                    } else {
                        self.handleProcessingError()
                    }
                }
            }
        }}
    
    ///Returns the Media Collection hit URL and Body
    private func generateHitUrlAndBody(_ isSessionStartHit: Bool, _ hit: MediaHit) -> (String, String) {
        var urlString = ""
        if isSessionStartHit {
            urlString = MediaCollectionReportHelper.getTrackingURL(url: mediaState.getMediaCollectionServer())
        } else {
            urlString = MediaCollectionReportHelper.getTrackingURLForEvents(url: mediaState.getMediaCollectionServer(), sessionId: sessionId)
        }
        
        let body = MediaCollectionReportHelper.generateHitReport(state: mediaState, hit: [hit])
        Log.debug(label: LOG_TAG, "trySendHit - Generated url (\(urlString)), Generated body (\(body))")
        return (urlString, body)
    }
    
    ///Handles if hit is successfully send to the Media Collection Server
    private func handleProcessingSuccess() {
        sessionRetryCount = 0
        hits.removeFirst()
        isSendingHit = false
        if hits.count > 0 {
            trySendHit()
        }
    }
    
    ///Handles if there is an error in sending hit to the Media Collection Server
    private func handleProcessingError() {
        if sessionRetryCount >= MediaRealTimeSession.MAX_ALLOWED_FAILURE {
            hits.removeFirst()
            sessionRetryCount = 0
        } else {
            sessionRetryCount += 1
        }
        isSendingHit = false
        if hits.count > 0 {
            trySendHit()
        }
    }
}
