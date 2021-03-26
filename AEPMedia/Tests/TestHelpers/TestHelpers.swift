/*
 Copyright 2020 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0
 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

import XCTest
@testable import AEPCore
@testable import AEPMedia

extension EventHub {
    static func reset() {
        shared = EventHub()
    }
}

extension MediaHit: Equatable {
    private static let emptyDict: [String: Any] = [:]

    public static func == (lhs: MediaHit, rhs: MediaHit) -> Bool {
        return lhs.eventType == rhs.eventType &&
            areDictionariesEqual(lhs: lhs.params, rhs: rhs.params) &&
            areDictionariesEqual(lhs: lhs.metadata, rhs: rhs.metadata) &&
            areDictionariesEqual(lhs: lhs.qoeData, rhs: rhs.qoeData) &&
            lhs.playhead.isAlmostEqual(rhs.playhead) &&
            lhs.timestamp.isAlmostEqual(rhs.timestamp)
    }

    private static func areDictionariesEqual(lhs: [String: Any]?, rhs: [String: Any]?) -> Bool {
        // two nil dictionaries
        if lhs == nil && rhs == nil {
            return true
            // lhs is nil, rhs is not nil
        } else if lhs == nil && rhs != nil {
            return NSDictionary(dictionary: emptyDict).isEqual(to: rhs ?? emptyDict)
            // lhs is not nil, rhs is nil
        } else if lhs != nil && rhs == nil {
            return NSDictionary(dictionary: lhs ?? emptyDict).isEqual(to: emptyDict)
        }
        // two empty dictionaries or two identical dictionaries
        return NSDictionary(dictionary: lhs ?? emptyDict).isEqual(to: rhs ?? emptyDict)
    }
}
