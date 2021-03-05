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

// TODO: replace with final implementation
enum MediaPlaybackState {
    case Init // First play / pause has not happened
    case Play
    case Pause
    case Buffer
    case Seek
    case Stall
}

// TODO: replace with final implementation
class MediaContext {
    private var mediaInfo: MediaInfo
    private var chapterInfo: ChapterInfo?
    private var adInfo: AdInfo?
    private var adBreakInfo: AdBreakInfo?
    private var qoeInfo: QoEInfo?
    private var metadata: [String: String]?
    private var adMetadata: [String: String]?
    private var chapterMetadata: [String: String]?
    private var playState: MediaPlaybackState?
    private var states: [String: Bool] = [:]
    private var buffering = false
    private var seeking = false
    
    init(mediaInfo: MediaInfo, metadata: [String: String]) {
        self.mediaInfo = mediaInfo
        self.metadata = metadata
    }
    
    let LOG_TAG = "MediaContext"

    func getMediaInfo() -> MediaInfo {
        return mediaInfo
    }
    
    func getMediaMetadata() -> [String: String] {
        return metadata ?? [:]
    }
    
    func getPlayhead() -> Double {
        return 50
    }
    
    func isInChapter() -> Bool {
        return chapterInfo != nil
    }
    
    func isInAdBreak() -> Bool {
        return adBreakInfo != nil
    }
    
    func isInAd() -> Bool {
        return adInfo != nil
    }
    
    func setAdInfo(adInfo: AdInfo?, metadata: [String: String]?) {
        if adInfo != nil {
            self.adInfo = adInfo
        }

        if metadata != nil {
            self.adMetadata = metadata
        }
    }

    func setAdBreakInfo(adBreakInfo: AdBreakInfo?) {
        if adBreakInfo != nil {
            self.adBreakInfo = adBreakInfo
        }
    }

    func setChapterInfo(chapterInfo: ChapterInfo?, metadata: [String: String]?) {
        if chapterInfo != nil {
            self.chapterInfo = chapterInfo
        }

        if metadata != nil {
            self.chapterMetadata = metadata
        }
    }

    func setQoeInfo(qoeInfo: QoEInfo?) {
        self.qoeInfo = qoeInfo
    }
    
    func getQoeInfo() -> QoEInfo? {
        return self.qoeInfo
    }
    
    func getActiveTrackedStates() -> [StateInfo] {
        var activeStates: [StateInfo] = []
        
        for state in states {
            if let activeState = StateInfo(stateName: state.key) {
                activeStates.append(activeState)
            }
        }
        
        return activeStates
    }
    
    func isInState(_ state: StateInfo) -> Bool {
        return states[state.stateName] != nil ? true : false
    }
    
    func isInState(_ state: MediaPlaybackState) -> Bool {
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
    
    func enterState(_ state: MediaPlaybackState) {
        switch state {
        case .Play, .Pause, .Stall:
            playState = state
        case .Buffer:
            buffering = true
        case .Seek:
            seeking = true
        default:
            Log.debug(label: LOG_TAG, "\(#function) - Invalid state passed to enterState: \(state)")
        }
    }
    
    func exitState(_ state: MediaPlaybackState) {
        switch state {
        case .Buffer:
            buffering = false
        case .Seek:
            seeking = false
        default:
            break
        }
    }
    
    func startState(_ stateInfo: StateInfo?) -> Bool {
        // TODO: check if (!hasTrackedState(stateInfo) && hasReachedStateLimit()) { then return false
        guard let stateInfo = stateInfo else {
            Log.debug(label: LOG_TAG, "\(#function) - Unable to start state, received nil StateInfo")
            return false
        }
        
        if isInState(stateInfo) {
            Log.debug(label: LOG_TAG, "\(#function) - Unable to start state, state \(stateInfo.stateName) already started")
            return false
        }
        
        Log.trace(label: LOG_TAG, "\(#function) - Starting state \(stateInfo.stateName)")
        states[stateInfo.stateName] = true
        return true
    }
    
    func endState(_ stateInfo: StateInfo?) -> Bool {
        guard let stateInfo = stateInfo else {
            Log.debug(label: LOG_TAG, "\(#function) - Unable to end state, received nil StateInfo")
            return false
        }
        
        if !isInState(stateInfo) {
            Log.debug(label: LOG_TAG, "\(#function) - Unable to end state, state \(stateInfo.stateName) has not been started")
            return false
        }
        
        Log.trace(label: LOG_TAG, "\(#function) - Ending state \(stateInfo.stateName)")
        states[stateInfo.stateName] = false
        return true
    }
}
