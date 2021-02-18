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

class MediaContext {
    let LOG_TAG = "MediaContext"

    // TODO: stub
    func getMediaInfo() -> [String: Any] {
        return [:]
    }
    
    // TODO: stub
    func getMediaMetadata() -> [String: Any] {
        return [:]
    }
    
    // TODO: stub
    func getPlayhead() -> Double {
        return 1234567890
    }
    
    // TODO: stub
    func isInChapter() -> Bool {
        return true
    }
    
    // TODO: stub
    func isInAdBreak() -> Bool {
        return true
    }
    
    // TODO: stub
    func isInAd() -> Bool {
        return true
    }
    
    // TODO: stub
    func getActiveTrackedStates() -> [StateInfo] {
        return []
    }
    
    // TODO: stub
    func isInState(_ state: MediaPlaybackState) -> Bool {
        var retVal = false
        
        return retVal
    }
}
