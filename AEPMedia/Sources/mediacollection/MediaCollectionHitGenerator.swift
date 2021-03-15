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

class MediaCollectionHitGenerator {
    private let LOG_TAG = "MediaCollectionHitGenerator"

    private let mediaHitProcessor: MediaProcessor
    private let mediaConfig: [String: Any]
    private let downloadedContent: Bool
    private var lastQoeData: [String: Any] = [:]
    private var sessionId: String = ""
    private var isTracking: Bool = false
    private var reportingInterval: TimeInterval
    private var currentStateRefTs: TimeInterval
    private var currentState: MediaContext.MediaPlaybackState?
    private var previousStateTS: TimeInterval
    private var qoeInfoUpdated = false
    private typealias EventType = MediaConstants.MediaCollection.EventType
    private typealias Media = MediaConstants.MediaCollection.Media
    private typealias QoE = MediaConstants.MediaCollection.QoE

    #if DEBUG
        var mediaContext: MediaContext
    #else
        private var mediaContext: MediaContext
    #endif

    /// Initializes the Media Collection Hit Generator
    public required init(context: MediaContext, hitProcessor: MediaProcessor, config: [String: Any], refTS: TimeInterval) {
        self.mediaContext = context
        self.mediaHitProcessor = hitProcessor
        self.mediaConfig = config
        self.currentStateRefTs = refTS
        self.currentState = .Init
        self.previousStateTS = currentStateRefTs

        self.downloadedContent = mediaConfig[MediaConstants.TrackerConfig.DOWNLOADED_CONTENT] as? Bool ?? false
        self.reportingInterval = downloadedContent ? MediaConstants.PingInterval.DEFAULT_OFFLINE : MediaConstants.PingInterval.DEFAULT_ONLINE
        startTrackingSession()
    }

    func processMediaStart(forceResume: Bool = false) {
        var params = MediaCollectionHelper.extractMediaParams(mediaContext: mediaContext)

        if forceResume {
            params[Media.RESUME] = true
        }

        params[Media.DOWNLOADED] = downloadedContent

        if !self.mediaConfig.isEmpty {
            if let channel = mediaConfig[MediaConstants.TrackerConfig.CHANNEL] as? String, !channel.isEmpty {
                params[Media.CHANNEL] = channel
            }
        }

        let customMetadata = MediaCollectionHelper.extractMediaMetadata(mediaContext: mediaContext)

        generateHit(eventType: EventType.SESSION_START, params: params, metadata: customMetadata)
    }

    func processMediaComplete() {
        generateHit(eventType: EventType.SESSION_COMPLETE)
        endTrackingSession()
    }

    func processMediaSkip() {
        generateHit(eventType: EventType.SESSION_END)
        endTrackingSession()
    }

    func processAdBreakStart() {
        let params = MediaCollectionHelper.extractAdBreakParams(mediaContext: mediaContext)
        generateHit(eventType: EventType.ADBREAK_START, params: params)
    }

    func processAdBreakComplete() {
        generateHit(eventType: EventType.ADBREAK_COMPLETE)
    }

    func processAdBreakSkip() {
        generateHit(eventType: EventType.ADBREAK_COMPLETE)
    }

    func processAdStart() {
        let mediaInfo = mediaContext.mediaInfo
        let granularAdTrackingEnabled = mediaInfo.granularAdTracking

        if downloadedContent {
            reportingInterval = MediaConstants.PingInterval.DEFAULT_OFFLINE
        } else if granularAdTrackingEnabled {
            reportingInterval = MediaConstants.PingInterval.GRANULAR_AD
        } else {
            reportingInterval = MediaConstants.PingInterval.DEFAULT_ONLINE
        }

        let params = MediaCollectionHelper.extractAdParams(mediaContext: mediaContext)
        let metadata = MediaCollectionHelper.extractAdMetadata(mediaContext: mediaContext)

        generateHit(eventType: EventType.AD_START, params: params, metadata: metadata)
    }

    func processAdComplete() {
        reportingInterval = downloadedContent ? MediaConstants.PingInterval.DEFAULT_OFFLINE : MediaConstants.PingInterval.DEFAULT_ONLINE
        generateHit(eventType: EventType.AD_COMPLETE)
    }

    func processAdSkip() {
        reportingInterval = downloadedContent ? MediaConstants.PingInterval.DEFAULT_OFFLINE : MediaConstants.PingInterval.DEFAULT_ONLINE
        generateHit(eventType: EventType.AD_SKIP)
    }

    func processChapterStart() {
        let params = MediaCollectionHelper.extractChapterParams(mediaContext: mediaContext)
        let metadata = MediaCollectionHelper.extractChapterMetadata(mediaContext: mediaContext)

        generateHit(eventType: EventType.CHAPTER_START, params: params, metadata: metadata)
    }

    func processChapterComplete() {
        generateHit(eventType: EventType.CHAPTER_COMPLETE)
    }

    func processChapterSkip() {
        generateHit(eventType: EventType.CHAPTER_SKIP)
    }

    /// End media session after 24 hr timeout or idle timeout(30 mins).
    func processSessionAbort() {
        processMediaSkip()
    }

    /// Restart session again after 24 hr timeout or idle timeout recovered.
    func processSessionRestart() {
        currentState = .Init
        previousStateTS = currentStateRefTs

        lastQoeData.removeAll()

        sessionId = mediaHitProcessor.createSession(config: mediaConfig) ?? ""
        isTracking = true

        processMediaStart(forceResume: true)

        if mediaContext.chapterInfo != nil {
            processChapterStart()
        }

        if mediaContext.adBreakInfo != nil {
            processAdBreakStart()
        }

        if mediaContext.adInfo != nil {
            processAdStart()
        }

        for state in mediaContext.getActiveTrackedStates() {
            processStateStart(stateInfo: state)
        }

        processPlayback(doFlush: true)
    }

    func processBitrateChange() {
        let qoeData = mediaContext.qoeInfo?.toMap()
        generateHit(eventType: EventType.BITRATE_CHANGE, qoeData: qoeData)
    }

    func processError(errorId: String) {
        var qoeData = mediaContext.qoeInfo?.toMap()
        qoeData?[QoE.ERROR_ID] = errorId
        qoeData?[QoE.ERROR_SOURCE] = QoE.ERROR_SOURCE_PLAYER

        generateHit(eventType: EventType.ERROR, qoeData: qoeData)
    }

    func setRefTS(ts: Double) {
        self.currentStateRefTs = ts
    }

    func processPlayback(doFlush: Bool = false) {
        if !isTracking {
            return
        }

        let currentState = getPlaybackState()

        if (self.currentState != currentState || doFlush) {
            let eventType = getMediaCollectionEvent(state: currentState)
            generateHit(eventType: eventType)
            self.currentState = currentState
            previousStateTS = currentStateRefTs
        } else if (self.currentState == currentState) && (currentStateRefTs - previousStateTS >= reportingInterval) {
            // if the ts difference is more than interval we need to send it as multiple pings
            generateHit(eventType: EventType.PING)
            previousStateTS = currentStateRefTs
        }
    }

    func processStateStart(stateInfo: StateInfo?) {
        guard let stateInfo = stateInfo else {
            Log.debug(label: LOG_TAG, "\(#function) - Received nil stateInfo, will not generate a start state hit.")
            return
        }
        var params = [String: Any]()
        params[MediaConstants.StateInfo.STATE_NAME_KEY] = stateInfo.stateName

        generateHit(eventType: EventType.STATE_START, params: params)
    }

    func processStateEnd(stateInfo: StateInfo?) {
        guard let stateInfo = stateInfo else {
            Log.debug(label: LOG_TAG, "\(#function) - Received nil stateInfo, will not generate an end state hit.")
            return
        }
        var params = [String: Any]()
        params[MediaConstants.StateInfo.STATE_NAME_KEY] = stateInfo.stateName

        generateHit(eventType: EventType.STATE_END, params: params)
    }

    func startTrackingSession() {
        guard let sessionId = mediaHitProcessor.createSession(config: mediaConfig) else {
            Log.debug(label: LOG_TAG, "\(#function) - Unable to create a tracking session.")
            isTracking = false
            return
        }
        self.sessionId = sessionId
        isTracking = true
    }

    #if DEBUG
        func endTrackingSession() {
            mediaHitProcessor.endSession(sessionId: sessionId)
            isTracking = false
        }
    #else
        private func endTrackingSession() {
            mediaHitProcessor.endSession(sessionId: sessionId)
            isTracking = false
        }
    #endif

    func generateHit(eventType: String, params: [String: Any]? = nil, metadata: [String: String]? = nil, qoeData: [String: Any]? = nil) {
        let mediaContextQoeData = mediaContext.qoeInfo?.toMap() ?? [String: Any]()
        let passedInQoeData = qoeData ?? [String: Any]()
        var qoeDataForCurrentHit = [String: Any]()

        if !isTracking {
            Log.debug(label: LOG_TAG, "\(#function) - Dropping hit as we have internally stopped tracking")
            return
        }

        // for bitrate change events, error events, and calls to generateHit with qoeData present,
        // we want to use the qoe data in the current hit being generated.
        // for all other events, qoe data will be sent on the next hit after a qoe info change.
        switch eventType {
        case EventType.BITRATE_CHANGE, EventType.ERROR:
            qoeDataForCurrentHit = passedInQoeData
        default:
            // handle case when generateHit is called with qoeData
            if !passedInQoeData.isEmpty {
                qoeDataForCurrentHit = passedInQoeData
            }
            // handle case when qoe info has been updated
            else if self.qoeInfoUpdated {
                qoeDataForCurrentHit = mediaContextQoeData

            }
        }

        // check if qoe info updated. if so, send qoe data in next hit.
        self.qoeInfoUpdated = self.lastQoeData as NSDictionary != mediaContextQoeData as NSDictionary

        // update the lastQoeData so we don't resend it with the next ping
        if !qoeDataForCurrentHit.isEmpty {
            self.lastQoeData = qoeDataForCurrentHit
        }

        let playhead = mediaContext.playhead
        let refTs = currentStateRefTs

        let hit = MediaHit.init(eventType: eventType, playhead: playhead, ts: refTs, params: params ?? [String: Any](), customMetadata: metadata ?? [String: String](), qoeData: qoeDataForCurrentHit)
        mediaHitProcessor.processHit(sessionId: sessionId, hit: hit)
    }

    func getPlaybackState() -> MediaContext.MediaPlaybackState {
        if mediaContext.isInMediaPlaybackState(state: .Buffer) {
            return .Buffer
        } else if mediaContext.isInMediaPlaybackState(state: .Seek) {
            return .Seek
        } else if mediaContext.isInMediaPlaybackState(state: .Play) {
            return .Play
        } else if mediaContext.isInMediaPlaybackState(state: .Pause) {
            return .Pause
        } else if mediaContext.isInMediaPlaybackState(state: .Stall) {
            return .Stall
        } else {
            return .Init
        }
    }

    func getMediaCollectionEvent(state: MediaContext.MediaPlaybackState) -> String {
        switch state {
        case .Buffer:
            return EventType.BUFFER_START
        case .Seek:
            return EventType.PAUSE_START
        case .Play:
            return EventType.PLAY
        case .Pause:
            return EventType.PAUSE_START
        case .Stall:
            // Stall not supported by backend we just send Play event for it
            return EventType.PLAY
        case .Init:
            // We should never hit this condition as there is no event to denote init.
            // Ping without any previous playback state denotes init.
            return EventType.PING
        }
    }
}
