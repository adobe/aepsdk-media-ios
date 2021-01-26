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
import AEPCore
import AEPServices

/// Defines the public interface for the Media extension
@objc public extension Media {
    private static let LOG_TAG = "Media"

    @objc(createTracker)
    static func createTracker() -> MediaTracker {
        //TODO
        return MediaTracker()
    }

    @objc(createTrackerWithConfig:)
    static func createTrackerWith(config: [String: Any]?) -> MediaTracker {
        //TODO
        return MediaTracker()
    }

    @objc(createMediaObjectWith:id:length:streamType:mediaType:)
    static func createMediaObjectWith(name: String, id: String, length: Double, streamType: String, mediaType: (String)) -> [String: Any]? {
        //TODO
        return [:]
    }

    @objc(createAdBreakObjectWith:position:startTime:)
    static func createAdBreakObjectWith(name: String, position: Double, startTime: Double) -> [String: Any]? {
        //TODO
        return [:]
    }

    @objc(createAdObjectWith:id:positon:length:)
    static func createAdObjectWith(name: String, id: String, position: Double, length: Double) -> [String: Any]? {
        //TODO
        return [:]
    }

    @objc(createChapterObjectWith:position:length:startTime:)
    static func createChapterObjectWith(name: String, position: Double, length: Double, startTime: Double) -> [String: Any]? {
        //TODO
        return [:]
    }

    @objc(createQoEObjectWith:startTime:fps:droppedFrames:)
    static func createQoEObjectWith(bitrate: Double, startTime: Double, fps: Double, droppedFrames: Double) -> [String: Any]? {
        //TODO
        return [:]
    }

    @objc(createStateObjectWith:)
    static func createStateObjectWith(stateName: String) -> [String: Any]? {
        //TODO
        return [:]
    }

}
