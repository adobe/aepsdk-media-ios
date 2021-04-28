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
    private var isTracking: Bool = false
    private var reportingInterval: Int64
    private var refTS: Int64
    private var currentPlaybackState: MediaContext.MediaPlaybackState?
    private var currentPlaybackStateStartRefTS: Int64
    private typealias EventType = MediaConstants.MediaCollection.EventType
    private typealias Media = MediaConstants.MediaCollection.Media

    #if DEBUG
        var mediaContext: MediaContext
        var sessionId: String = ""
    #else
        private var mediaContext: MediaContext
        private var sessionId: String = ""
    #endif

    /// Initializes the Media Collection Hit Generator
    public required init?(context: MediaContext?, hitProcessor: MediaProcessor, config: [String: Any], refTS: Int64) {
        guard let context = context else {
            Log.debug(label: Self.LOG_TAG, "\(#function) - Unable to create a MediaCollectionHitGenerator, media context is nil.")
            return nil
        }
        self.mediaContext = context
        self.mediaHitProcessor = hitProcessor
        self.mediaConfig = config
        self.refTS = refTS
        self.currentPlaybackState = .Init
        self.currentPlaybackStateStartRefTS = refTS
        self.downloadedContent = mediaConfig[MediaConstants.TrackerConfig.DOWNLOADED_CONTENT] as? Bool ?? false
        self.reportingInterval = downloadedContent ?
            MediaConstants.PingInterval.OFFLINE_TRACKING :
            MediaConstants.PingInterval.REALTIME_TRACKING
        startTrackingSession()
    }

    func processMediaStart(forceResume: Bool = false) {
        var params = MediaCollectionHelper.generateMediaParams(mediaInfo: mediaContext.mediaInfo, metadata: mediaContext.mediaMetadata)

        if forceResume {
            params[Media.RESUME] = true
        }

        params[Media.DOWNLOADED] = downloadedContent

        if let channel = mediaConfig[MediaConstants.TrackerConfig.CHANNEL] as? String, !channel.isEmpty {
            params[Media.CHANNEL] = channel
        }

        let customMetadata = MediaCollectionHelper.generateMediaMetadata(metadata: mediaContext.mediaMetadata)

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
        let params = MediaCollectionHelper.generateAdBreakParams(adBreakInfo: mediaContext.adBreakInfo)
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
            reportingInterval = MediaConstants.PingInterval.OFFLINE_TRACKING
        } else if granularAdTrackingEnabled {
            reportingInterval = MediaConstants.PingInterval.GRANULAR_AD_TRACKING
        } else {
            reportingInterval = MediaConstants.PingInterval.REALTIME_TRACKING
        }

        let params = MediaCollectionHelper.generateAdParams(adInfo: mediaContext.adInfo, adMetadata: mediaContext.adMetadata)
        let metadata = MediaCollectionHelper.generateAdMetadata(adMetadata: mediaContext.adMetadata)

        generateHit(eventType: EventType.AD_START, params: params, metadata: metadata)
    }

    func processAdComplete() {
        reportingInterval = downloadedContent ?
            MediaConstants.PingInterval.OFFLINE_TRACKING :
            MediaConstants.PingInterval.REALTIME_TRACKING
        generateHit(eventType: EventType.AD_COMPLETE)
    }

    func processAdSkip() {
        reportingInterval = downloadedContent ?
            MediaConstants.PingInterval.OFFLINE_TRACKING :
            MediaConstants.PingInterval.REALTIME_TRACKING
        generateHit(eventType: EventType.AD_SKIP)
    }

    func processChapterStart() {
        let params = MediaCollectionHelper.generateChapterParams(chapterInfo: mediaContext.chapterInfo)
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
        currentPlaybackStateStartRefTS = refTS

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
        let qoeData = MediaCollectionHelper.generateQoEParam(qoeInfo: mediaContext.qoeInfo)
        generateHit(eventType: EventType.BITRATE_CHANGE, qoeData: qoeData)
    }

    func processError(errorId: String) {
        let qoeDataWithError = MediaCollectionHelper.generateQoEParam(qoeInfo: mediaContext.qoeInfo, errorId: errorId)
        generateHit(eventType: EventType.ERROR, qoeData: qoeDataWithError)
    }

    func setRefTS(ts: Int64) {
        refTS = ts
    }

    func processPlayback(doFlush: Bool = false) {
        if !isTracking {
            return
        }

        let newPlaybackState = getPlaybackState()

        if self.currentPlaybackState != newPlaybackState || doFlush {
            let eventType = getMediaCollectionEvent(state: newPlaybackState)
            generateHit(eventType: eventType)
            currentPlaybackState = newPlaybackState
            currentPlaybackStateStartRefTS = refTS
        } else if (newPlaybackState == currentPlaybackState) && (refTS - currentPlaybackStateStartRefTS >= reportingInterval) {
            // if the ts difference is more than interval we need to send it as multiple pings
            generateHit(eventType: EventType.PING)
            currentPlaybackStateStartRefTS = refTS
        }
    }

    func processStateStart(stateInfo: StateInfo?) {
        guard let stateInfo = stateInfo else {
            Log.debug(label: Self.LOG_TAG, "\(#function) - Received nil stateInfo, will not generate a start state hit.")
            return
        }

        let  params: [String: Any] = [
            MediaConstants.MediaCollection.State.NAME: stateInfo.stateName
        ]
        generateHit(eventType: EventType.STATE_START, params: params)
    }

    func processStateEnd(stateInfo: StateInfo?) {
        guard let stateInfo = stateInfo else {
            Log.debug(label: Self.LOG_TAG, "\(#function) - Received nil stateInfo, will not generate an end state hit.")
            return
        }

        let  params: [String: Any] = [
            MediaConstants.MediaCollection.State.NAME: stateInfo.stateName
        ]
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

    private func endTrackingSession() {
        if isTracking {
            Log.trace(label: Self.LOG_TAG, "\(#function) - Ending session with id \(sessionId).")
            mediaHitProcessor.endSession(sessionId: sessionId)
            isTracking = false
        }
    }

    private func generateHit(eventType: String, params: [String: Any]? = nil, metadata: [String: String]? = nil, qoeData: [String: Any]? = nil) {
        let passedInQoeData = qoeData ?? [String: Any]()

        if !isTracking {
            Log.debug(label: Self.LOG_TAG, "\(#function) - Dropping hit as we have internally stopped tracking")
            return
        }
        // for bitrate change events and error events we want to use the qoe data in the current hit being generated.
        let qoeForCurrentHit = getQoEForCurrentHit(qoeData: passedInQoeData)
        let playhead = mediaContext.playhead
        let ts = refTS
        let hit = MediaHit(eventType: eventType, playhead: playhead, ts: ts, params: params, customMetadata: metadata, qoeData: qoeForCurrentHit)
        mediaHitProcessor.processHit(sessionId: sessionId, hit: hit)
    }

    private func getQoEForCurrentHit(qoeData: [String: Any]?) -> [String: Any]? {
        if let qoeData = qoeData, !qoeData.isEmpty {
            lastReportedQoeData = qoeData
            return qoeData
        }
        let mediaContextQoeData = MediaCollectionHelper.generateQoEParam(qoeInfo: mediaContext.qoeInfo)
        if !(lastReportedQoeData as NSDictionary).isEqual(to: mediaContextQoeData) {
            lastReportedQoeData = mediaContextQoeData
            return mediaContextQoeData
        } else {
            return nil
        }
    }

    private func getPlaybackState() -> MediaContext.MediaPlaybackState {
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

    private func getMediaCollectionEvent(state: MediaContext.MediaPlaybackState) -> String {
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
