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

    private let mediaContext: MediaContext
    private let mediaHitProcessor: MediaHitProcessor
    private let mediaConfig: [String: Any]
    private let downloadedContent: Bool
    private var lastQoeData: [String: Any] = [:]
    private var sessionID: Int
    private var isTracking: Bool
    private var interval: TimeInterval
    private var refTS: Double
    private var previousState: MediaPlaybackState?
    private var previousStateTS: Double

    /// Initializes the Media Collection Hit Generator
    public required init(context: MediaContext, hitProcessor: MediaHitProcessor, config: [String: Any], timestamp: Double) {
        self.mediaContext = context
        self.mediaHitProcessor = hitProcessor
        self.mediaConfig = config
        self.refTS = timestamp
        previousState = MediaPlaybackState.Init
        self.previousStateTS = refTS

        self.downloadedContent = mediaConfig[MediaConstants.Configuration.DOWNLOADED_CONTENT] as? Bool ?? false
        self.interval = downloadedContent ? MediaConstants.PingInterval.DEFAULT_OFFLINE : MediaConstants.PingInterval.DEFAULT_ONLINE
        self.sessionID = mediaHitProcessor.startSession()
        self.isTracking = true
    }

    func processMediaStart() {
        processMediaStart(forceResume: false)
    }

    func processMediaStart(forceResume: Bool) {
        var params = MediaCollectionHelper.extractMediaParams(mediaContext: mediaContext)

        if forceResume {
            params[MediaConstants.MediaInfo.RESUMED] = true
        }

        params[MediaConstants.MediaInfo.DOWNLOADED] = downloadedContent

        if !self.mediaConfig.isEmpty {
            params[MediaConstants.Configuration.CHANNEL] = mediaConfig[MediaConstants.Configuration.MEDIA_CHANNEL]
        }

        let customMetadata = MediaCollectionHelper.extractMediaMetadata(mediaContext: mediaContext)

        generateHit(eventType: MediaConstants.EventName.SESSION_START, params: params, metadata: customMetadata)
    }

    func processMediaComplete() {
        generateHit(eventType: MediaConstants.EventName.COMPLETE)
        endMediaSession()
    }

    func processMediaSkip() {
        generateHit(eventType: MediaConstants.EventName.SESSION_END)
        endMediaSession()
    }

    func processAdBreakStart() {
        let params = MediaCollectionHelper.extractAdBreakParams(mediaContext: mediaContext)
        generateHit(eventType: MediaConstants.EventName.AD_START, params: params, metadata: nil)
    }

    func processAdBreakComplete() {
        generateHit(eventType: MediaConstants.EventName.AD_COMPLETE)
    }

    func processAdBreakSkip() {
        generateHit(eventType: MediaConstants.EventName.AD_SKIP)
    }

    func processAdStart() {
        let mediaInfo = mediaContext.getMediaInfo()
        let granularTrackingEnabled = mediaInfo[MediaConstants.MediaInfo.GRANULAR_AD_TRACKING] as? Bool ?? false

        if downloadedContent {
            interval = MediaConstants.PingInterval.DEFAULT_OFFLINE
        } else if granularTrackingEnabled == true {
            interval = MediaConstants.PingInterval.GRANULAR_AD
        } else {
            interval = MediaConstants.PingInterval.DEFAULT_ONLINE
        }

        let params = MediaCollectionHelper.extractAdParams(mediaContext: mediaContext)
        let metadata = MediaCollectionHelper.extractAdMetadata(mediaContext: mediaContext)

        generateHit(eventType: MediaConstants.EventName.AD_START, params: params, metadata: metadata)
    }

    func processAdComplete() {
        interval = downloadedContent ? MediaConstants.PingInterval.DEFAULT_OFFLINE : MediaConstants.PingInterval.DEFAULT_ONLINE
        generateHit(eventType: MediaConstants.EventName.AD_COMPLETE)
    }

    func processAdSkip() {
        interval = downloadedContent ? MediaConstants.PingInterval.DEFAULT_OFFLINE : MediaConstants.PingInterval.DEFAULT_ONLINE
        generateHit(eventType: MediaConstants.EventName.AD_SKIP)
    }

    func processChapterStart() {
        let params = MediaCollectionHelper.extractChapterParams(mediaContext: mediaContext)
        let metadata = MediaCollectionHelper.extractChapterMetadata(mediaContext: mediaContext)

        generateHit(eventType: MediaConstants.EventName.CHAPTER_START, params: params, metadata: metadata)
    }

    func processChapterComplete() {
        generateHit(eventType: MediaConstants.EventName.CHAPTER_COMPLETE)
    }

    func processChapterSkip() {
        generateHit(eventType: MediaConstants.EventName.CHAPTER_SKIP)
    }

    /// End media session after 24 hr timeout or idle timeout(30 mins).
    func processSessionAbort() {
        processMediaSkip()
    }

    /// Restart session again after 24 hr timeout or idle timeout recovered.
    func processSessionRestart() {
        previousState = MediaPlaybackState.Init
        previousStateTS = refTS

        lastQoeData.removeAll()

        sessionID = mediaHitProcessor.startSession()
        isTracking = true

        processMediaStart(forceResume: true)

        if mediaContext.isInChapter() {
            processChapterStart()
        }

        if mediaContext.isInAdBreak() {
            processAdBreakStart()
        }

        if mediaContext.isInAd() {
            processAdStart()
        }

        for state in mediaContext.getActiveTrackedStates() {
            processStateStart(stateInfo: state)
        }

        processPlayback(doFlush: true)
    }


    func processBitrateChange() {
        let qoeData = MediaCollectionHelper.extractQoeData(mediaContext: mediaContext)
        generateHit(eventType: MediaConstants.EventName.BITRATE_CHANGE, params: nil, metadata: nil, qoeData: qoeData)
    }

    func processError(errorId: String) {
        var qoeData = MediaCollectionHelper.extractQoeData(mediaContext: mediaContext)
        qoeData[MediaConstants.MediaCollection.QoE.ERROR_ID] = errorId
        qoeData[MediaConstants.MediaCollection.QoE.ERROR_SOURCE] = MediaConstants.MediaCollection.QoE.ERROR_SOURCE_PLAYER

        generateHit(eventType: MediaConstants.EventName.ERROR, params: nil, metadata: nil, qoeData: qoeData)
    }
    
    func setRefTS(ts: Double) {
        self.refTS = ts
    }

    private func processPlayback(doFlush: Bool) {
        if !isTracking {
            return
        }

        let currentState = getPlaybackState()

        if (previousState != currentState || doFlush) {
            let eventType = getMediaCollectionEvent(state: currentState)
            generateHit(eventType: eventType)
            previousState = currentState
            previousStateTS = refTS
        } else if (previousState == currentState && (refTS - previousStateTS) >= interval) {
            // if the ts difference is more than interval we need to send it as multiple pings
            generateHit(eventType: MediaConstants.EventName.PING)
            previousStateTS = refTS
        }
    }

    private func generateHit(eventType: String) {
        generateHit(eventType: eventType, params: nil, metadata: nil)
    }

    private func generateHit(eventType: String, params: [String: Any]?, metadata: [String: String]?) {
        let qoeData = MediaCollectionHelper.extractQoeData(mediaContext: mediaContext)
        let qoeInfoUpdated = self.lastQoeData as NSDictionary == qoeData as NSDictionary

        if qoeInfoUpdated {
            generateHit(eventType: eventType, params: params, metadata: metadata, qoeData: qoeData)
        } else {
            generateHit(eventType: eventType, params: params, metadata: metadata, qoeData: nil)
        }
    }

    private func generateHit(eventType: String, params: [String: Any]?, metadata: [String: String]?, qoeData: [String: Any]?) {
        // Update the lastQoeData so we don't resend it with the next ping
        if let qoeData = qoeData, !qoeData.isEmpty {
            self.lastQoeData = qoeData
        }

        if !isTracking {
            Log.debug(label: self.LOG_TAG, "generateHit - Dropping hit as we have internally stopped tracking")
            return
        }

        let playhead = mediaContext.getPlayhead()
        let ts = refTS

        let hit = MediaHit.init(eventType: eventType, params: params, metadata: metadata, qoeData: qoeData, playhead: playhead, ts: ts)
        mediaHitProcessor.processHit(sessionID: sessionID, hit: hit)
    }

    private func processStateStart(stateInfo: StateInfo) {
        var params = [String: Any]()

        params[MediaConstants.StateInfo.STATE_NAME_KEY] = stateInfo.getStateName()

        generateHit(eventType: MediaConstants.EventName.STATE_START, params: params, metadata: nil)
    }

    private func processStateEnd(stateInfo: StateInfo) {
        var params = [String: Any]()

        params[MediaConstants.StateInfo.STATE_NAME_KEY] = stateInfo.getStateName()

        generateHit(eventType: MediaConstants.EventName.STATE_END, params: params, metadata: nil)
    }

    private func endMediaSession() {
        mediaHitProcessor.endSession(sessionID: sessionID)
        isTracking = false
    }

    private func getPlaybackState() -> MediaPlaybackState {
        if mediaContext.isInState(MediaPlaybackState.Buffer) {
            return MediaPlaybackState.Buffer
        } else if mediaContext.isInState(MediaPlaybackState.Seek) {
            return MediaPlaybackState.Seek
        } else if mediaContext.isInState(MediaPlaybackState.Play) {
            return MediaPlaybackState.Play
        } else if mediaContext.isInState(MediaPlaybackState.Pause) {
            return MediaPlaybackState.Pause
        } else if mediaContext.isInState(MediaPlaybackState.Stall) {
            return MediaPlaybackState.Stall
        } else {
            return MediaPlaybackState.Init
        }
    }

    private func getMediaCollectionEvent(state: MediaPlaybackState) -> String {
        switch state {
            case MediaPlaybackState.Buffer:
                return MediaConstants.EventName.BUFFER_START
            case MediaPlaybackState.Seek:
                return MediaConstants.EventName.PAUSE
            case MediaPlaybackState.Play:
                return MediaConstants.EventName.PLAY
            case MediaPlaybackState.Pause:
                return MediaConstants.EventName.PAUSE
            case MediaPlaybackState.Stall:
                // Stall not supported by backend we just send Play event for it
                return MediaConstants.EventName.PLAY
            case MediaPlaybackState.Init:
                // We should never hit this condition as there is not event to denote init.
                // Ping without any previous playback state denotes init.
                return MediaConstants.EventName.PING
        }
    }
}
