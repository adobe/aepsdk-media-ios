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

class MediaRealTimeSession: MediaSession {

    private static let LOG_TAG = MediaConstants.LOG_TAG
    private static let CLASS_NAME = "MediaRealTimeSession"

    private static let DURATION_BETWEEN_HITS_ON_FAILURE = 60 // Retry duration in case of failure
    private static let MAX_ALLOWED_DURATION_BETWEEN_HITS_MS: Int64 = 60  * 1000 // 60 sec
    private static let MAX_ALLOWED_FAILURE = 3 //The maximum number of times SDK retries to send hit on failure, after that drop the hit.

    #if DEBUG
        var hits: [MediaHit] = []
        var retryDuration = 1
    #else
        private var hits: [MediaHit] = []
        private var retryDuration = DURATION_BETWEEN_HITS_ON_FAILURE
    #endif

    private var mcSessionId: String?
    private var isSendingHit: Bool = false
    private var lastHitTS: Int64 = 0
    // this will be used when we have failed to send the request so starting at 1
    private var sessionStartRetryCount = 1

    override func handleQueueMediaHit(hit: MediaHit) {
        Log.trace(label: Self.LOG_TAG, "[\(Self.CLASS_NAME)<\(#function)>] - [Session (\(id))] Queuing hit with event type (\(hit.eventType))")
        hits.append(hit)
        trySendHit()
    }

    override func handleSessionEnd() {
        Log.trace(label: Self.LOG_TAG, "[\(Self.CLASS_NAME)<\(#function)>] - [Session (\(id))] End")
        trySendHit()
    }

    override func handleSessionAbort() {
        Log.trace(label: Self.LOG_TAG, "[\(Self.CLASS_NAME)<\(#function)>] - [Session (\(id))] Abort")
        hits.removeAll()
        sessionEndHandler?()
    }

    override func handleMediaStateUpdate() {
        Log.trace(label: Self.LOG_TAG, "[\(Self.CLASS_NAME)<\(#function)>] - [Session (\(id))] Handling media state update")
        trySendHit()
    }

    ///Sends the first `MediaHit` from the collected hits to Media Collection Server
    private func trySendHit() {
        guard state.privacyStatus == .optedIn else {
            Log.debug(label: Self.LOG_TAG, "[\(Self.CLASS_NAME)<\(#function)>] - [Session (\(id)] Exiting as privacy is not opted-in")
            return
        }

        guard MediaCollectionReportHelper.hasAllTrackingParams(state: state) else {
            Log.debug(label: Self.LOG_TAG, "[\(Self.CLASS_NAME)<\(#function)>] - [Session (\(id)] Exiting as media state does not have required params")
            return
        }

        guard !isSendingHit else {
            Log.trace(label: Self.LOG_TAG, "[\(Self.CLASS_NAME)<\(#function)>] - [Session (\(id)] Exiting as it is currently sending a hit")
            return
        }

        guard !hits.isEmpty, let hit = hits.first else {
            Log.trace(label: Self.LOG_TAG, "[\(Self.CLASS_NAME)<\(#function)>] - [Session (\(id)] Exiting as there is no queued hits")
            return
        }

        let eventType = hit.eventType
        let isSessionStartHit = (eventType == MediaConstants.MediaCollection.EventType.SESSION_START)

        if !isSessionStartHit && (mcSessionId ?? "").isEmpty {
            Log.trace(label: Self.LOG_TAG, "[\(Self.CLASS_NAME)<\(#function)>] -  [Session (\(id)] Dropping hit (\(eventType)), media collection session id is unavailable.")
            sendNextHit()
            return
        }

        logHitDelay(hit: hit)

        guard let url = generateHitUrl(isSessionStartHit) else {
            Log.debug(label: Self.LOG_TAG, "[\(Self.CLASS_NAME)<\(#function)>] -  [Session (\(id)] Dropping hit (\(eventType)), unable to create url")
            sendNextHit()
            return
        }
        guard let body = MediaCollectionReportHelper.generateHitReport(state: state, hit: hit), !body.isEmpty else {
            Log.debug(label: Self.LOG_TAG, "[\(Self.CLASS_NAME)<\(#function)>] -  [Session (\(id)] Dropping hit (\(eventType)), unable to generate hit body")
            sendNextHit()
            return
        }

        isSendingHit = true

        Log.trace(label: Self.LOG_TAG, "[\(Self.CLASS_NAME)<\(#function)>] -  [Session (\(id)] Send hit (\(eventType)) with body \(body)")
        let networkRequest = NetworkRequest(url: url, httpMethod: .post, connectPayload: body, httpHeaders: MediaConstants.Networking.REQUEST_HEADERS, connectTimeout: MediaConstants.Networking.HTTP_TIMEOUT_SECONDS, readTimeout: MediaConstants.Networking.HTTP_TIMEOUT_SECONDS)
        ServiceProvider.shared.networkService.connectAsync(networkRequest: networkRequest) {[weak self] connection in
            self?.dispatchQueue.async {
                guard let self = self else {return}

                self.isSendingHit = false

                let responseCode = connection.responseCode ?? -1
                guard MediaConstants.Networking.HTTP_SUCCESS_RANGE.contains(responseCode) else {
                    Log.debug(label: Self.LOG_TAG, "[\(Self.CLASS_NAME)<\(#function)>] - [Session (\(self.id)] \(eventType) Http failed with response code \(responseCode)")
                    self.handleProcessingError(sessionStart: isSessionStartHit)
                    return
                }

                if isSessionStartHit {
                    guard let mcSessionId = self.extractSessionId(connection: connection) else {
                        self.handleProcessingError(sessionStart: isSessionStartHit)
                        return
                    }
                    Log.trace(label: Self.LOG_TAG, "[\(Self.CLASS_NAME)<\(#function)>] - [Session (\(self.id) Created Mediacollection session \(mcSessionId)")
                    self.mcSessionId = mcSessionId
                }

                self.handleProcessingSuccess()
            }
        }
    }

    private func extractSessionId(connection: HttpConnection) -> String? {
        guard let sessionResponseFragment = connection.responseHttpHeader(forKey: "Location") else {
            return nil
        }

        return MediaCollectionReportHelper.extractSessionID(sessionResponseFragment: sessionResponseFragment)
    }

    private func generateHitUrl(_ isSessionStartHit: Bool) -> URL? {
        var url: URL?
        if isSessionStartHit {
            url = MediaCollectionReportHelper.getTrackingURL(host: state.mediaCollectionServer ?? "")
        } else {
            url = MediaCollectionReportHelper.getTrackingURLForEvents(host: state.mediaCollectionServer ?? "", sessionId: mcSessionId)
        }
        return url
    }

    ///Handles if hit is successfully send to the Media Collection Server
    private func handleProcessingSuccess() {
        sendNextHit()
    }

    ///Handles if there is an error in sending hit to the Media Collection Server
    private func handleProcessingError(sessionStart: Bool) {
        if !sessionStart || sessionStartRetryCount >= MediaRealTimeSession.MAX_ALLOWED_FAILURE {
            sendNextHit()
            return
        }

        if sessionStartRetryCount < MediaRealTimeSession.MAX_ALLOWED_FAILURE {
            sessionStartRetryCount += 1
            dispatchQueue.asyncAfter(deadline: .now() + .seconds(retryDuration)) { [weak self] in
                self?.trySendHit()
            }
        }
    }

    ///Initiates sending the next hit after a hit is successfully send OR error occurred in sending the hit, greater than or equals to MAX_ALLOWED_FAILURE times. It also handles the condition if there is not pending hit and session has been ended.
    private func sendNextHit() {
        if !hits.isEmpty {
            hits.removeFirst()
        }

        if hits.isEmpty && !isSessionActive {
            sessionEndHandler?()
            return
        }

        trySendHit()
    }

    private func logHitDelay(hit: MediaHit) {
        if hit.eventType == MediaConstants.MediaCollection.EventType.SESSION_START {
            lastHitTS = hit.timestamp
        }

        let currHitTS = hit.timestamp
        let diff = currHitTS - lastHitTS
        if diff >= MediaRealTimeSession.MAX_ALLOWED_DURATION_BETWEEN_HITS_MS {
            Log.warning(label: Self.LOG_TAG, "trySendHit - (\(hit.eventType)) TS difference from previous hit is \(diff) greater than 60 seconds.")
        }
        lastHitTS = currHitTS
    }
}
