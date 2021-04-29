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
    private static let LOG_TAG = MediaConstants.LOG_TAG
    private static let CLASS_NAME = "Media"

    /// Creates an instance of `MediaTracker` used for calling track APIs.
    @objc(createTracker)
    static func createTracker() -> MediaTracker {
        return createTrackerWith(config: nil)
    }

    /// Creates an instance of `MediaTracker`  used for calling track APIs.
    /// - Parameter:
    ///   - config: The configuration for `MediaTracker` instance.
    @objc(createTrackerWithConfig:)
    static func createTrackerWith(config: [String: Any]?) -> MediaTracker {
        return MediaPublicTracker(dispatch: MobileCore.dispatch(event:), config: config)
    }

    /// Creates an instance of `MediaInfo` to be used with `trackSessionStart` API.
    /// - Parameter:
    ///   - name: The name of the media.
    ///   - id: The unqiue identifier for the media.
    ///   - length: The length of the media in seconds.
    ///   - streamType: The stream type as a string. Use the pre-defined constants for vod, live, and linear content.
    ///   - mediaType: The media type of the stream. Use `MediaType` enum which can be either `MediaType.Video` or `MediaType.Audio`.
    @objc(createMediaObjectWith:id:length:streamType:mediaType:)
    static func createMediaObjectWith(name: String, id: String, length: Double, streamType: String, mediaType: MediaType) -> [String: Any]? {
        guard let mediaInfo = MediaInfo(id: id, name: name, streamType: streamType, mediaType: mediaType, length: length) else {
            Log.error(label: LOG_TAG, "[\(Self.CLASS_NAME)<\(#function)>] - Error creating media Object")
            return nil
        }

        return mediaInfo.toMap()
    }

    /// Creates an instance of `AdBreakInfo` to be used with `trackEvent(AdBreakStart)` API.
    /// - Parameter:
    ///   - name: The name of the ad break.
    ///   - position: The position of the ad break in the content starting with `1`.
    ///   - startTime: The start time of the ad break relative to the main media in seconds.
    @objc(createAdBreakObjectWith:position:startTime:)
    static func createAdBreakObjectWith(name: String, position: Int, startTime: Double) -> [String: Any]? {
        guard let adBreakInfo = AdBreakInfo(name: name, position: position, startTime: startTime) else {
            Log.error(label: LOG_TAG, "[\(Self.CLASS_NAME)<\(#function)>] - Error creating adBreak Object")
            return nil
        }
        return adBreakInfo.toMap()
    }

    /// Creates an instance of `AdInfo` to be used with `trackEvent(AdStart)` API.
    /// - Parameter:
    ///   - name: The name of the ad.
    ///   - id: The unqiue identifier for the ad.
    ///   - position: The position of the ad in the ad break starting with `1`.
    ///   - length: The length of the ad in seconds.
    @objc(createAdObjectWith:id:position:length:)
    static func createAdObjectWith(name: String, id: String, position: Int, length: Double) -> [String: Any]? {
        guard let adInfo = AdInfo(id: id, name: name, position: position, length: length) else {
            Log.error(label: LOG_TAG, "[\(Self.CLASS_NAME)<\(#function)>] - Error creating ad Object")
            return nil
        }
        return adInfo.toMap()
    }

    /// Creates an instance of `ChapterInfo` to be used with `trackEvent(ChapterStart)` API.
    /// - Parameter:
    ///   - name: The name of the chapter.
    ///   - position: The position of the chapter in the content starting with `1`.
    ///   - length: The length of the chapter in seconds.
    ///   - startTime: The start time of the chapter relative to the main media in seconds.
    @objc(createChapterObjectWith:position:length:startTime:)
    static func createChapterObjectWith(name: String, position: Int, length: Double, startTime: Double) -> [String: Any]? {
        guard let chapterInfo = ChapterInfo(name: name, position: position, startTime: startTime, length: length) else {
            Log.error(label: LOG_TAG, "[\(Self.CLASS_NAME)<\(#function)>] - Error creating chapter Object")
            return nil
        }
        return chapterInfo.toMap()
    }

    /// Creates an instance of `QoEInfo` to be used with `updateQoEObject` API.
    /// - Parameter:
    ///   - bitrate: The bitrate of media in bits per second.
    ///   - startupTime:  The start up time of media in seconds.
    ///   - fps: The current frames per second information.
    ///   - droppedFrames: The number of dropped frames so far.
    @objc(createQoEObjectWith:startTime:fps:droppedFrames:)
    static func createQoEObjectWith(bitrate: Double, startupTime: Double, fps: Double, droppedFrames: Double) -> [String: Any]? {
        guard let qoeInfo = QoEInfo(bitrate: bitrate, droppedFrames: droppedFrames, fps: fps, startupTime: startupTime) else {
            Log.error(label: LOG_TAG, "[\(Self.CLASS_NAME)<\(#function)>] - Error creating qoe Object")
            return nil
        }
        return qoeInfo.toMap()
    }

    /// Creates an instance of `StateInfo` to be used with trackEvent(StateStart) and trackEvent(StateEnd) API.
    /// - Parameter:
    ///   - stateName: The name of the custom state to track. Use the pre-defined constants for fullscreen, pictureInPicture, closedCaptioning, inFocus and mute.
    @objc(createStateObjectWith:)
    static func createStateObjectWith(stateName: String) -> [String: Any]? {
        guard let stateInfo = StateInfo(stateName: stateName) else {
            Log.error(label: LOG_TAG, "[\(Self.CLASS_NAME)<\(#function)>] - Error creating state Object")
            return nil
        }
        return stateInfo.toMap()
    }
}

@objc(AEPMediaEvent)
public enum MediaEvent: Int, RawRepresentable {
    case AdBreakStart
    case AdBreakComplete
    case AdStart
    case AdComplete
    case AdSkip
    case ChapterStart
    case ChapterComplete
    case ChapterSkip
    case SeekStart
    case SeekComplete
    case BufferStart
    case BufferComplete
    case BitrateChange
    case StateStart
    case StateEnd

    public typealias RawValue = String

    public var rawValue: RawValue {
        switch self {
        case .AdBreakStart: return MediaConstants.EventName.ADBREAK_START
        case .AdBreakComplete: return MediaConstants.EventName.ADBREAK_COMPLETE
        case .AdStart: return MediaConstants.EventName.AD_START
        case .AdComplete: return MediaConstants.EventName.AD_COMPLETE
        case .AdSkip: return MediaConstants.EventName.AD_SKIP
        case .ChapterStart: return MediaConstants.EventName.CHAPTER_START
        case .ChapterComplete: return MediaConstants.EventName.CHAPTER_COMPLETE
        case .ChapterSkip: return MediaConstants.EventName.CHAPTER_SKIP
        case .SeekStart: return MediaConstants.EventName.SEEK_START
        case .SeekComplete: return MediaConstants.EventName.SEEK_COMPLETE
        case .BufferStart: return MediaConstants.EventName.BUFFER_START
        case .BufferComplete: return MediaConstants.EventName.BUFFER_COMPLETE
        case .BitrateChange: return MediaConstants.EventName.BITRATE_CHANGE
        case .StateStart: return MediaConstants.EventName.STATE_START
        case .StateEnd: return MediaConstants.EventName.STATE_END
        }
    }

    public init?(rawValue: RawValue) {
        switch rawValue {
        case MediaConstants.EventName.ADBREAK_START:
            self = .AdBreakStart
        case MediaConstants.EventName.ADBREAK_COMPLETE:
            self = .AdBreakComplete
        case MediaConstants.EventName.AD_START:
            self = .AdStart
        case MediaConstants.EventName.AD_COMPLETE:
            self = .AdComplete
        case MediaConstants.EventName.AD_SKIP:
            self = .AdSkip
        case MediaConstants.EventName.CHAPTER_START:
            self = .ChapterStart
        case MediaConstants.EventName.CHAPTER_COMPLETE:
            self = .ChapterComplete
        case MediaConstants.EventName.CHAPTER_SKIP:
            self = .ChapterSkip
        case MediaConstants.EventName.SEEK_START:
            self = .SeekStart
        case MediaConstants.EventName.SEEK_COMPLETE:
            self = .SeekComplete
        case MediaConstants.EventName.BUFFER_START:
            self = .BufferStart
        case MediaConstants.EventName.BUFFER_COMPLETE:
            self = .BufferComplete
        case MediaConstants.EventName.BITRATE_CHANGE:
            self = .BitrateChange
        case MediaConstants.EventName.STATE_START:
            self = .StateStart
        case MediaConstants.EventName.STATE_END:
            self = .StateEnd

        default:
            return nil
        }
    }
}
