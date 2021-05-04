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

class ChapterInfo: Equatable {
    private static let LOG_TAG = MediaConstants.LOG_TAG
    private static let CLASS_NAME = "ChapterInfo"
    let name: String
    let position: Int
    let startTime: Double
    let length: Double

    static func == (lhs: ChapterInfo, rhs: ChapterInfo) -> Bool {
        return  lhs.name == rhs.name &&
            lhs.position == rhs.position &&
            lhs.startTime.isAlmostEqual(rhs.startTime) &&
            lhs.length.isAlmostEqual(rhs.length)
    }

    init?(name: String, position: Int, startTime: Double, length: Double) {

        guard !name.isEmpty else {
            Log.debug(label: Self.LOG_TAG, "[\(Self.CLASS_NAME)<\(#function)>] - Error creating ChapterInfo, name must not be empty")
            return nil
        }

        guard position >= 1 else {
            Log.debug(label: Self.LOG_TAG, "[\(Self.CLASS_NAME)<\(#function)>] - Error creating AdBreakInfo, position must be greater than zero")
            return nil
        }

        guard startTime >= 0 else {
            Log.debug(label: Self.LOG_TAG, "[\(Self.CLASS_NAME)<\(#function)>] - Error creating ChapterInfo, start time must not be less than zero")
            return nil
        }

        guard length >= 0 else {
            Log.debug(label: Self.LOG_TAG, "[\(Self.CLASS_NAME)<\(#function)>] - Error creating ChapterInfo, length must not be less than zero")
            return nil
        }

        self.name = name
        self.position = position
        self.startTime = startTime
        self.length = length
    }

    convenience init?(info: [String: Any]?) {
        guard info != nil else {
            return nil
        }

        guard let name = info?[MediaConstants.ChapterInfo.NAME] as? String else {
            Log.debug(label: Self.LOG_TAG, "[\(Self.CLASS_NAME)<\(#function)>] - Error parsing ChapterInfo, invalid name")
            return nil
        }

        guard let position = info?[MediaConstants.ChapterInfo.POSITION] as? Int else {
            Log.debug(label: Self.LOG_TAG, "[\(Self.CLASS_NAME)<\(#function)>] - Error parsing ChapterInfo, invalid position")
            return nil
        }

        guard let startTime = info?[MediaConstants.ChapterInfo.START_TIME] as? Double else {
            Log.debug(label: Self.LOG_TAG, "[\(Self.CLASS_NAME)<\(#function)>] - Error parsing ChapterInfo, invalid start time")
            return nil
        }

        guard let length = info?[MediaConstants.ChapterInfo.LENGTH] as? Double else {
            Log.debug(label: Self.LOG_TAG, "[\(Self.CLASS_NAME)<\(#function)>] - Error parsing ChapterInfo, invalid length")
            return nil
        }

        self.init(name: name, position: position, startTime: startTime, length: length)
    }

    func toMap() -> [String: Any] {
        var chapterInfoMap: [String: Any] = [:]
        chapterInfoMap[MediaConstants.ChapterInfo.NAME] = self.name
        chapterInfoMap[MediaConstants.ChapterInfo.POSITION] = self.position
        chapterInfoMap[MediaConstants.ChapterInfo.START_TIME] = self.startTime
        chapterInfoMap[MediaConstants.ChapterInfo.LENGTH] = self.length

        return chapterInfoMap
    }
}
