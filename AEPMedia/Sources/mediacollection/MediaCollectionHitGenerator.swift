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
    private static let LOG_TAG = "MediaCollectionHitGenerator"

    private let mediaHitProcessor: MediaProcessor
    private let mediaConfig: [String: Any]
    private let downloadedContent: Bool
    private var lastReportedQoeData: [String: Any] = [:]
    private var sessionId: String = ""
    private var isTracking: Bool = false
    private var reportingInterval: TimeInterval
    private var currentRefTS: TimeInterval
    private var currentPlaybackState: MediaContext.MediaPlaybackState?
    private var currentPlaybackStateStartRefTs: TimeInterval
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
    public required init?(context: MediaContext?, hitProcessor: MediaProcessor, config: [String: Any], refTS: TimeInterval) {
        guard let context = context else {
            Log.debug(label: Self.LOG_TAG, "\(#function) - Unable to create a MediaCollectionHitGenerator, media context is nil.")
            return nil
        }
        self.mediaContext = context
        self.mediaHitProcessor = hitProcessor
        self.mediaConfig = config
        self.currentRefTS = refTS
        self.currentPlaybackState = .Init
        self.currentPlaybackStateStartRefTs = currentRefTS

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

        if let channel = mediaConfig[MediaConstants.TrackerConfig.CHANNEL] as? String, !channel.isEmpty {
            params[Media.CHANNEL] = channel
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
        let metadata = mediaContext.chapterMetadata

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
        currentPlaybackState = .Init
        currentPlaybackStateStartRefTs = currentRefTS

        lastReportedQoeData.removeAll()
        startTrackingSession()
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
        self.currentRefTS = ts
    }

    func processPlayback(doFlush: Bool = false) {
        if !isTracking {
            return
        }

        let currentPlaybackState = getPlaybackState()

        if (self.currentPlaybackState != currentPlaybackState || doFlush) {
            let eventType = getMediaCollectionEvent(state: currentPlaybackState)
            generateHit(eventType: eventType)
            self.currentPlaybackState = currentPlaybackState
            currentPlaybackStateStartRefTs = currentRefTS
        } else if (self.currentPlaybackState == currentPlaybackState) && (currentRefTS - currentPlaybackStateStartRefTs >= reportingInterval) {
            // if the ts difference is more than interval we need to send it as multiple pings
            generateHit(eventType: EventType.PING)
            currentPlaybackStateStartRefTs = currentRefTS
        }
    }

    func processStateStart(stateInfo: StateInfo?) {
        guard let stateInfo = stateInfo else {
            Log.debug(label: Self.LOG_TAG, "\(#function) - Received nil stateInfo, will not generate a start state hit.")
            return
        }
        var params = [String: Any]()
        params[MediaConstants.StateInfo.STATE_NAME_KEY] = stateInfo.stateName

        generateHit(eventType: EventType.STATE_START, params: params)
    }

    func processStateEnd(stateInfo: StateInfo?) {
        guard let stateInfo = stateInfo else {
            Log.debug(label: Self.LOG_TAG, "\(#function) - Received nil stateInfo, will not generate an end state hit.")
            return
        }
        var params = [String: Any]()
        params[MediaConstants.StateInfo.STATE_NAME_KEY] = stateInfo.stateName

        generateHit(eventType: EventType.STATE_END, params: params)
    }

    private func startTrackingSession() {
        guard let sessionId = mediaHitProcessor.createSession(config: mediaConfig) else {
            Log.debug(label: Self.LOG_TAG, "\(#function) - Unable to create a tracking session.")
            isTracking = false
            return
        }
        Log.debug(label: Self.LOG_TAG, "\(#function) - Started a new session with id \(sessionId).")
        self.sessionId = sessionId
        isTracking = true
    }

    #if DEBUG
        func endTrackingSession() {
            mediaHitProcessor.endSession(sessionId: sessionId)
            isTracking = false
        }
        func generateHit(eventType: String, params: [String: Any]? = nil, metadata: [String: String]? = nil, qoeData: [String: Any]? = nil) {
            let passedInQoeData = qoeData ?? [String: Any]()

            if !isTracking {
                Log.debug(label: Self.LOG_TAG, "\(#function) - Dropping hit as we have internally stopped tracking")
                return
            }
            let qoeForCurrentHit = getQoEForCurrentHit(qoeData: passedInQoeData)
            let playhead = mediaContext.playhead
            let refTs = currentRefTS
            let hit = MediaHit(eventType: eventType, playhead: playhead, ts: refTs, params: params ?? [String: Any](), customMetadata: metadata ?? [String: String](), qoeData: qoeForCurrentHit)
            mediaHitProcessor.processHit(sessionId: sessionId, hit: hit)
        }
    #else
        private func endTrackingSession() {
            mediaHitProcessor.endSession(sessionId: sessionId)
            isTracking = false
        }
        private func generateHit(eventType: String, params: [String: Any]? = nil, metadata: [String: String]? = nil, qoeData: [String: Any]? = nil) {
            let passedInQoeData = qoeData ?? [String: Any]()

            if !isTracking {
                Log.debug(label: Self.LOG_TAG, "\(#function) - Dropping hit as we have internally stopped tracking")
                return
            }
            // for bitrate change events and error events we want to use the qoe data in the current hit being generated.
            // for all other events, qoe data will be sent on the next hit after a qoe info change.
            let qoeForCurrentHit = getQoEForCurrentHit(qoeData: passedInQoeData)
            let playhead = mediaContext.playhead
            let refTs = currentRefTS
            let hit = MediaHit(eventType: eventType, playhead: playhead, ts: refTs, params: params ?? [String: Any](), customMetadata: metadata ?? [String: String](), qoeData: qoeForCurrentHit)
            mediaHitProcessor.processHit(sessionId: sessionId, hit: hit)
        }
    #endif

    private func getQoEForCurrentHit(qoeData: [String: Any]) -> [String: Any] {
        let mediaContextQoeData = mediaContext.qoeInfo?.toMap() ?? [String: Any]()
        // we always used passed in qoe data in the next generated hit
        if !qoeData.isEmpty {
            lastReportedQoeData = qoeData
            return qoeData
            // check if last reported qoe data is different than media context's version.
            // if so, store it as the last reported qoe data.
        } else if lastReportedQoeData as NSDictionary != mediaContextQoeData as NSDictionary {
            lastReportedQoeData = mediaContextQoeData
            // use the last reported qoe data on the next hit after a qoe info change
        } else {
            return lastReportedQoeData
        }
        return [:]
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
        case .Init:
            // We should never hit this condition as there is no event to denote init.
            // Ping without any previous playback state denotes init.
            return EventType.PING
        }
    }
}
