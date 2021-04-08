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

import AEPServices

class AdInfo: Equatable {
    private static let LOG_TAG = "AdInfo"
    let id: String
    let name: String
    let position: Int
    let length: Double

    static func == (lhs: AdInfo, rhs: AdInfo) -> Bool {
        return  lhs.id == rhs.id &&
            lhs.name == rhs.name &&
            lhs.position == rhs.position &&
            lhs.length.isAlmostEqual(rhs.length)
    }

    init?(id: String, name: String, position: Int, length: Double) {

        guard !id.isEmpty else {
            Log.debug(label: Self.LOG_TAG, "\(#function) - Error creating AdInfo, id must not be Empty")
            return nil
        }

        guard !name.isEmpty else {
            Log.debug(label: Self.LOG_TAG, "\(#function) - Error creating AdInfo, name must not be Empty")
            return nil
        }

        guard position >= 1 else {
            Log.debug(label: Self.LOG_TAG, "\(#function) - Error creating AdBreakInfo, position must be greater than zero")
            return nil
        }

        guard length >= 0 else {
            Log.debug(label: Self.LOG_TAG, "\(#function) - Error creating AdInfo, start time must not be less than zero")
            return nil
        }

        self.id = id
        self.name = name
        self.position = position
        self.length = length
    }

    convenience init?(info: [String: Any]?) {
        guard info != nil else {
            return nil
        }

        guard let id = info?[MediaConstants.AdInfo.ID] as? String else {
            Log.debug(label: Self.LOG_TAG, "\(#function) - Error parsing AdInfo, invalid id")
            return nil
        }

        guard let name = info?[MediaConstants.AdInfo.NAME] as? String else {
            Log.debug(label: Self.LOG_TAG, "\(#function) - Error parsing AdInfo, invalid name")
            return nil
        }

        guard let position = info?[MediaConstants.AdInfo.POSITION] as? Int else {
            Log.debug(label: Self.LOG_TAG, "\(#function) - Error parsing AdInfo, invalid position")
            return nil
        }

        guard let length = info?[MediaConstants.AdInfo.LENGTH] as? Double else {
            Log.debug(label: Self.LOG_TAG, "\(#function) - Error parsing AdInfo, invalid length")
            return nil
        }

        self.init(id: id, name: name, position: position, length: length)
    }

    func toMap() -> [String: Any] {
        var adInfoMap: [String: Any] = [:]
        adInfoMap[MediaConstants.AdInfo.ID] = self.id
        adInfoMap[MediaConstants.AdInfo.NAME] = self.name
        adInfoMap[MediaConstants.AdInfo.POSITION] = self.position
        adInfoMap[MediaConstants.AdInfo.LENGTH] = self.length

        return adInfoMap
    }
}
