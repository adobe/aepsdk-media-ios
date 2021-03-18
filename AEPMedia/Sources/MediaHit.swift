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

struct MediaHit: Codable {
    /// Media Analytics Tracking Event Type
    private (set) var eventType: String

    /// Media Analytics parameters
    private (set) var params: [String: Any]?

    /// Media Analytics metadata
    private (set) var metadata: [String: String]?

    /// Media Analytics QoE data
    private (set) var qoeData: [String: Any]?

    /// The current playhead
    private (set) var playhead: Double = 0

    /// The current timestamp
    private (set) var timestamp: TimeInterval
    
    enum CodingKeys: String, CodingKey {
        case eventType
        case params
        case metadata
        case qoeData
        case playhead
        case timestamp
    }

    init(eventType: String, playhead: Double, ts: TimeInterval, params: [String: Any]? = nil, customMetadata: [String: String]? = nil, qoeData: [String: Any]? = nil) {
        self.eventType = eventType
        self.params = params
        self.metadata = customMetadata
        self.qoeData = qoeData
        self.playhead = playhead
        self.timestamp = ts
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.eventType = try values.decode(String.self, forKey: .eventType)
        self.params = try values.decode([String: AnyCodable].self, forKey: .params)
        self.metadata = try values.decode([String: String].self, forKey: .metadata)
        self.qoeData = try values.decode([String: AnyCodable].self, forKey: .qoeData)
        self.playhead = try values.decode(Double.self, forKey: .playhead)
        self.timestamp = try values.decode(Double.self, forKey: .timestamp)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(eventType, forKey: .eventType)
        try container.encode(AnyCodable.from(dictionary: params), forKey: .params)
        try container.encode(metadata, forKey: .metadata)
        try container.encode(AnyCodable.from(dictionary: qoeData), forKey: .qoeData)
        try container.encode(playhead, forKey: .playhead)
        try container.encode(timestamp, forKey: .timestamp)
    }
}
