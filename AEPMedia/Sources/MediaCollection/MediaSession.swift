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

class MediaSession {

    private let LOG_TAG = "MediaSession"
    static let DURATION_BETWEEN_HITS_ON_FAILURE = 30  //Waiting time in seconds before sending hit again after failure.

    var id: String
    var state: MediaState
    var isSessionActive: Bool
    var dispatchQueue: DispatchQueue
    var sessionEndHandler: (() -> Void)?

    ///Initializer for `MediaSession`
    ///- Parameters:
    ///    - id: Unique `MediaSession id`
    ///    - mediaState: `MediaState` object
    ///    - dispatchQueue: `DispatchQueue` used for handling response after processing `MediaHit`
    init(id: String, state: MediaState, dispatchQueue: DispatchQueue) {
        self.id = id
        self.state = state
        isSessionActive = true
        self.dispatchQueue = dispatchQueue
    }

    ///Returns true if SDk is ready to send hits else return false.
    func isReadyToSendHit() -> Bool {

        guard state.privacyStatus == .optedIn else {
            Log.debug(label: LOG_TAG, "\(#function) Unable to send MediaHit, privacy status is not optedin.")
            return false
        }

        guard MediaCollectionReportHelper.hasAllTrackingParams(state: state) else {
            Log.debug(label: LOG_TAG, "Unable to send MediaHit. Tracking parameter is missing.")
            return false
        }

        return true
    }

    ///Queues the `MediaHit`
    /// - Parameter hit: `MediaHit` to be queued.
    func queue(hit: MediaHit?) {
        guard let hit = hit else {
            Log.debug(label: LOG_TAG, "\(#function) - Unable to queue hit. MediaHit passed is nil.")
            return
        }

        guard isSessionActive else {
            Log.debug(label: LOG_TAG, "\(#function) - Unable to queue hit. Media Session is inactive.")
            return
        }

        handleQueueMediaHit(hit: hit)
    }

    ///Ends the session
    ///- Parameter onsessionEnd: An optional closure that will be executed after successfully ending the session.
    func end(onSessionEnd sessionEndHandler: (() -> Void)? = nil) {

        guard isSessionActive else {
            Log.debug(label: LOG_TAG, "\(#function) - Unable to end session. Session (\(id)) is inactive")
            return
        }

        self.sessionEndHandler = sessionEndHandler
        isSessionActive = false
        handleSessionEnd()
    }

    ///Aborts the session.
    ///- Parameter onSessionEnd: An optional closure that will be executed after successfully aborting the session.
    func abort(onSessionEnd sessionEndHandler: (() -> Void)? = nil) {

        guard isSessionActive else {
            Log.debug(label: LOG_TAG, "\(#function) - Unable to abort session. Session (\(id)) is inactive")
            return
        }

        self.sessionEndHandler = sessionEndHandler
        isSessionActive = false
        handleSessionAbort()
    }

    ///Includes the business logic for ending session. Implemented by more concrete classes of MediaSession: `MedialRealTimeSession` and `MediaOfflineSession`.
    func handleSessionEnd() {
        Log.warning(label: LOG_TAG, "\(#function) - This function should be handle by the child class.")
    }

    ///Includes the business logic for aborting session. Implemented by more concrete classes of MediaSession: `MedialRealTimeSession` and `MediaOfflineSession`.
    func handleSessionAbort() {
        Log.warning(label: LOG_TAG, "\(#function) - This function should be handle by the child class.")
    }

    ///Includes the business logic for queuing `MediaHit`. Implemented by more concrete classes of MediaSession: `MedialRealTimeSession` and `MediaOfflineSession`.
    /// - Parameter hit: `MediaHit` to be queued.
    func handleQueueMediaHit(hit: MediaHit) {
        Log.warning(label: LOG_TAG, "\(#function) - This function should be handle by the child class.")
    }
}
