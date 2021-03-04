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
        return createTrackerWith(config: nil)
    }

    @objc(createTrackerWithConfig:)
    static func createTrackerWith(config: [String: Any]?) -> MediaTracker {
        return MediaPublicTracker(dispatch: MobileCore.dispatch(event:), config: config)
    }

    @objc(createMediaObjectWith:id:length:streamType:mediaType:)
    static func createMediaObjectWith(name: String, id: String, length: Double, streamType: String, mediaType: MediaType) -> [String: Any]? {
        guard let mediaInfo = MediaInfo(id: id, name: name, streamType: streamType, mediaType: mediaType, length: length) else {
            Log.error(label: LOG_TAG, "\(#function) Error creating media Object")
            return nil
        }

        return mediaInfo.toMap()
    }

    @objc(createAdBreakObjectWith:position:startTime:)
    static func createAdBreakObjectWith(name: String, position: Int, startTime: Double) -> [String: Any]? {
        guard let adBreakInfo = AdBreakInfo(name: name, position: position, startTime: startTime) else {
            Log.error(label: LOG_TAG, "\(#function) Error creating adBreak Object")
            return nil
        }
        return adBreakInfo.toMap()
    }

    @objc(createAdObjectWith:id:position:length:)
    static func createAdObjectWith(name: String, adId: String, position: Int, length: Double) -> [String: Any]? {
        guard let adInfo = AdInfo(id: adId, name: name, position: position, length: length) else {
            Log.error(label: LOG_TAG, "\(#function) Error creating ad Object")
            return nil
        }
        return adInfo.toMap()
    }

    @objc(createChapterObjectWith:position:length:startTime:)
    static func createChapterObjectWith(name: String, position: Int, length: Double, startTime: Double) -> [String: Any]? {
        guard let chapterInfo = ChapterInfo(name: name, position: position, startTime: startTime, length: length) else {
            Log.error(label: LOG_TAG, "\(#function) Error creating chapter Object")
            return nil
        }
        return chapterInfo.toMap()
    }

    @objc(createQoEObjectWith:startTime:fps:droppedFrames:)
    static func createQoEObjectWith(bitrate: Double, startupTime: Double, fps: Double, droppedFrames: Double) -> [String: Any]? {
        guard let qoeInfo = QoEInfo(bitrate: bitrate, droppedFrames: droppedFrames, fps: fps, startupTime: startupTime) else {
            Log.error(label: LOG_TAG, "\(#function) Error creating qoe Object")
            return nil
        }
        return qoeInfo.toMap()
    }

    @objc(createStateObjectWith:)
    static func createStateObjectWith(stateName: String) -> [String: Any]? {
        guard let stateInfo = StateInfo(stateName: stateName) else {
            Log.error(label: LOG_TAG, "\(#function) Error creating state Object")
            return nil
        }
        return stateInfo.toMap()
    }
}

@objc public enum AEPMediaEvent: Int {
    case AEPMediaEventAdBreakStart
    case AEPMediaEventAdBreakComplete
    case AEPMediaEventAdStart
    case AEPMediaEventAdComplete
    case AEPMediaEventAdSkip
    case AEPMediaEventChapterStart
    case AEPMediaEventChapterComplete
    case AEPMediaEventChapterSkip
    case AEPMediaEventSeekStart
    case AEPMediaEventSeekComplete
    case AEPMediaEventBufferStart
    case AEPMediaEventBufferComplete
    case AEPMediaEventBitrateChange
    case AEPMediaEventStateStart
    case AEPMediaEventStateEnd

    func stringValue() -> String {
        switch self {
        case .AEPMediaEventAdBreakStart: return MediaConstants.EventName.ADBREAK_START
        case .AEPMediaEventAdBreakComplete: return MediaConstants.EventName.ADBREAK_COMPLETE
        case .AEPMediaEventAdStart: return MediaConstants.EventName.AD_START
        case .AEPMediaEventAdComplete: return MediaConstants.EventName.AD_COMPLETE
        case .AEPMediaEventAdSkip: return MediaConstants.EventName.AD_SKIP
        case .AEPMediaEventChapterStart: return MediaConstants.EventName.CHAPTER_START
        case .AEPMediaEventChapterComplete: return MediaConstants.EventName.CHAPTER_COMPLETE
        case .AEPMediaEventChapterSkip: return MediaConstants.EventName.CHAPTER_SKIP
        case .AEPMediaEventSeekStart: return MediaConstants.EventName.SEEK_START
        case .AEPMediaEventSeekComplete: return MediaConstants.EventName.SEEK_COMPLETE
        case .AEPMediaEventBufferStart: return MediaConstants.EventName.BUFFER_START
        case .AEPMediaEventBufferComplete: return MediaConstants.EventName.BUFFER_COMPLETE
        case .AEPMediaEventBitrateChange: return MediaConstants.EventName.BITRATE_CHANGE
        case .AEPMediaEventStateStart: return MediaConstants.EventName.STATE_START
        case .AEPMediaEventStateEnd: return MediaConstants.EventName.STATE_END
        }
    }
}
