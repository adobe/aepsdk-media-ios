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

class MediaRealTimeSession : MediaSession, MediaSessionEventsHandler {
    
    private let LOG_TAG = "MediaRealTimeSession"
    private static let MAX_RETRY_COUNT = 2
    private static let MAX_ALLOWED_DURATION_BETWEEN_HITS: TimeInterval = 60
    
    private var hits: [MediaHit] = []
    private var sessionId: String?    
    private var isSendingHit: Bool?
    private var sessionStartRetryCount: Int?
    private var lastRefTS: TimeInterval = 0
    private var sessionRetryCount = 0
        
    
    init(id: String, state: MediaState) {
        super.init(id: id, mediaState: state)
        eventsHandler = self
    }
    
    func queue(hit: MediaHit) {
        
        hits.append(hit)
    }
            
    func processSession() {
        
        trySendHit()
    }
    
    func endSession() {
        
        isSessionActive = false
    }
    
    func abortSession() {
        
        isSessionActive = false
        hits.removeAll()
    }
    
    func finishedProcessing() -> Bool {
        return !isSessionActive && !(isSendingHit ?? false) && hits.isEmpty
    }
    
    private func trySendHit() {
        guard !hits.isEmpty else {
            Log.trace(label: LOG_TAG, "\(#function) - MediaHit collection is empty.")
            return
        }
        
        guard !(isSendingHit ?? false) else {
            Log.trace(label: LOG_TAG, "\(#function) - Returning early. Already sending a Media hit.")
            return
        }
        
        guard let hit = hits.first else {
            Log.debug(label: LOG_TAG, "Returning early, first MediaHit is nil.")
            return
        }
        let eventType = hit.eventType
        
        let isSessionStartHit = hit.eventType == MediaConstants.EventName.SESSION_START
        if !isSessionStartHit && sessionId?.isEmpty ?? true {
            Log.trace(label: LOG_TAG, "\(#function) - \(eventType) Dropping as session id is unavailable.")
            hits.removeFirst()
            return
        }
        
        if (isSessionStartHit) {
            lastRefTS = hit.ts
        }
        
        // We currently just lof the error and don't do any error correction.
        // This should never happen. Might happen in some devices if app goes to sleep and timer stops ticking.
        let currRefTs = hit.ts
        let diff = currRefTs - lastRefTS;
        
        if (diff >= MediaRealTimeSession.MAX_ALLOWED_DURATION_BETWEEN_HITS) {
            Log.warning(label: LOG_TAG, "trySendHit - \(eventType) TS difference from previous hit is \(diff) greater than 60 seconds.")
        }
        
        lastRefTS = currRefTs;
        
        var urlString = "";
        
        if isSessionStartHit {
            urlString = MediaCollectionReportHelper.getTrackingURL(url: mediaState.getMediaCollectionServer())
        } else {
            urlString = MediaCollectionReportHelper.getTrackingURLForEvents(url: mediaState.getMediaCollectionServer(), sessionId: sessionId)
        }
        
        let body = MediaCollectionReportHelper.generateHitReport(state: mediaState, hit: [hit])
        Log.debug(label: LOG_TAG, "trySendHit - \(eventType) Generated url \(urlString), Generated body \(body)")
        isSendingHit = true;
                
        if let url = URL.init(string: urlString){
            let networkService = ServiceProvider.shared.networkService
            let networkrequest = NetworkRequest(url: url, httpMethod: .post, connectPayload: body, httpHeaders: [String:String](), connectTimeout: MediaConstants.Networking.HTTP_TIMEOUT_SECONDS, readTimeout: MediaConstants.Networking.HTTP_TIMEOUT_SECONDS)
            networkService.connectAsync(networkRequest: networkrequest) { connection in
                if connection.error == nil {
                    let statusCode = connection.response?.statusCode ?? -1
                    if MediaConstants.Networking.HTTP_SUCCESS_RANGE.contains(statusCode) {
                        Log.debug(label: self.LOG_TAG, "\(#function) - \(eventType) Http failed with response code (\(statusCode))")
                    } else {
                        if isSessionStartHit {
                            if let sessionReponseFragment = connection.responseHttpHeader(forKey: "Location"), !sessionReponseFragment.isEmpty {
                                let mcSessionId = MediaCollectionReportHelper.extractSessionID(sessionResponseFragment: sessionReponseFragment)
                                Log.trace(label: self.LOG_TAG, "\(#function) - \(eventType) Media collection endpoint created internal session with id \(String(describing: mcSessionId))")
                                
                                var shouldRetry = false
                                
                                if isSessionStartHit, let mcSessionId = mcSessionId, mcSessionId.count > 0 {
                                    self.sessionId = mcSessionId;
                                } else if (isSessionStartHit) {
                                    shouldRetry = self.sessionRetryCount < MediaRealTimeSession.MAX_RETRY_COUNT
                                    self.sessionRetryCount += 1
                                }
                                
                                self.isSendingHit = false
                                
                                if (!shouldRetry) {
                                    self.hits.removeFirst()
                                }
                            }
                        } else {
                            Log.trace(label: self.LOG_TAG, "\(#function) \(eventType) Media collection endpoint returns nil location header.")
                        }
                        
                    }
                } else if let error = connection.error as? URLError, error.code == URLError.Code.notConnectedToInternet {
                    //TODO handle no internet connection here.
                } else {
                    //TODO handle all other errors here.
                }
            }
        }
    }
}
