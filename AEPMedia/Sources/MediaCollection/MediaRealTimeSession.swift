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
import AEPServices

class MediaRealTimeSession: MediaSession {

    private static let LOG_TAG = MediaConstants.LOG_TAG
    private static let CLASS_NAME = "MediaRealTimeSession"

    private static let DURATION_BETWEEN_HITS_ON_FAILURE = 60 // Retry duration in case of failure
    private static let MAX_ALLOWED_DURATION_BETWEEN_HITS_MS: Int64 = 60  * 1000 // 60 sec
    private static let MAX_ALLOWED_FAILURE = 3 // The maximum number of times SDK retries to send hit on failure, after that drop the hit.

    #if DEBUG
        var hits: [MediaHit] = []
    #else
        private var hits: [MediaHit] = []
    #endif

    private var mcSessionId: String?
    private var isSendingHit: Bool = false
    private var lastHitTS: Int64 = 0
    // this will be used when we have failed to send the request so starting at 1
    private var sessionStartRetryCount = 1
    var retryDuration = DURATION_BETWEEN_HITS_ON_FAILURE

    override func handleQueueMediaHit(hit: MediaHit) {
        if !isSessionActive {
            return
        }

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

    /// Sends the first `MediaHit` from the collected hits to Media Collection Server
    // swiftlint:disable function_body_length
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
        let debugInfo = MediaCollectionReportHelper.extractDebugInfo(hit: hit)

        isSendingHit = true

        Log.trace(label: Self.LOG_TAG, "[\(Self.CLASS_NAME)<\(#function)>] -  [Session (\(id)] Send hit (\(eventType)) with body \(body)")

        var httpHeaders = MediaConstants.Networking.REQUEST_HEADERS
        if let assuranceIntegrationId = state.assuranceIntegrationId {
            httpHeaders[MediaConstants.Networking.HEADER_KEY_AEP_VALIDATION_TOKEN] = assuranceIntegrationId
        }

        let networkRequest = NetworkRequest(url: url,
                                            httpMethod: .post,
                                            connectPayload: body,
                                            httpHeaders: httpHeaders,
                                            connectTimeout: MediaConstants.Networking.HTTP_TIMEOUT_SECONDS,
                                            readTimeout: MediaConstants.Networking.HTTP_TIMEOUT_SECONDS)

        ServiceProvider.shared.networkService.connectAsync(networkRequest: networkRequest) {[weak self] connection in
            self?.dispatchQueue.async {
                guard let self = self else {return}

                self.isSendingHit = false

                let responseCode = connection.responseCode ?? -1
                guard MediaConstants.Networking.HTTP_SUCCESS_RANGE.contains(responseCode) else {
                    self.handleProcessingError(eventType: eventType, connection: connection)
                    return
                }

                if isSessionStartHit {
                    guard let mcSessionId = self.extractSessionId(connection: connection) else {
                        Log.trace(label: Self.LOG_TAG, "[\(Self.CLASS_NAME)<\(#function)>] - [Session(\(self.id))] Something went wrong, could not get sessionId from server response.")

                        self.handleProcessingError(eventType: eventType)
                        return
                    }
                    Log.trace(label: Self.LOG_TAG, "[\(Self.CLASS_NAME)<\(#function)>] - [Session(\(self.id))] Created Mediacollection session \(mcSessionId)")
                    self.mcSessionId = mcSessionId

                    var eventData = debugInfo
                    eventData[MediaConstants.Tracker.BACKEND_SESSION_ID] = mcSessionId
                    self.dispathFn?(eventData)
                }

                self.handleProcessingSuccess()
            }
        }
    }
    // swiftlint:enable function_body_length

    private func extractSessionId(connection: HttpConnection) -> String? {
        guard let sessionResponseFragment = connection.responseHttpHeader(forKey: "Location") else {
            return nil
        }

        return MediaCollectionReportHelper.extractSessionID(sessionResponseFragment: sessionResponseFragment)
    }

    private func generateHitUrl(_ isSessionStartHit: Bool) -> URL? {
        var url: URL?
        if isSessionStartHit {
            url = MediaCollectionReportHelper.getTrackingURL(trackingServer: state.mediaCollectionServer ?? "")
        } else {
            url = MediaCollectionReportHelper.getTrackingURLForEvents(trackingServer: state.mediaCollectionServer ?? "", sessionId: mcSessionId)
        }
        return url
    }

    /// Handles if hit is successfully send to the Media Collection Server
    private func handleProcessingSuccess() {
        sendNextHit()
    }

    /// Handles if there is an error in sending hit to the Media Collection Server
    private func handleProcessingError(eventType: String, connection: HttpConnection? = nil) {
        if !shouldRetry(eventType: eventType, connection: connection) {
            sendNextHit()
            return
        }

        sessionStartRetryCount += 1
        dispatchQueue.asyncAfter(deadline: .now() + .seconds(retryDuration)) { [weak self] in
            self?.trySendHit()
        }
    }

    private func shouldRetry(eventType: String, connection: HttpConnection?) -> Bool {
        guard eventType == MediaConstants.MediaCollection.EventType.SESSION_START else {
            Log.trace(label: Self.LOG_TAG, "[\(Self.CLASS_NAME)<\(#function)>] - [Session (\(self.id))] \(eventType) request resulted in error and since event type is not sessionStart it will be dropped.")
            return false
        }

        guard sessionStartRetryCount < MediaRealTimeSession.MAX_ALLOWED_FAILURE else {
            Log.trace(label: Self.LOG_TAG, "[\(Self.CLASS_NAME)<\(#function)>] - [Session (\(self.id))] \(eventType) request resulted in error but since it surpassed the retry limit:(\(MediaRealTimeSession.MAX_ALLOWED_FAILURE), the request will be dropped.")
            return false
        }

        guard let connection = connection else {
            // connection is never null
            // should reach here when no error (http, url) and L141 calls this method with null connection
            // retry for case when error occured while parsing sessionStart response for sessionId
            Log.trace(label: Self.LOG_TAG, "[\(Self.CLASS_NAME)<\(#function)>] - [Session (\(self.id))] Unable to extract sessionId from sessionStart request response, the request will be retried.")
            return true
        }

        if let urlError = connection.error as? URLError {

            if urlError.isRecoverable {
                Log.debug(label: Self.LOG_TAG, "[\(Self.CLASS_NAME)<\(#function)>] - [Session(\(self.id))] \(eventType) request failed with recoverable URL error:(\(urlError.localizedDescription)) code:(\(urlError.errorCode)). Request will be retried.")
                return true // retry for recoverable url errors
            } else {
                Log.debug(label: Self.LOG_TAG, "[\(Self.CLASS_NAME)<\(#function)>] - [Session(\(self.id))] \(eventType) request failed with unrecoverable URL error:(\(urlError.localizedDescription)) code:(\(urlError.errorCode)). Request will be dropped.")
                return false
            }
        }

        if let responseCode = connection.responseCode {

            if NetworkServiceConstants.RECOVERABLE_ERROR_CODES.contains(responseCode) {
                Log.debug(label: Self.LOG_TAG, "[\(Self.CLASS_NAME)<\(#function)>] - [Session(\(self.id))] \(eventType) request failed with recoverable HTTP error:(\(connection.responseMessage ?? "")) response code:(\(responseCode)). Request will be retried.")
                return true // retry for recoverable http errors
            } else {
                Log.debug(label: Self.LOG_TAG, "[\(Self.CLASS_NAME)<\(#function)>] - [Session(\(self.id))] \(eventType) request failed with unrecoverable HTTP error:(\(connection.responseMessage ?? "")) response code:(\(connection.responseCode ?? -1)). Request will be dropped.")
                return false
            }
        }

        // ideally this line should never be executed
        Log.trace(label: Self.LOG_TAG, "[\(Self.CLASS_NAME)<\(#function)>] - [Session (\(self.id))] Request failed with unknown error, the request will be dropped.")

        return false
    }

    /// Initiates sending the next hit after a hit is successfully send OR error occurred in sending the hit, greater than or equals to MAX_ALLOWED_FAILURE times. It also handles the condition if there is not pending hit and session has been ended.
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
