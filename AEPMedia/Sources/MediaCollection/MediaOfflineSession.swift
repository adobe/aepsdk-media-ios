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

class MediaOfflineSession: MediaSession {

    private static let LOG_TAG = MediaConstants.LOG_TAG
    private static let CLASS_NAME = "MediaOfflineSession"
    private static let MAX_ALLOWED_FAILURE = 3 //The maximun number of times SDK retries to send hit on failure, after that drop the hit.
    private static let DURATION_BETWEEN_HITS_ON_FAILURE = 60 // Retry duration in case of failure
    private let mediaDBService: MediaDBService
    private var isReportingSession = false
    private var failureCount = 0

    ///Initializer for `MediaOfflineSession`
    ///- Parameters:
    ///    - id: Unique `MediaSession id`
    ///    - state: `MediaState` object
    ///    - dispatchQueue: `DispatchQueue` used for handling response after processing `MediaHit`    
    ///    - mediaDBService: `MediaDBService` object used for persisting hits in the database
    init(id: String, state: MediaState, dispatchQueue: DispatchQueue, mediaDBService: MediaDBService) {
        self.mediaDBService = mediaDBService
        super.init(id: id, state: state, dispatchQueue: dispatchQueue)
    }

    override func handleQueueMediaHit(hit: MediaHit) {
        Log.trace(label: Self.LOG_TAG, "[\(Self.CLASS_NAME)<\(#function)>] - [Session (\(id))] Persisting hit of event type (\(hit.eventType))")
        mediaDBService.persistHit(hit: hit, sessionId: id)
    }

    override func handleSessionEnd() {
        Log.trace(label: Self.LOG_TAG, "[\(Self.CLASS_NAME)<\(#function)>] - [Session (\(id))] End")
        tryReportSession()
    }

    override func handleSessionAbort() {
        Log.trace(label: Self.LOG_TAG, "[\(Self.CLASS_NAME)<\(#function)>] - [Session (\(id))] Abort")
        clearSession()
    }

    override func handleMediaStateUpdate() {
        Log.trace(label: Self.LOG_TAG, "[\(Self.CLASS_NAME)<\(#function)>] - [Session (\(id))] Handling media state update")

        // Manually trigger sessionEnd if required shared states are updated after the session had ended.
        if !isSessionActive {
            tryReportSession()
        }
    }

    ///Create media collection report for session and send to Media Collection Server.
    private func tryReportSession() {
        guard state.privacyStatus == .optedIn else {
            Log.debug(label: Self.LOG_TAG, "[\(Self.CLASS_NAME)<\(#function)>] - [Session (\(id)] Exiting as privacy is not opted-in.")
            return
        }

        guard MediaCollectionReportHelper.hasAllTrackingParams(state: state) else {
            Log.debug(label: Self.LOG_TAG, "[\(Self.CLASS_NAME)<\(#function)>] - [Session (\(id)] Exiting as media state does not have required params.")
            return
        }

        guard !isReportingSession else {
            Log.debug(label: Self.LOG_TAG, "[\(Self.CLASS_NAME)<\(#function)>] - [Session (\(id))] Exiting as it is currently reporting a session.")
            return
        }

        guard let url = MediaCollectionReportHelper.getTrackingURL(host: state.mediaCollectionServer ?? "") else {
            Log.debug(label: Self.LOG_TAG, "[\(Self.CLASS_NAME)<\(#function)>] - [Session (\(id))] Exiting as it is not able to generate a valid URL.")
            return
        }

        let hits = mediaDBService.getHits(sessionId: id)
        guard !hits.isEmpty else {
            Log.debug(label: Self.LOG_TAG, "[\(Self.CLASS_NAME)<\(#function)>] - [Session (\(id))] Unable to report, No persisted hits found.")
            clearSession()
            return
        }

        guard let body = MediaCollectionReportHelper.generateDownloadReport(state: state, hits: hits) else {
            Log.debug(label: Self.LOG_TAG, "[\(Self.CLASS_NAME)<\(#function)>] - [Session (\(id))] Could not generate downloaded content report from persisted hits, Clearing persisted pings.")
            clearSession()
            return
        }

        isReportingSession = true

        let networkRequest = NetworkRequest(url: url, httpMethod: .post, connectPayload: body, httpHeaders: MediaConstants.Networking.REQUEST_HEADERS, connectTimeout: MediaConstants.Networking.HTTP_TIMEOUT_SECONDS, readTimeout: MediaConstants.Networking.HTTP_TIMEOUT_SECONDS)

        ServiceProvider.shared.networkService.connectAsync(networkRequest: networkRequest) {[weak self] connection in
            self?.dispatchQueue.async {
                guard let self = self else {return}

                self.isReportingSession = false

                if let error = connection.error {
                    Log.trace(label: Self.LOG_TAG, "[\(Self.CLASS_NAME)<\(#function)>] - [Session (\(self.id))] Network Request failed with error: (\(error.localizedDescription)).")
                    // Failed due to transport error, will retry.
                    self.onSessionReportFailure(true)
                    return
                }

                let statusCode = connection.responseCode ?? -1
                Log.trace(label: Self.LOG_TAG, "[\(Self.CLASS_NAME)<\(#function)>] - [Session (\(self.id))] Network Request completed with status code: (\(statusCode)).")

                if MediaConstants.Networking.HTTP_SUCCESS_RANGE.contains(statusCode) {
                    self.onSessionReportSuccess()
                } else {
                    self.onSessionReportFailure()
                }
            }
        }
    }

    ///Clears the persisted session hits after session is successfully reported to Media collection server.
    private func onSessionReportSuccess() {
        Log.trace(label: Self.LOG_TAG, "[\(Self.CLASS_NAME)<\(#function)>] - [Session (\(self.id))] - Successfully reported media session.")
        clearSession()
    }

    ///Handles the response when session reporting is failed
    private func onSessionReportFailure(_ deviceOffline: Bool = false) {
        if failureCount >= Self.MAX_ALLOWED_FAILURE {
            Log.trace(label: Self.LOG_TAG, "[\(Self.CLASS_NAME)<\(#function)>] - [Session (\(self.id))] Exceeded maximum allowed retry count, dropping the session.")
            clearSession()
            return
        }

        // Don't increase failure count if device is offline
        if !deviceOffline {
            failureCount += 1
        }

        Log.trace(label: Self.LOG_TAG, "[\(Self.CLASS_NAME)<\(#function)>] - [Session (\(self.id))] Will retry reporting media session after (\(Self.DURATION_BETWEEN_HITS_ON_FAILURE)) seconds.")
        dispatchQueue.asyncAfter(deadline: .now() + .seconds(Self.DURATION_BETWEEN_HITS_ON_FAILURE)) { [weak self] in
            self?.tryReportSession()
        }
    }

    ///Removes the persisted hits.
    private func clearSession() {
        Log.trace(label: Self.LOG_TAG, "[\(Self.CLASS_NAME)<\(#function)>] - [Session (\(self.id))] Clearing persisted hits for the media session.")
        mediaDBService.deleteHits(sessionId: id)
        sessionEndHandler?()
    }
}
