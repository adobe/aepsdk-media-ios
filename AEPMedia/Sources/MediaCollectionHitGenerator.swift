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
    let LOG_TAG = "MediaCollectionHitGenerator"

    let mediaContext: MediaContext?
    let mediaHitProcessor = MediaHitProcessor()
    let mediaConfig: [String: Any]?
    let downloadedContent: Bool
    var lastQoeData: [String: Any] = [:]
    var sessionID: Int
    var isTracking: Bool
    var interval: TimeInterval
    var refTS: Double
    var previousState: MediaPlaybackState?
    var previousStateTS: Double

    /// Initializes the Media Collection Hit Generator
    public required init(context: MediaContext, hitProcessor: MediaHitProcessor, config: [String: Any]?, timestamp: Double) {
        self.mediaContext = context
        self.mediaConfig = config
        self.refTS = timestamp
        previousState = MediaPlaybackState.Init
        self.previousStateTS = refTS

        self.downloadedContent = mediaConfig?[MediaConstants.Configuration.DOWNLOADED_CONTENT] as? Bool ?? false
        self.interval = downloadedContent ? MediaConstants.PingInterval.DEFAULT_OFFLINE : MediaConstants.PingInterval.DEFAULT_ONLINE
        self.sessionID = mediaHitProcessor.startSession()
        self.isTracking = true
    }

    func processMediaStart() {
        processMediaStart(forceResume: false)
    }

    func processMediaStart(forceResume: Bool) {
        guard let mediaContext = self.mediaContext else {
            Log.debug(label: self.LOG_TAG, "processMediaStart - Ignoring media start event, media context is nil")
            return
        }

        var params = MediaCollectionHelper.extractMediaParams(mediaContext: mediaContext)

        if forceResume {
            params[MediaConstants.MediaInfo.RESUMED] = true
        }

        params[MediaConstants.MediaInfo.DOWNLOADED] = downloadedContent

        if let mediaConfig = self.mediaConfig, !mediaConfig.isEmpty {
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
        guard let mediaContext = self.mediaContext else {
            Log.debug(label: self.LOG_TAG, "processAdBreakStart - Ignoring ad break start event, media context is nil")
            return
        }

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
        guard let mediaContext = self.mediaContext else {
            Log.debug(label: self.LOG_TAG, "processAdStart - Ignoring ad start event, media context is nil")
            return
        }

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
        guard let mediaContext = self.mediaContext else {
            Log.debug(label: self.LOG_TAG, "processChapterStart - Ignoring chapter start event, media context is nil")
            return
        }

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
        guard let mediaContext = self.mediaContext else {
            Log.debug(label: self.LOG_TAG, "processSessionRestart - Ignoring session start event, media context is nil")
            return
        }

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
        guard let mediaContext = self.mediaContext else {
            Log.debug(label: self.LOG_TAG, "processBitrateChange - Ignoring bitrate change event, media context is nil")
            return
        }

        let qoeData = MediaCollectionHelper.extractQoeData(mediaContext: mediaContext)
        generateHit(eventType: MediaConstants.EventName.BITRATE_CHANGE, params: nil, metadata: nil, qoeData: qoeData)
    }

    func processError(errorId: String) {
        guard let mediaContext = self.mediaContext else {
            Log.debug(label: self.LOG_TAG, "processError - Ignoring error event, media context is nil")
            return
        }

        var qoeData = MediaCollectionHelper.extractQoeData(mediaContext: mediaContext)
        qoeData[MediaConstants.MediaCollection.QoE.ERROR_ID] = errorId
        qoeData[MediaConstants.MediaCollection.QoE.ERROR_SOURCE] = MediaConstants.MediaCollection.QoE.ERROR_SOURCE_PLAYER

        generateHit(eventType: MediaConstants.EventName.ERROR, params: nil, metadata: nil, qoeData: qoeData)
    }

    private func processPlayback(doFlush: Bool) {
        if !isTracking {
            return
        }

        guard let currentState = getPlaybackState() else {
            Log.error(label: self.LOG_TAG, "processPlayback - Ignoring playback event, current state is nil")
            return
        }

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

    func setRefTS(ts: Double) {
        self.refTS = ts
    }

    private func generateHit(eventType: String) {
        generateHit(eventType: eventType, params: nil, metadata: nil)
    }

    private func generateHit(eventType: String, params: [String: Any]?, metadata: [String: String]?) {
        guard let mediaContext = self.mediaContext else {
            Log.debug(label: self.LOG_TAG, "generateHit - Hit not generated, media context is nil")
            return
        }

        let qoeData = MediaCollectionHelper.extractQoeData(mediaContext: mediaContext)
        let qoeInfoUpdated = self.lastQoeData as NSDictionary == qoeData as NSDictionary

        if qoeInfoUpdated {
            generateHit(eventType: eventType, params: params, metadata: metadata, qoeData: qoeData)
        } else {
            generateHit(eventType: eventType, params: params, metadata: metadata, qoeData: nil)
        }
    }

    private func generateHit(eventType: String, params: [String: Any]?, metadata: [String: String]?, qoeData: [String: Any]?) {
        guard let mediaContext = self.mediaContext else {
            Log.debug(label: self.LOG_TAG, "generateHit - Hit not generated, media context is nil")
            return
        }

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

        // TODO: create MediaHit class
//        let hit = MediaHit(eventType: eventType, params: params, metadata: metadata, qoeData: qoeData, playhead: playhead, ts: ts)
        //		mediaHitProcessor.processHit(sessionID, hit)
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

    private func getPlaybackState() -> MediaPlaybackState? {
        guard let mediaContext = self.mediaContext else {
            Log.debug(label: self.LOG_TAG, "getPlaybackState - Unable to get playback state, media context is nil")
            return nil
        }

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
        if state == MediaPlaybackState.Buffer {
            return MediaConstants.EventName.BUFFER_START
        } else if state == MediaPlaybackState.Seek {
            return MediaConstants.EventName.PAUSE
        } else if state == MediaPlaybackState.Play {
            return MediaConstants.EventName.PLAY
        } else if state == MediaPlaybackState.Pause {
            return MediaConstants.EventName.PAUSE
        } else if state == MediaPlaybackState.Stall {
            // Stall not supported by backend we just send Play event for it
            return MediaConstants.EventName.PLAY
        } else if state == MediaPlaybackState.Init {
            // We should never hit this condition as there is not event to denote init.
            // Ping without any previous playback state denotes init.
            return MediaConstants.EventName.PING
        } else {
            return ""
        }
    }
}
