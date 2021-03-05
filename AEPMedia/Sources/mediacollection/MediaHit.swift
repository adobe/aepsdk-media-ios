/*
 Copyright 2021 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0
 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES  REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

import Foundation

struct MediaHit {
    let eventType: String
    let playhead: Double
    let ts: TimeInterval
    let params: [String: Any]?
    let customMetada: [String: String]?
    let qoeData: [String: Any]?
    
    init(eventType: String, params: [String: Any]? = nil, customMetada: [String: String]? = nil, qoeData: [String: Any]? = nil, playhead: Double, ts: TimeInterval) {
        self.eventType = eventType
        self.playhead = playhead
        self.ts = ts
        self.params = params
        self.customMetada = customMetada
        self.qoeData = qoeData
    }
}
