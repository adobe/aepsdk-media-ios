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

import Foundation
import AEPServices
import AEPCore

// swiftlint:disable type_body_length
class MediaEventTracker: MediaEventTracking {
    // MARK: Rule Name

    enum RuleName: Int {
        case MediaStart
        case MediaComplete
        case MediaSkip
        case AdBreakStart
        case AdBreakComplete
        case AdStart
        case AdComplete
        case AdSkip
        case ChapterStart
        case ChapterComplete
        case ChapterSkip
        case Play
        case Pause
        case SeekStart
        case SeekComplete
        case BufferStart
        case BufferComplete
        case BitrateChange
        case Error
        case QoEUpdate
        case PlayheadUpdate
        case StateStart
        case StateEnd
    }

    static let eventToRuleMap: [String: RuleName] = [
        MediaConstants.EventName.SESSION_START: RuleName.MediaStart,
        MediaConstants.EventName.COMPLETE: RuleName.MediaComplete,
        MediaConstants.EventName.SESSION_END: RuleName.MediaSkip,

        MediaConstants.EventName.ADBREAK_START: RuleName.AdBreakStart,
        MediaConstants.EventName.ADBREAK_COMPLETE: RuleName.AdBreakComplete,

        MediaConstants.EventName.AD_START: RuleName.AdStart,
        MediaConstants.EventName.AD_COMPLETE: RuleName.AdComplete,
        MediaConstants.EventName.AD_SKIP: RuleName.AdSkip,

        MediaConstants.EventName.CHAPTER_START: RuleName.ChapterStart,
        MediaConstants.EventName.CHAPTER_COMPLETE: RuleName.ChapterComplete,
        MediaConstants.EventName.CHAPTER_SKIP: RuleName.ChapterSkip,

        MediaConstants.EventName.PLAY: RuleName.Play,
        MediaConstants.EventName.PAUSE: RuleName.Pause,
        MediaConstants.EventName.SEEK_START: RuleName.SeekStart,
        MediaConstants.EventName.SEEK_COMPLETE: RuleName.SeekComplete,
        MediaConstants.EventName.BUFFER_START: RuleName.BufferStart,
        MediaConstants.EventName.BUFFER_COMPLETE: RuleName.BufferComplete,

        MediaConstants.EventName.BITRATE_CHANGE: RuleName.BitrateChange,
        MediaConstants.EventName.ERROR: RuleName.Error,
        MediaConstants.EventName.QOE_UPDATE: RuleName.QoEUpdate,
        MediaConstants.EventName.PLAYHEAD_UPDATE: RuleName.PlayheadUpdate,
        MediaConstants.EventName.STATE_START: RuleName.StateStart,
        MediaConstants.EventName.STATE_END: RuleName.StateEnd
    ]

    enum ErrorMessage: String {
        case ErrNotInMedia = "Media tracker is not in active tracking session, call 'API:trackSessionStart' to begin a new tracking session."
        case ErrInMedia = "Media tracker is in active tracking session, call 'API:trackSessionEnd' or 'API:trackComplete' to end current tracking session."
        case ErrInBuffer = "Media tracker is tracking buffer events, call 'API:trackEvent(BufferComplete)' first to stop tracking buffer events."
        case ErrNotInBuffer = "Media tracker is not tracking buffer events, call 'API:trackEvent(BufferStart)' before 'API:trackEvent(BufferComplete)'."
        case ErrInSeek = "Media tracker is tracking seek events, call 'API:trackEvent(SeekComplete)' first to stop tracking seek events."
        case ErrNotInSeek = "Media tracker is not tracking seek events, call 'API:trackEvent(SeekStart)' before 'API:trackEvent(SeekComplete)'."
        case ErrNotInAdBreak = "Media tracker is not tracking any AdBreak, call 'API:trackEvent(AdBreakStart)' to begin tracking AdBreak"
        case ErrNotInAd = "Media tracker is not tracking any Ad, call 'API:trackEvent(AdStart)' to begin tracking Ad"
        case ErrNotInChapter = "Media tracker is not tracking any Chapter, call 'API:trackEvent(ChapterStart)' to begin tracking Chapter"
        case ErrInvalidMediaInfo = "MediaInfo passed into 'API:trackSessionStart' is invalid."
        case ErrInvalidAdBreakInfo = "AdBreakInfo passed into 'API:trackEvent(AdBreakStart)' is invalid."
        case ErrDuplicateAdBreakInfo = "Media tracker is currently tracking the AdBreak passed into 'API:trackEvent(AdBreakStart)'."
        case ErrInvalidAdInfo = "AdInfo passed into 'API:trackEvent(AdStart)' is invalid."
        case ErrDuplicateAdInfo = "Media tracker is currently tracking the Ad passed into 'API:trackEvent(AdStart)'."
        case ErrInvalidChapterInfo = "ChapterInfo passed into 'API:trackEvent(ChapterStart)' is invalid."
        case ErrDuplicateChapterInfo =  "Media tracker is currently tracking the Chapter passed into 'API:trackEvent(ChapterStart)'."
        case ErrInvalidQoEInfo = "QoEInfo passed into 'API:updateQoEInfo' is invalid."
        case ErrInvalidPlayhead = "Playhead value not present in 'API:updatePlayhead' event data."
        case ErrInvalidPlaybackState = "Media tracker is tracking an AdBreak but not tracking any Ad and will drop any calls to track player state (Play, Pause, Buffer or Seek) in this state."
        case ErrInvalidStateInfo = "StateInfo passed into 'API:trackEvent(StartStart)' or 'API:trackEvent(StartEnd)' is invalid."
        case ErrInTrackedState = "Media tracker is already tracking a state with the same state name."
        case ErrNotInTrackedState = "Media tracker is not tracking a state with the given state name."
        case ErrTrackedStatesLimitReached = "Media tracker has reached maximum number of states per session (10)."
    }

    private static let KEY_INFO = "key_info"
    private static let KEY_METADATA = "key_metadata"
    private static let KEY_EVENT_TS = "key_eventts"
    private static let KEY_EVENT = "key_event"

    private static let LOG_TAG = MediaConstants.LOG_TAG
    private static let CLASS_NAME = "MediaEventTracker"
    private static let IDLE_TIMEOUT_MS: Int64 = 1800 * 1000 // 30 min
    private static let MEDIA_SESSION_TIMEOUT_MS: Int64 = 86400 * 1000 // 24 hours
    private static let CONTENT_START_DURATION_MS: Int64 = 1 * 1000 // 1 sec

    #if DEBUG
        var inPrerollInterval = false
        var trackerIdle = false
        var mediaContext: MediaContext?
    #else
        private var inPrerollInterval = false
        private var trackerIdle = false
        private var mediaContext: MediaContext?
    #endif

    private let hitProcessor: MediaProcessor
    private var hitGenerator: MediaCollectionHitGenerator?
    private let config: [String: Any]?
    private var mediaIdle = false
    private var prerollQueuedRules: [(name: RuleName, context: [String: Any])] = []
    private var contentStarted = false
    private static let INVALID_TS: Int64 = -1
    private var prerollRefTS: Int64 = INVALID_TS
    private var contentStartRefTS: Int64 = INVALID_TS
    private var mediaSessionStartTS: Int64 = INVALID_TS
    private var mediaIdleStartTS: Int64 = INVALID_TS
    private let ruleEngine: MediaRuleEngine

    init(hitProcessor: MediaProcessor, config: [String: Any]) {
        self.hitProcessor = hitProcessor
        self.config = config
        ruleEngine = MediaRuleEngine()
        setupRules()
    }

    private func reset() {
        self.hitGenerator = nil
        self.mediaContext = nil

        self.trackerIdle = false
        self.mediaIdle = false

        inPrerollInterval = false
        prerollQueuedRules.removeAll()
        contentStarted = false
        prerollRefTS = Self.INVALID_TS
        contentStartRefTS = Self.INVALID_TS
        mediaSessionStartTS = Self.INVALID_TS
        mediaIdleStartTS = Self.INVALID_TS
    }

    /// Handles all the track API calls.
    /// - Parameters:
    ///    - event: Event for the track API consisting of eventName, playhead, timeStamp, params and metadata.
    @discardableResult
    func track(event: Event) -> Bool {

        guard let rule = Self.eventToRuleMap[event.name ?? ""] else {
            Log.debug(label: Self.LOG_TAG, "[\(Self.CLASS_NAME)<\(#function)>] - Event name is missing/invalid in track event data.")
            return false
        }

        guard let eventTs = event.eventTs else {
            Log.debug(label: Self.LOG_TAG, "[\(Self.CLASS_NAME)<\(#function)>] - Event timestamp is missing in track event data.")
            return false
        }

        var ruleContext: [String: Any] = [:]
        ruleContext[Self.KEY_EVENT] = event
        ruleContext[Self.KEY_EVENT_TS] = eventTs

        if let param = event.param {
            ruleContext[Self.KEY_INFO] = param
        }

        if let metadata = event.metadata {
            ruleContext[Self.KEY_METADATA] = cleanMetadata(data: metadata)
        }

        if rule != RuleName.PlayheadUpdate {
            Log.trace(label: Self.LOG_TAG, "[\(Self.CLASS_NAME)<\(#function)>] - Processing event - \(String(describing: event.name))")
        }

        if prerollDeferRule(rule: rule, context: ruleContext) {
            return true
        }

        return processRule(rule: rule, context: ruleContext)
    }

    /// Processes rules through preset conditions set in the state machine
    /// - Parameters:
    ///    - rule: EventName corresponding to API call
    ///    - context: Data passed with the corresponding API call
    @discardableResult
    private func processRule(rule: RuleName, context: [String: Any]) -> Bool {
        let result = ruleEngine.processRule(name: rule.rawValue, context: context)

        if !result.success {
            Log.warning(label: Self.LOG_TAG, "[\(Self.CLASS_NAME)<\(#function)>] - ProcessRule - \(result.errorMsg)")
        }

        return result.success
    }

    /// Setup state machine i.e. conditions and actions for each Rule
    /// - Parameters:
    ///    - rule: EventName corresponding to API call
    ///    - context: Data passed with the corresponding API call
    private func setupRules() {
        ruleEngine.onEnterRule(enterFn: cmdEnterAction(rule:context:))
        ruleEngine.onExitRule(exitFn: cmdExitAction(rule:context:))

        let mediaStart = MediaRule(name: RuleName.MediaStart.rawValue, description: "API::trackSessionStart")
        mediaStart.addPredicate(predicateFn: isInMedia(rule:context:), expectedValue: false, errorMsg: ErrorMessage.ErrInMedia.rawValue)
            .addPredicate(predicateFn: isValidMediaInfo(rule:context:), expectedValue: true, errorMsg: ErrorMessage.ErrInvalidMediaInfo.rawValue)
            .addAction(actionFn: cmdMediaStart(rule:context:))
        ruleEngine.add(rule: mediaStart)

        let mediaComplete = MediaRule(name: RuleName.MediaComplete.rawValue, description: "API::trackComplete")
        mediaComplete.addPredicate(predicateFn: isInMedia(rule:context:), expectedValue: true, errorMsg: ErrorMessage.ErrNotInMedia.rawValue)
            .addAction(actionFn: cmdAdSkip(rule:context:))
            .addAction(actionFn: cmdAdBreakSkip(rule:context:))
            .addAction(actionFn: cmdChapterSkip(rule:context:))
            .addAction(actionFn: cmdMediaComplete(rule:context:))
        ruleEngine.add(rule: mediaComplete)

        let mediaSkip = MediaRule(name: RuleName.MediaSkip.rawValue, description: "API::trackSessionEnd")
        mediaSkip.addPredicate(predicateFn: isInMedia(rule:context:), expectedValue: true, errorMsg: ErrorMessage.ErrNotInMedia.rawValue)
            .addAction(actionFn: cmdAdSkip(rule:context:))
            .addAction(actionFn: cmdAdBreakSkip(rule:context:))
            .addAction(actionFn: cmdChapterSkip(rule:context:))
            .addAction(actionFn: cmdMediaSkip(rule:context:))
        ruleEngine.add(rule: mediaSkip)

        let error = MediaRule(name: RuleName.Error.rawValue, description: "API::trackError")
        error.addPredicate(predicateFn: isInMedia(rule:context:), expectedValue: true, errorMsg: ErrorMessage.ErrNotInMedia.rawValue)
            .addAction(actionFn: cmdError(rule:context:))
        ruleEngine.add(rule: error)

        let play = MediaRule(name: RuleName.Play.rawValue, description: "API::trackPlay")
        play.addPredicate(predicateFn: isInMedia(rule:context:), expectedValue: true, errorMsg: ErrorMessage.ErrNotInMedia.rawValue)
            .addPredicate(predicateFn: allowPlaybackStateChange(rule:context:), expectedValue: true, errorMsg: ErrorMessage.ErrInvalidPlaybackState.rawValue)
            .addAction(actionFn: cmdSeekComplete(rule:context:))
            .addAction(actionFn: cmdBufferComplete(rule:context:))
            .addAction(actionFn: cmdPlay(rule:context:))
        ruleEngine.add(rule: play)

        let pause = MediaRule(name: RuleName.Pause.rawValue, description: "API::trackPause")
        pause.addPredicate(predicateFn: isInMedia(rule:context:), expectedValue: true, errorMsg: ErrorMessage.ErrNotInMedia.rawValue)
            .addPredicate(predicateFn: allowPlaybackStateChange(rule:context:), expectedValue: true, errorMsg: ErrorMessage.ErrInvalidPlaybackState.rawValue)
            .addPredicate(predicateFn: isBuffering(rule:context:), expectedValue: false, errorMsg: ErrorMessage.ErrInBuffer.rawValue)
            .addPredicate(predicateFn: isSeeking(rule:context:), expectedValue: false, errorMsg: ErrorMessage.ErrInSeek.rawValue)
            .addAction(actionFn: cmdPause(rule:context:))
        ruleEngine.add(rule: pause)

        let bufferStart = MediaRule(name: RuleName.BufferStart.rawValue, description: "API::trackEvent(BufferStart)")
        bufferStart.addPredicate(predicateFn: isInMedia(rule:context:), expectedValue: true, errorMsg: ErrorMessage.ErrNotInMedia.rawValue)
            .addPredicate(predicateFn: allowPlaybackStateChange(rule:context:), expectedValue: true, errorMsg: ErrorMessage.ErrInvalidPlaybackState.rawValue)
            .addPredicate(predicateFn: isBuffering(rule:context:), expectedValue: false, errorMsg: ErrorMessage.ErrInBuffer.rawValue)
            .addPredicate(predicateFn: isSeeking(rule:context:), expectedValue: false, errorMsg: ErrorMessage.ErrInSeek.rawValue)
            .addAction(actionFn: cmdBufferStart(rule:context:))
        ruleEngine.add(rule: bufferStart)

        let bufferComplete = MediaRule(name: RuleName.BufferComplete.rawValue, description: "API::trackEvent(BufferComplete)")
        bufferComplete.addPredicate(predicateFn: isInMedia(rule:context:), expectedValue: true, errorMsg: ErrorMessage.ErrNotInMedia.rawValue)
            .addPredicate(predicateFn: allowPlaybackStateChange(rule:context:), expectedValue: true, errorMsg: ErrorMessage.ErrInvalidPlaybackState.rawValue)
            .addPredicate(predicateFn: isBuffering(rule:context:), expectedValue: true, errorMsg: ErrorMessage.ErrNotInBuffer.rawValue)
            .addAction(actionFn: cmdBufferComplete(rule:context:))
        ruleEngine.add(rule: bufferComplete)

        let seekStart = MediaRule(name: RuleName.SeekStart.rawValue, description: "API::trackEvent(SeekStart)")
        seekStart.addPredicate(predicateFn: isInMedia(rule:context:), expectedValue: true, errorMsg: ErrorMessage.ErrNotInMedia.rawValue)
            .addPredicate(predicateFn: allowPlaybackStateChange(rule:context:), expectedValue: true, errorMsg: ErrorMessage.ErrInvalidPlaybackState.rawValue)
            .addPredicate(predicateFn: isSeeking(rule:context:), expectedValue: false, errorMsg: ErrorMessage.ErrInSeek.rawValue)
            .addPredicate(predicateFn: isBuffering(rule:context:), expectedValue: false, errorMsg: ErrorMessage.ErrInBuffer.rawValue)
            .addAction(actionFn: cmdSeekStart(rule:context:))
        ruleEngine.add(rule: seekStart)

        let seekComplete = MediaRule(name: RuleName.SeekComplete.rawValue, description: "API::trackEvent(SeekComplete)")
        seekComplete.addPredicate(predicateFn: isInMedia(rule:context:), expectedValue: true, errorMsg: ErrorMessage.ErrNotInMedia.rawValue)
            .addPredicate(predicateFn: allowPlaybackStateChange(rule:context:), expectedValue: true, errorMsg: ErrorMessage.ErrInvalidPlaybackState.rawValue)
            .addPredicate(predicateFn: isSeeking(rule:context:), expectedValue: true, errorMsg: ErrorMessage.ErrNotInSeek.rawValue)
            .addAction(actionFn: cmdSeekComplete(rule:context:))
        ruleEngine.add(rule: seekComplete)

        let adBreakStart = MediaRule(name: RuleName.AdBreakStart.rawValue, description: "API::trackEvent(AdBreakStart)")
        adBreakStart.addPredicate(predicateFn: isInMedia(rule:context:), expectedValue: true, errorMsg: ErrorMessage.ErrNotInMedia.rawValue)
            .addPredicate(predicateFn: isValidAdBreakInfo(rule:context:), expectedValue: true, errorMsg: ErrorMessage.ErrInvalidAdBreakInfo.rawValue)
            .addPredicate(predicateFn: isDifferentAdBreakInfo(rule:context:), expectedValue: true, errorMsg: ErrorMessage.ErrDuplicateAdBreakInfo.rawValue)
            .addAction(actionFn: cmdAdSkip(rule:context:))
            .addAction(actionFn: cmdAdBreakSkip(rule:context:))
            .addAction(actionFn: cmdAdBreakStart(rule:context:))
        ruleEngine.add(rule: adBreakStart)

        let adBreakComplete = MediaRule(name: RuleName.AdBreakComplete.rawValue, description: "API::trackEvent(AdBreakComplete)")
        adBreakComplete.addPredicate(predicateFn: isInMedia(rule:context:), expectedValue: true, errorMsg: ErrorMessage.ErrNotInMedia.rawValue)
            .addPredicate(predicateFn: isInAdBreak(rule:context:), expectedValue: true, errorMsg: ErrorMessage.ErrNotInAdBreak.rawValue)
            .addAction(actionFn: cmdAdSkip(rule:context:))
            .addAction(actionFn: cmdAdBreakComplete(rule:context:))
        ruleEngine.add(rule: adBreakComplete)

        let adStart = MediaRule(name: RuleName.AdStart.rawValue, description: "API::trackEvent(AdStart)")
        adStart.addPredicate(predicateFn: isInMedia(rule:context:), expectedValue: true, errorMsg: ErrorMessage.ErrNotInMedia.rawValue)
            .addPredicate(predicateFn: isInAdBreak(rule:context:), expectedValue: true, errorMsg: ErrorMessage.ErrNotInAdBreak.rawValue)
            .addPredicate(predicateFn: isValidAdInfo(rule:context:), expectedValue: true, errorMsg: ErrorMessage.ErrInvalidAdInfo.rawValue)
            .addPredicate(predicateFn: isDifferentAdInfo(rule:context:), expectedValue: true, errorMsg: ErrorMessage.ErrDuplicateAdInfo.rawValue)
            .addAction(actionFn: cmdAdSkip(rule:context:))
            .addAction(actionFn: cmdAdStart(rule:context:))
        ruleEngine.add(rule: adStart)

        let adComplete = MediaRule(name: RuleName.AdComplete.rawValue, description: "API::trackEvent(AdComplete)")
        adComplete.addPredicate(predicateFn: isInMedia(rule:context:), expectedValue: true, errorMsg: ErrorMessage.ErrNotInMedia.rawValue)
            .addPredicate(predicateFn: isInAdBreak(rule:context:), expectedValue: true, errorMsg: ErrorMessage.ErrNotInAdBreak.rawValue)
            .addPredicate(predicateFn: isInAd(rule:context:), expectedValue: true, errorMsg: ErrorMessage.ErrNotInAd.rawValue)
            .addAction(actionFn: cmdAdComplete(rule:context:))
        ruleEngine.add(rule: adComplete)

        let adSkip = MediaRule(name: RuleName.AdSkip.rawValue, description: "API::trackEvent(AdSkip)")
        adSkip.addPredicate(predicateFn: isInMedia(rule:context:), expectedValue: true, errorMsg: ErrorMessage.ErrNotInMedia.rawValue)
            .addPredicate(predicateFn: isInAdBreak(rule:context:), expectedValue: true, errorMsg: ErrorMessage.ErrNotInAdBreak.rawValue)
            .addPredicate(predicateFn: isInAd(rule:context:), expectedValue: true, errorMsg: ErrorMessage.ErrNotInAd.rawValue)
            .addAction(actionFn: cmdAdSkip(rule:context:))
        ruleEngine.add(rule: adSkip)

        let chapterStart = MediaRule(name: RuleName.ChapterStart.rawValue, description: "API::trackEvent(ChapterStart)")
        chapterStart.addPredicate(predicateFn: isInMedia(rule:context:), expectedValue: true, errorMsg: ErrorMessage.ErrNotInMedia.rawValue)
            .addPredicate(predicateFn: isValidChapterInfo(rule:context:), expectedValue: true, errorMsg: ErrorMessage.ErrInvalidChapterInfo.rawValue)
            .addPredicate(predicateFn: isDifferentChapterInfo(rule:context:), expectedValue: true, errorMsg: ErrorMessage.ErrDuplicateChapterInfo.rawValue)
            .addAction(actionFn: cmdChapterSkip(rule:context:))
            .addAction(actionFn: cmdChapterStart(rule:context:))
        ruleEngine.add(rule: chapterStart)

        let chapterComplete = MediaRule(name: RuleName.ChapterComplete.rawValue, description: "API::trackEvent(ChapterComplete")
        chapterComplete.addPredicate(predicateFn: isInMedia(rule:context:), expectedValue: true, errorMsg: ErrorMessage.ErrNotInMedia.rawValue)
            .addPredicate(predicateFn: isInChapter(rule:context:), expectedValue: true, errorMsg: ErrorMessage.ErrNotInChapter.rawValue)
            .addAction(actionFn: cmdChapterComplete(rule:context:))
        ruleEngine.add(rule: chapterComplete)

        let chapterSkip = MediaRule(name: RuleName.ChapterSkip.rawValue, description: "API::trackEvent(ChapterSkip")
        chapterSkip.addPredicate(predicateFn: isInMedia(rule:context:), expectedValue: true, errorMsg: ErrorMessage.ErrNotInMedia.rawValue)
            .addPredicate(predicateFn: isInChapter(rule:context:), expectedValue: true, errorMsg: ErrorMessage.ErrNotInChapter.rawValue)
            .addAction(actionFn: cmdChapterSkip(rule:context:))
        ruleEngine.add(rule: chapterSkip)

        let bitrateChange = MediaRule(name: RuleName.BitrateChange.rawValue, description: "API::trackEvent(BitrateChange)")
        bitrateChange.addPredicate(predicateFn: isInMedia(rule:context:), expectedValue: true, errorMsg: ErrorMessage.ErrNotInMedia.rawValue)
            .addAction(actionFn: cmdBitrateChange(rule:context:))
        ruleEngine.add(rule: bitrateChange)

        let qoeUpdate = MediaRule(name: RuleName.QoEUpdate.rawValue, description: "API::trackEvent(UpdateQoEInfo)")
        qoeUpdate.addPredicate(predicateFn: isInMedia(rule:context:), expectedValue: true, errorMsg: ErrorMessage.ErrNotInMedia.rawValue)
            .addPredicate(predicateFn: isValidQoEInfo(rule:context:), expectedValue: true, errorMsg: ErrorMessage.ErrInvalidQoEInfo.rawValue)
            .addAction(actionFn: cmdQoEUpdate(rule:context:))
        ruleEngine.add(rule: qoeUpdate)

        let playheadUpdate = MediaRule(name: RuleName.PlayheadUpdate.rawValue, description: "API::trackEvent(UpdatePlayhead)")
        playheadUpdate.addPredicate(predicateFn: isInMedia(rule:context:), expectedValue: true, errorMsg: ErrorMessage.ErrNotInMedia.rawValue)
            .addAction(actionFn: cmdPlayheadUpdate(rule:context:))
        ruleEngine.add(rule: playheadUpdate)

        let stateStart = MediaRule(name: RuleName.StateStart.rawValue, description: "API::trackEvent(StateStart)")
        stateStart.addPredicate(predicateFn: isInMedia(rule:context:), expectedValue: true, errorMsg: ErrorMessage.ErrNotInMedia.rawValue)
            .addPredicate(predicateFn: isValidStateInfo(rule:context:), expectedValue: true, errorMsg: ErrorMessage.ErrInvalidStateInfo.rawValue)
            .addPredicate(predicateFn: isTrackingState(rule:context:), expectedValue: false, errorMsg: ErrorMessage.ErrInTrackedState.rawValue)
            .addPredicate(predicateFn: allowStateTrack(rule:context:), expectedValue: true, errorMsg: ErrorMessage.ErrTrackedStatesLimitReached.rawValue)
            .addAction(actionFn: cmdStateStart(rule:context:))
        ruleEngine.add(rule: stateStart)

        let stateEnd = MediaRule(name: RuleName.StateEnd.rawValue, description: "API::trackEvent(StateEnd)")
        stateEnd.addPredicate(predicateFn: isInMedia(rule:context:), expectedValue: true, errorMsg: ErrorMessage.ErrNotInMedia.rawValue)
            .addPredicate(predicateFn: isValidStateInfo(rule:context:), expectedValue: true, errorMsg: ErrorMessage.ErrInvalidStateInfo.rawValue)
            .addPredicate(predicateFn: isTrackingState(rule:context:), expectedValue: true, errorMsg: ErrorMessage.ErrNotInTrackedState.rawValue)
            .addAction(actionFn: cmdStateEnd(rule:context:))
        ruleEngine.add(rule: stateEnd)

    }

    // MARK: Rule Predicates
    private func isInMedia(rule: MediaRule, context: [String: Any]) -> Bool {
        return mediaContext != nil
    }

    private func isInAdBreak(rule: MediaRule, context: [String: Any]) -> Bool {
        return mediaContext?.adBreakInfo != nil
    }

    private func isInAd(rule: MediaRule, context: [String: Any]) -> Bool {
        return mediaContext?.adInfo != nil
    }

    private func isInChapter(rule: MediaRule, context: [String: Any]) -> Bool {
        return mediaContext?.chapterInfo != nil
    }

    private func isBuffering(rule: MediaRule, context: [String: Any]) -> Bool {
        return mediaContext?.buffering ?? false
    }

    private func isSeeking(rule: MediaRule, context: [String: Any]) -> Bool {
        return mediaContext?.seeking ?? false
    }

    private func isTrackingState(rule: MediaRule, context: [String: Any]) -> Bool {
        guard let state = StateInfo(info: context[Self.KEY_INFO] as? [String: Any]) else {
            return false
        }
        return mediaContext?.isInState(info: state) ?? false
    }

    private func allowStateTrack(rule: MediaRule, context: [String: Any]) -> Bool {
        guard let state = StateInfo(info: context[Self.KEY_INFO] as? [String: Any]) else {
            return false
        }
        return (mediaContext?.hasTrackedState(info: state) ?? false) || !(mediaContext?.didReachMaxStateLimit() ?? true)
    }

    private func isValidMediaInfo(rule: MediaRule, context: [String: Any]) -> Bool {
        return MediaInfo(info: context[Self.KEY_INFO] as? [String: Any]) != nil
    }

    private func isValidAdBreakInfo(rule: MediaRule, context: [String: Any]) -> Bool {
        return AdBreakInfo(info: context[Self.KEY_INFO] as? [String: Any]) != nil
    }

    private func isValidAdInfo(rule: MediaRule, context: [String: Any]) -> Bool {
        return AdInfo(info: context[Self.KEY_INFO] as? [String: Any]) != nil
    }

    private func isValidChapterInfo(rule: MediaRule, context: [String: Any]) -> Bool {
        return ChapterInfo(info: context[Self.KEY_INFO] as? [String: Any]) != nil
    }

    private func isValidQoEInfo(rule: MediaRule, context: [String: Any]) -> Bool {
        return QoEInfo(info: context[Self.KEY_INFO] as? [String: Any]) != nil
    }

    private func isValidStateInfo(rule: MediaRule, context: [String: Any]) -> Bool {
        return StateInfo(info: context[Self.KEY_INFO] as? [String: Any]) != nil
    }

    private func isDifferentAdBreakInfo(rule: MediaRule, context: [String: Any]) -> Bool {
        guard let mediaContext = mediaContext else {
            return false
        }

        if mediaContext.adBreakInfo == nil {
            return true
        }

        let currAdBreak = mediaContext.adBreakInfo
        let newAdBreak = AdBreakInfo(info: context[Self.KEY_INFO] as? [String: Any] ?? [:])
        return currAdBreak != newAdBreak
    }

    private func isDifferentAdInfo(rule: MediaRule, context: [String: Any]) -> Bool {
        guard let mediaContext = mediaContext else {
            return false
        }

        if mediaContext.adInfo == nil {
            return true
        }

        let currAd = mediaContext.adInfo
        let newAd = AdInfo(info: context[Self.KEY_INFO] as? [String: Any] ?? [:])
        return currAd != newAd
    }

    private func isDifferentChapterInfo(rule: MediaRule, context: [String: Any]) -> Bool {
        guard let mediaContext = mediaContext else {
            return false
        }

        if mediaContext.chapterInfo == nil {
            return true
        }

        let currChapter = mediaContext.chapterInfo
        let newChapter = ChapterInfo(info: context[Self.KEY_INFO] as? [String: Any] ?? [:])
        return currChapter != newChapter
    }

    private func allowPlaybackStateChange(rule: MediaRule, context: [String: Any]) -> Bool {
        guard let mediaContext = mediaContext else {
            return false
        }
        // Change of Playback State not allowed inside AdBreak but outside Ad
        return (mediaContext.adBreakInfo == nil) || (mediaContext.adInfo != nil)
    }

    // MARK: Rule Actions
    private func cmdEnterAction(rule: MediaRule, context: [String: Any]) -> Bool {
        if hitGenerator != nil {
            hitGenerator?.setRefTS(ts: getRefTS(context: context))
        }
        return true
    }

    private func cmdExitAction(rule: MediaRule, context: [String: Any]) -> Bool {
        guard let mediaContext = mediaContext else {
            return false
        }

        // Force the state to play when we receive adstart before any play/pause.
        // Happens usually for preroll ad. We manually switch our state to play as the backend
        // automatically switches state to play after adstart.
        if rule.name == RuleName.AdStart.rawValue {
            if mediaContext.isInMediaPlaybackState(state: MediaContext.MediaPlaybackState.Init) &&
                !mediaContext.isInMediaPlaybackState(state: MediaContext.MediaPlaybackState.Buffer) &&
                !mediaContext.isInMediaPlaybackState(state: MediaContext.MediaPlaybackState.Seek) {
                mediaContext.enterPlaybackState(state: MediaContext.MediaPlaybackState.Play)
            }
        }

        // If we receive BufferComplete / SeekComplete before first play / pause,
        // we manually switch to pause as there is not way to go back to init state.
        if rule.name == RuleName.BufferComplete.rawValue || rule.name == RuleName.SeekComplete.rawValue {
            if mediaContext.isInMediaPlaybackState(state: MediaContext.MediaPlaybackState.Init) {
                mediaContext.enterPlaybackState(state: MediaContext.MediaPlaybackState.Pause)
            }
        }

        cmdIdleDetection(rule: rule, context: context)
        cmdSessionTimeoutDetection(rule: rule, context: context)
        cmdContentStartDetection(rule: rule, context: context)

        // Flush the playback state after AdStart and AdBreakComplete
        let shouldFlush = (rule.name == RuleName.AdStart.rawValue) || (rule.name == RuleName.AdBreakComplete.rawValue)
        hitGenerator?.processPlayback(doFlush: shouldFlush)

        return true
    }

    private func cmdMediaStart(rule: MediaRule, context: [String: Any]) -> Bool {
        guard let mediaInfo = MediaInfo(info: context[Self.KEY_INFO] as? [String: Any]) else {
            return false
        }

        guard let refEvent = context[Self.KEY_EVENT] as? Event else {
            return false
        }

        let metadata = getMetadata(context: context)

        let refTS = getRefTS(context: context)

        mediaContext = MediaContext(mediaInfo: mediaInfo, metadata: metadata)
        hitGenerator = MediaCollectionHitGenerator(context: mediaContext, hitProcessor: hitProcessor, config: config ?? [:], refEvent: refEvent, refTS: refTS)
        hitGenerator?.processMediaStart()

        inPrerollInterval = mediaInfo.prerollWaitingTime != 0
        prerollRefTS = refTS
        mediaSessionStartTS = refTS

        return true
    }

    private func cmdMediaComplete(rule: MediaRule, context: [String: Any]) -> Bool {
        hitGenerator?.processMediaComplete()
        reset()

        return true
    }

    private func cmdMediaSkip(rule: MediaRule, context: [String: Any]) -> Bool {
        hitGenerator?.processMediaSkip()
        reset()

        return true
    }

    private func cmdAdBreakStart(rule: MediaRule, context: [String: Any]) -> Bool {
        guard let adBreakInfo = AdBreakInfo(info: context[Self.KEY_INFO] as? [String: Any]) else {
            return false
        }
        mediaContext?.setAdBreak(info: adBreakInfo)
        hitGenerator?.processAdBreakStart()
        return true
    }

    private func cmdAdBreakComplete(rule: MediaRule, context: [String: Any]) -> Bool {
        hitGenerator?.processAdBreakComplete()
        mediaContext?.clearAdBreak()

        return true
    }

    private func cmdAdBreakSkip(rule: MediaRule, context: [String: Any]) -> Bool {
        // This may be called even when we are not in adbreak.
        if mediaContext?.adBreakInfo != nil {
            hitGenerator?.processAdBreakSkip()
            mediaContext?.clearAdBreak()
        }
        return true
    }

    private func cmdAdStart(rule: MediaRule, context: [String: Any]) -> Bool {
        guard let adInfo = AdInfo(info: context[Self.KEY_INFO] as? [String: Any]) else {
            return false
        }
        let metadata = getMetadata(context: context)

        mediaContext?.setAd(info: adInfo, metadata: metadata)
        hitGenerator?.processAdStart()

        return true
    }

    private func cmdAdComplete(rule: MediaRule, context: [String: Any]) -> Bool {
        hitGenerator?.processAdComplete()
        mediaContext?.clearAd()

        return true
    }

    private func cmdAdSkip(rule: MediaRule, context: [String: Any]) -> Bool {
        // This may be called even when we are not in ad.
        if mediaContext?.adInfo != nil {
            hitGenerator?.processAdSkip()
            mediaContext?.clearAd()
        }

        return true
    }

    private func cmdChapterStart(rule: MediaRule, context: [String: Any]) -> Bool {
        guard let chapterInfo = ChapterInfo(info: context[Self.KEY_INFO] as? [String: Any]) else {
            return false
        }
        let metadata = getMetadata(context: context)

        mediaContext?.setChapter(info: chapterInfo, metadata: metadata)
        hitGenerator?.processChapterStart()

        return true
    }

    private func cmdChapterComplete(rule: MediaRule, context: [String: Any]) -> Bool {
        hitGenerator?.processChapterComplete()
        mediaContext?.clearChapter()

        return true
    }

    private func cmdChapterSkip(rule: MediaRule, context: [String: Any]) -> Bool {
        // This may be called even when we are not in chapter.
        if mediaContext?.chapterInfo != nil {
            hitGenerator?.processChapterSkip()
            mediaContext?.clearChapter()
        }
        return true
    }

    private func cmdError(rule: MediaRule, context: [String: Any]) -> Bool {
        if let errorId = getError(context: context) {
            hitGenerator?.processError(errorId: errorId)
        }
        return true
    }

    private func cmdBitrateChange(rule: MediaRule, context: [String: Any]) -> Bool {
        hitGenerator?.processBitrateChange()
        return true
    }

    private func cmdPlay(rule: MediaRule, context: [String: Any]) -> Bool {
        mediaContext?.enterPlaybackState(state: MediaContext.MediaPlaybackState.Play)
        return true
    }

    private func cmdPause(rule: MediaRule, context: [String: Any]) -> Bool {
        mediaContext?.enterPlaybackState(state: MediaContext.MediaPlaybackState.Pause)
        return true
    }

    private func cmdBufferStart(rule: MediaRule, context: [String: Any]) -> Bool {
        mediaContext?.enterPlaybackState(state: MediaContext.MediaPlaybackState.Buffer)
        return true
    }

    private func cmdBufferComplete(rule: MediaRule, context: [String: Any]) -> Bool {
        if mediaContext?.isInMediaPlaybackState(state: MediaContext.MediaPlaybackState.Buffer) ?? false {
            mediaContext?.exitPlaybackState(state: MediaContext.MediaPlaybackState.Buffer)
        }
        return true
    }

    private func cmdSeekStart(rule: MediaRule, context: [String: Any]) -> Bool {
        mediaContext?.enterPlaybackState(state: MediaContext.MediaPlaybackState.Seek)
        return true
    }

    private func cmdSeekComplete(rule: MediaRule, context: [String: Any]) -> Bool {
        if mediaContext?.isInMediaPlaybackState(state: MediaContext.MediaPlaybackState.Seek) ?? false {
            mediaContext?.exitPlaybackState(state: MediaContext.MediaPlaybackState.Seek)
        }
        return true
    }

    private func cmdStateStart(rule: MediaRule, context: [String: Any]) -> Bool {
        guard let stateInfo = StateInfo(info: context[Self.KEY_INFO] as? [String: Any]) else {
            return false
        }
        mediaContext?.startState(info: stateInfo)
        hitGenerator?.processStateStart(stateInfo: stateInfo)

        return true
    }

    private func cmdStateEnd(rule: MediaRule, context: [String: Any]) -> Bool {
        guard let stateInfo = StateInfo(info: context[Self.KEY_INFO] as? [String: Any]) else {
            return false
        }
        mediaContext?.endState(info: stateInfo)
        hitGenerator?.processStateEnd(stateInfo: stateInfo)

        return true
    }

    private func cmdQoEUpdate(rule: MediaRule, context: [String: Any]) -> Bool {
        if let qoeInfo = QoEInfo(info: context[Self.KEY_INFO] as? [String: Any]) {
            mediaContext?.qoeInfo = qoeInfo
            return true
        }
        return false
    }

    private func cmdPlayheadUpdate(rule: MediaRule, context: [String: Any]) -> Bool {
        if let playhead = getPlayhead(context: context) {
            mediaContext?.playhead = playhead
            return true
        }
        return false
    }

    /// Check the duration of current session and abort if active for more than 24 hours
    /// - Parameters:
    ///    - rule: EventName corresponding to API call
    ///    - context: Data passed with the corresponding API call
    @discardableResult
    private func cmdSessionTimeoutDetection(rule: MediaRule, context: [String: Any]) -> Bool {
        let refTS = getRefTS(context: context)

        if mediaSessionStartTS == Self.INVALID_TS {
            mediaSessionStartTS = refTS
        }

        if !trackerIdle && ((refTS - mediaSessionStartTS) >= Self.MEDIA_SESSION_TIMEOUT_MS) {
            hitGenerator?.processSessionAbort()
            hitGenerator?.processSessionRestart()

            mediaSessionStartTS = refTS
            contentStarted = false
            contentStartRefTS = Self.INVALID_TS
        }

        return true
    }

    /// Detect if the player is idle (not in play) and abort current session if idle for more than 30 minutes
    /// - Parameters:
    ///    - rule: EventName corresponding to API call
    ///    - context: Data passed with the corresponding API call
    @discardableResult
    private func cmdIdleDetection(rule: MediaRule, context: [String: Any]) -> Bool {
        guard let mediaContext = mediaContext else {
            return false
        }

        if mediaContext.isIdle() {
            let refTS = getRefTS(context: context)
            if mediaIdle {
                // Media was already idle during previous call.
                if !trackerIdle && (refTS - mediaIdleStartTS) >= Self.IDLE_TIMEOUT_MS {
                    // We stop trakcing if media has been idle for 30 mins.
                    hitGenerator?.processSessionAbort()
                    trackerIdle = true
                }
            } else {
                mediaIdle = true
                mediaIdleStartTS = refTS
            }
        } else {
            // Media is not currently idle.
            if trackerIdle {
                // We resume tracking if we have stopped tracking.
                hitGenerator?.processSessionRestart()
                trackerIdle = false
                // If media is idle, reset content started flag
                contentStarted = false
                contentStartRefTS = Self.INVALID_TS
                mediaSessionStartTS = Self.INVALID_TS
            }

            mediaIdle = false
        }

        return true
    }

    /// Handle content start (play) ping. Sends 1 play ping per session after detecting the first second of main content playback
    /// - Parameters:
    ///    - rule: EventName corresponding to API call
    ///    - context: Data passed with the corresponding API call
    @discardableResult
    private func cmdContentStartDetection(rule: MediaRule, context: [String: Any]) -> Bool {
        guard let mediaContext = mediaContext else {
            return false
        }

        if mediaContext.isIdle() || contentStarted {
            return true
        }

        if mediaContext.adBreakInfo != nil {
            // Reset the timer if in AdBreak and contentStart ping is not sent
            contentStartRefTS = Self.INVALID_TS
            return true
        }

        let refTS = getRefTS(context: context)
        if contentStartRefTS == Self.INVALID_TS {
            contentStartRefTS = refTS
        }

        if (refTS - contentStartRefTS) >= Self.CONTENT_START_DURATION_MS {
            hitGenerator?.processPlayback(doFlush: true)
            contentStarted = true
        }

        return true
    }

    // MARK: Preroll Rule Helpers

    // Remove the trackPlay calls before AdBreakStart for preroll ads to avoid incorrect content start on reporting side
    func prerollReorderRules(rules: [(name: RuleName, context: [String: Any])]) ->[(name: RuleName, context: [String: Any])] {
        var reorderedRules: [(name: RuleName, context: [String: Any])] = []
        var adBreakStart: (name: RuleName, context: [String: Any])?

        for rule in rules {
            if rule.name == RuleName.AdBreakStart {
                adBreakStart = rule
                break
            }
        }

        var dropPlay = adBreakStart != nil
        for rule in rules {
            if rule.name == RuleName.Play && dropPlay {
                continue
            }

            if dropPlay && rule.name == RuleName.AdBreakStart {
                dropPlay = false
            }

            reorderedRules.append(rule)
        }

        return reorderedRules
    }

    // Check if we need to wait for PrerollWaitTime for preroll ads before executing any track calls
    func prerollDeferRule(rule: RuleName, context: [String: Any]) -> Bool {
        guard  let mediaContext = mediaContext, inPrerollInterval else {
            return false
        }
        let prerollWaitingtime = Int64(mediaContext.mediaInfo.prerollWaitingTime)
        // We are going to queue the events and stop further downstream
        // processing for preroll_waiting_time ms.
        prerollQueuedRules.append((name: rule, context: context))

        let refTS = getRefTS(context: context)

        if (refTS - prerollRefTS) >= prerollWaitingtime ||
            rule == RuleName.AdBreakStart ||
            rule == RuleName.MediaComplete ||
            rule == RuleName.MediaSkip {

            // If preroll_waiting_time has elapsed or we get any of these rules
            // We start processing all the queued rules.
            let reorderedRules = prerollReorderRules(rules: prerollQueuedRules)

            for orderedRule in reorderedRules {
                processRule(rule: orderedRule.name, context: orderedRule.context)
            }

            prerollQueuedRules.removeAll()
            inPrerollInterval = false
        }

        return true
    }

    // MARK: Event Data Helpers
    private func cleanMetadata(data: [String: String]) -> [String: String] {
        var cleanData: [String: String] = [:]
        let pattern = ("^[a-zA-Z0-9_\\.]+$")
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return data
        }

        for (key, value) in data {
            let matches = regex.matches(in: key, options: [], range: NSRange(location: 0, length: key.count))
            if matches.isEmpty {
                Log.trace(label: Self.LOG_TAG, "CleanMetadata - Dropping metadata entry key:\"\(key)\" value:\"\(value)\". Key should contain only alphabets, digits, '_' and '.'.")
            } else {
                cleanData[key] = value
            }
        }

        return cleanData
    }

    func getMetadata(context: [String: Any]) -> [String: String] {
        guard let metadata = context[Self.KEY_METADATA] as? [String: String] else {
            return [:]
        }

        return metadata
    }

    func getError(context: [String: Any]) -> String? {
        guard let errorInfo = context[Self.KEY_INFO] as? [String: Any] else {
            return nil
        }

        guard let errorId = errorInfo[MediaConstants.ErrorInfo.ID] as? String else {
            return nil
        }

        return errorId
    }

    func getPlayhead(context: [String: Any]) -> Double? {
        guard let playheadInfo = context[Self.KEY_INFO] as? [String: Any] else {
            return nil
        }

        guard let playhead = playheadInfo[MediaConstants.Tracker.PLAYHEAD] as? Double else {
            return nil
        }

        return playhead
    }

    func getRefTS(context: [String: Any]) -> Int64 {
        guard let ts = context[Self.KEY_EVENT_TS] as? Int64 else {
            return 0
        }

        return ts
    }
}
