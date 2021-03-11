/*
 Copyright 2021 Adobe. All rights reserved.
 This file is licensed to you under the Apache License Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0
 Unless required by applicable law or agreed to in writing software distributed under
 the License is distributed on an "AS IS" BASIS WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

import AEPServices

class MediaContext {
    enum MediaPlaybackState: String {
        case Play
        case Pause
        case Stall
        case Buffer
        case Seek
        case Init
    }

    static let LOG_TAG = "MediaContext"
    private var buffering: Bool
    private var seeking: Bool
    private var trackedStates: [String: Bool]

    private var playhead: Double
    private var playState: MediaPlaybackState

    private let mediaInfo: MediaInfo
    private let mediaMetadata: [String: String]?

    private var adBreakInfo: AdBreakInfo?
    private var adInfo: AdInfo?
    private var adMetadata: [String: String]?

    private var chapterInfo: ChapterInfo?
    private var chapterMetadata: [String: String]?

    private var errorInfo: [String: String]?
    private var qoeInfo: QoEInfo?

    init(mediaInfo: MediaInfo, metadata: [String: String]?) {
        self.mediaInfo = mediaInfo
        self.mediaMetadata = metadata
        self.buffering = false
        self.seeking = false
        self.trackedStates = [:]
        self.playhead = 0.0
        self.playState = MediaPlaybackState.Init
    }

    func getMediaInfo() -> MediaInfo? {
        return mediaInfo
    }

    func getMetadata() -> [String: String] {
        return mediaMetadata ?? [:]
    }

    // AdBreak
    func setAdBreak(info: AdBreakInfo?) {
        adBreakInfo = info
    }

    func clearAdBreakInfo() {
        adBreakInfo = nil
    }

    func isInAdBreak() -> Bool {
        return adBreakInfo != nil
    }

    func getAdBreakInfo() -> AdBreakInfo? {
        return adBreakInfo
    }

    // Ad
    func setAd(info: AdInfo?, metadata: [String: String]) {
        guard info != nil else {
            return
        }
        adInfo = info
        adMetadata = metadata
    }

    func clearAdInfo() {
        adInfo = nil
    }

    func isInAd() -> Bool {
        return adInfo != nil
    }

    func getAdInfo() -> AdInfo? {
        return adInfo
    }

    func getAdMetadata() -> [String: String] {
        return adMetadata ?? [:]
    }

    // Chapter
    func setChapter(info: ChapterInfo?, metadata: [String: String]) {
        guard info != nil else {
            return
        }
        chapterInfo = info
        chapterMetadata = metadata
    }

    func clearChapterInfo() {
        chapterInfo = nil
    }

    func isInChapter() -> Bool {
        return chapterInfo != nil
    }

    func getChapterInfo() -> ChapterInfo? {
        return chapterInfo
    }

    func getChapterMetadata() -> [String: String] {
        return chapterMetadata ?? [:]
    }

    // QoE
    func setQoE(info: QoEInfo?) {
        qoeInfo = info
    }

    func getQoEInfo() -> QoEInfo? {
        return qoeInfo
    }

    // Playhead
    func setPlayhead(value: Double) {
        playhead = value
    }

    func getPlayhead() -> Double {
        return playhead
    }

    func enter(state: MediaPlaybackState) {
        Log.trace(label: Self.LOG_TAG, "\(#function) EnterState - \(state)")
        switch state {
        case .Play, .Pause, .Stall:
            playState = state
        case .Buffer:
            buffering = true
        case .Seek:
            seeking = true
        default:
            Log.debug(label: Self.LOG_TAG, "\(#function) - Invalid state passed to enterState: \(state)")
        }
    }

    func exit(state: MediaPlaybackState) {
        Log.trace(label: Self.LOG_TAG, "\(#function) ExitState - \(state)")
        switch state {
        case .Buffer:
            buffering = false
        case .Seek:
            seeking = false
        default:
            Log.debug(label: Self.LOG_TAG, "\(#function) - Invalid state passed to exitState: \(state)")
        }
    }

    func isInMediaPlaybackState(state: MediaPlaybackState) -> Bool {
        var retVal = false

        switch state {
        case .Init, .Play, .Pause, .Stall:
            retVal = (playState == state)
        case .Buffer:
            retVal = buffering
        case .Seek:
            retVal = seeking
        }
        return retVal
    }

    func isIdle() -> Bool {
        return !isInMediaPlaybackState(state: MediaPlaybackState.Play) ||
            isInMediaPlaybackState(state: MediaPlaybackState.Seek) ||
            isInMediaPlaybackState(state: MediaPlaybackState.Buffer)
    }

    // State
    @discardableResult
    func startState(info: StateInfo?) -> Bool {
        guard let info = info else {
            return false
        }

        if !hasTrackedState(info: info) && didReachMaxStateLimit() {
            Log.debug(label: Self.LOG_TAG, "\(#function) - failed, already tracked max states \(MediaConstants.StateInfo.STATE_LIMIT) during the current session.")
            return false
        }

        if isInState(info: info) {
            Log.debug(label: Self.LOG_TAG, "\(#function) - failed, state \(info.stateName) is already being tracked.")
            return false
        }

        trackedStates[info.stateName] = true
        return true
    }

    @discardableResult
    func endState(info: StateInfo?) -> Bool {
        guard let info = info else {
            return false
        }

        if !isInState(info: info) {
            Log.debug(label: Self.LOG_TAG, "\(#function) - failed, state \(info.stateName) is not being tracked.")
            return false
        }

        trackedStates[info.stateName] = false
        return true
    }

    func isInState(info: StateInfo) -> Bool {
        guard let isStateActive = trackedStates[info.stateName] else {
            return false
        }

        return isStateActive
    }

    func hasTrackedState(info: StateInfo) -> Bool {
        return trackedStates[info.stateName] != nil
    }

    func getActiveTrackeStates() -> [StateInfo] {
        var activeStates: [StateInfo] = []

        for (name, active) in trackedStates {
            if active {
                if let stateInfo = StateInfo(stateName: name) {
                    activeStates.append(stateInfo)
                }
            }
        }

        return activeStates
    }

    func didReachMaxStateLimit() -> Bool {
        return trackedStates.count >= MediaConstants.StateInfo.STATE_LIMIT
    }

    func clearStates() {
        trackedStates.removeAll()
    }
}