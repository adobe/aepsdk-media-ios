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

class StateInfo: Equatable {
    private static let LOG_TAG = MediaConstants.LOG_TAG
    private static let CLASS_NAME = "StateInfo"
    let stateName: String

    static func == (lhs: StateInfo, rhs: StateInfo) -> Bool {
        return  lhs.stateName == rhs.stateName
    }

    init?(stateName: String) {
        guard !stateName.isEmpty else {
            Log.debug(label: Self.LOG_TAG, "[\(Self.CLASS_NAME)<\(#function)>] - Error creating StateInfo, state name cannot be empty")
            return nil
        }
        let pattern = "^[a-zA-Z0-9_\\.]{1,64}$"
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let matches = regex.matches(in: stateName, options: [], range: NSRange(location: 0, length: stateName.count))
            if matches.isEmpty {
                Log.debug(label: Self.LOG_TAG, "[\(Self.CLASS_NAME)<\(#function)>] - Error creating StateInfo, state name: \(stateName) with length: \(stateName.count)  cannot contain special characters and can only be 64 character long. Only alphabets, digits, '_' and '.' are allowed.")
                return nil
            }
        } catch {
            Log.debug(label: Self.LOG_TAG, "[\(Self.CLASS_NAME)<\(#function)>] - Invalid regex pattern")
        }

        self.stateName = stateName
    }

    convenience init?(info: [String: Any]?) {
        guard info != nil else {
            return nil
        }

        guard let stateName = info?[MediaConstants.StateInfo.STATE_NAME_KEY] as? String else {
            Log.debug(label: Self.LOG_TAG, "[\(Self.CLASS_NAME)<\(#function)>] - Error parsing StateInfo, no state name")
            return nil
        }

        self.init(stateName: stateName)
    }

    func toMap() -> [String: Any]? {
        var stateInfoMap: [String: Any] = [:]
        stateInfoMap[MediaConstants.StateInfo.STATE_NAME_KEY] = self.stateName

        return stateInfoMap
    }
}
