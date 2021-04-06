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
    private var lastRefTS: TimeInterval = 0
    private var sessionRetryCount = 0

    override func handleQueueMediaHit(hit: MediaHit) {
        Log.trace(label: LOG_TAG, "\(#function) - Queuing hit for Session (\(id)) with event type (\(hit.eventType))")
        hits.append(hit)
        trySendHit()
    }

    override func handleSessionEnd() {
        Log.trace(label: LOG_TAG, "\(#function) - Ending Session (\(id))")
        trySendHit()
    }

    override func handleSessionAbort() {
        Log.trace(label: LOG_TAG, "\(#function) - Aborting Session (\(id))")
        hits.removeAll()
        sessionEndHandler?()
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

        if isSessionStartHit {
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
        guard !urlString.isEmpty && !body.isEmpty else {
            Log.debug(label: LOG_TAG, "\(#function) - Failed to report Event (\(eventType). Unable to create url or event report.")
            hits.removeFirst()
            return
        }

        guard let url = URL.init(string: urlString) else {
            Log.debug(label: LOG_TAG, "\(#function) - Failed to report Event (\(eventType). Unable to create URL.")
            hits.removeFirst()
            return
        }

        isSendingHit = true

        let networkService = ServiceProvider.shared.networkService
        let networkrequest = NetworkRequest(url: url, httpMethod: .post, connectPayload: body, httpHeaders: MediaConstants.Networking.REQUEST_HEADERS, connectTimeout: MediaConstants.Networking.HTTP_TIMEOUT_SECONDS, readTimeout: MediaConstants.Networking.HTTP_TIMEOUT_SECONDS)
        networkService.connectAsync(networkRequest: networkrequest) {[weak self] connection in
            self?.dispatchQueue.async {

                guard connection.error == nil, let responseCode = connection.response?.statusCode, MediaConstants.Networking.HTTP_SUCCESS_RANGE.contains(responseCode) else {
                    Log.debug(label: self?.LOG_TAG ?? "", "\(#function) - \(eventType) Http failed with response code (\(connection.response?.statusCode ?? MediaConstants.Networking.INVALID_RESPONSE))")
                    self?.handleProcessingError()
                    return
                }

                if isSessionStartHit {
                    if let sessionResponseFragment = connection.responseHttpHeader(forKey: "Location"), !sessionResponseFragment.isEmpty {
                        let mcSessionId = MediaCollectionReportHelper.extractSessionID(sessionResponseFragment: sessionResponseFragment)
                        Log.trace(label: self?.LOG_TAG ?? "", "\(#function) - \(eventType): Media collection endpoint created internal session with id (\(String(describing: mcSessionId)))")

                        if let mcSessionId = mcSessionId, mcSessionId.count > 0 {
                            self?.sessionId = mcSessionId
                            self?.handleProcessingSuccess()
                            return
                        }
                    }
                    self?.handleProcessingError()
                    return
                }
                self?.handleProcessingSuccess()
            }
        }
    }

    ///Returns the Media Collection hit URL and Body
    private func generateHitUrlAndBody(_ isSessionStartHit: Bool, _ hit: MediaHit) -> (String, String) {
        var urlString = ""
        if isSessionStartHit {
            urlString = MediaCollectionReportHelper.getTrackingURL(host: state.getMediaCollectionServer())
        } else {
            urlString = MediaCollectionReportHelper.getTrackingURLForEvents(host: state.getMediaCollectionServer(), sessionId: sessionId)
        }

        let body = MediaCollectionReportHelper.generateHitReport(state: state, hit: [hit]) ?? ""
        Log.debug(label: LOG_TAG, "trySendHit - Generated url (\(urlString)), Generated body (\(body))")
        return (urlString, body)
    }

    ///Handles if hit is successfully send to the Media Collection Server
    private func handleProcessingSuccess() {
        isSendingHit = false
        sendNextHit()
    }

    ///Handles if there is an error in sending hit to the Media Collection Server
    private func handleProcessingError() {
        isSendingHit = false
        if sessionRetryCount >= MediaRealTimeSession.MAX_ALLOWED_FAILURE {
            sendNextHit()
        } else {
            sessionRetryCount += 1
            dispatchQueue.asyncAfter(deadline: .now() + .seconds(MediaSession.DURATION_BETWEEN_HITS_ON_FAILURE)) {
                self.trySendHit()
            }
        }
    }

    ///Initiates sending the next hit after a hit is successfully send OR error occurred in sending the hit, greater than or equals to MAX_ALLOWED_FAILURE times. It also handles the condition if there is not pending hit and session has been ended.
    private func sendNextHit() {
        hits.removeFirst()
        sessionRetryCount = 0
        if hits.count > 0 {
            trySendHit()
            return
        }
        if !isSessionActive { //Session is ended
            sessionEndHandler?()
        }
    }
}
