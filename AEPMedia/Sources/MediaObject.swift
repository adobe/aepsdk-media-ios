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

@objc public enum MediaType: Int {
    case Audio
    case Video

    func stringValue() -> String {
        switch self {
        case .Audio: return "audio"
        case .Video: return "video"
        }
    }
}

class MediaInfo: Equatable {
    static let LOG_TAG = "MediaInfo"
    static let MEDIA_TYPE_AUDIO = "audio"
    static let MEDIA_TYPE_VIDEO = "video"
    static let DEFAULT_PREROLL_WAITING_TIME_IN_MS: Double = 250.0 //250 milliseconds
    private var id: String
    private var name: String
    private var streamType: String
    private var mediaType: MediaType
    private var length: Double
    private var resumed: Bool
    private var prerollWaitingTime: TimeInterval
    private var granularAdTracking: Bool

    static func == (lhs: MediaInfo, rhs: MediaInfo) -> Bool {
        return  lhs.id == rhs.id &&
            lhs.name == rhs.name &&
            lhs.streamType == rhs.streamType &&
            lhs.mediaType == rhs.mediaType &&
            lhs.length == rhs.length &&
            lhs.resumed == rhs.resumed &&
            lhs.prerollWaitingTime == rhs.prerollWaitingTime &&
            lhs.granularAdTracking == rhs.granularAdTracking
    }

    private init(id: String, name: String, streamType: String, mediaType: MediaType, length: Double, resumed: Bool, prerollWaitingTime: TimeInterval, granularAdTracking: Bool) {
        self.id = id
        self.name = name
        self.streamType = streamType
        self.mediaType = mediaType
        self.length = length
        self.resumed = resumed
        self.prerollWaitingTime = prerollWaitingTime
        self.granularAdTracking = granularAdTracking
    }

    static func createFrom(info: [String: Any]?) -> MediaInfo? {
        guard info != nil else {
            return nil
        }

        guard let id = info?[MediaConstants.MediaInfo.ID] as? String else {
            Log.debug(label: LOG_TAG, "\(#function) - Error parsing MediaInfo, invalid id")
            return nil
        }

        guard let name = info?[MediaConstants.MediaInfo.NAME] as? String else {
            Log.debug(label: LOG_TAG, "\(#function) - Error parsing MediaInfo, invalid name")
            return nil
        }

        guard let streamType = info?[MediaConstants.MediaInfo.STREAM_TYPE] as? String else {
            Log.debug(label: LOG_TAG, "\(#function) - Error parsing MediaInfo, invalid stream type. Sample values -> {\"VOD\", \"LIVE\" ...}")
            return nil
        }

        guard let mediaTypeString = info?[MediaConstants.MediaInfo.MEDIA_TYPE] as? String else {
            Log.debug(label: LOG_TAG, "\(#function) - Error parsing MediaInfo, invalid media type. Valid values -> {\"video\", \"audio\"}")
            return nil
        }

        var mediaType: MediaType
        if mediaTypeString == MediaType.Audio.stringValue() {
            mediaType = MediaType.Audio
        } else if mediaTypeString == MediaType.Video.stringValue() {
            mediaType = MediaType.Video
        } else {
            Log.debug(label: LOG_TAG, "\(#function) - Error parsing MediaInfo, invalid media type")
            return nil
        }

        guard let length = info?[MediaConstants.MediaInfo.LENGTH] as? Double else {
            Log.debug(label: LOG_TAG, "\(#function) - Error parsing MediaInfo, invalid length")
            return nil
        }

        let resumed = info?[MediaConstants.MediaInfo.RESUMED] as? Bool ?? false

        let prerollWaitTimeVal: Double = info?[MediaConstants.MediaInfo.PREROLL_TRACKING_WAITING_TIME] as? Double ?? DEFAULT_PREROLL_WAITING_TIME_IN_MS

        let prerollWaitingTime: TimeInterval = TimeInterval(prerollWaitTimeVal)

        let granularAdTracking = info?[MediaConstants.MediaInfo.GRANULAR_AD_TRACKING] as? Bool ?? false

        let mediaInfo = create(id: id, name: name, streamType: streamType, mediaType: mediaType, length: length, resumed: resumed, prerollWaitingTime: prerollWaitingTime, granularAdTracking: granularAdTracking)

        return mediaInfo
    }

    static func create(id: String, name: String, streamType: String, mediaType: MediaType = MediaType.Video, length: Double, resumed: Bool = false, prerollWaitingTime: TimeInterval = DEFAULT_PREROLL_WAITING_TIME_IN_MS, granularAdTracking: Bool = false) -> MediaInfo? {

        guard !id.isEmpty else {
            Log.debug(label: LOG_TAG, "\(#function) - Error creating MediaInfo, id must not be Empty")
            return nil
        }

        guard !name.isEmpty else {
            Log.debug(label: LOG_TAG, "\(#function) - Error creating MediaInfo, name must not be Empty")
            return nil
        }

        guard !streamType.isEmpty else {
            Log.debug(label: LOG_TAG, "\(#function) - Error creating MediaInfo, stream type must not be Empty")
            return nil
        }

        guard length > 0 else {
            Log.debug(label: LOG_TAG, "\(#function) - Error creating MediaInfo, length must not be less than zero")
            return nil
        }

        let prerollWaitingTimeInSeconds = prerollWaitingTime/1000 //convert to seconds

        let mediaInfo = MediaInfo.init(id: id, name: name, streamType: streamType, mediaType: mediaType, length: length, resumed: resumed, prerollWaitingTime: prerollWaitingTimeInSeconds, granularAdTracking: granularAdTracking)

        return mediaInfo
    }

    func toMap() -> [String: Any] {
        var mediaInfoMap: [String: Any] = [:]
        mediaInfoMap[MediaConstants.MediaInfo.ID] = getId()
        mediaInfoMap[MediaConstants.MediaInfo.NAME] = getName()
        mediaInfoMap[MediaConstants.MediaInfo.LENGTH] = getLength()
        mediaInfoMap[MediaConstants.MediaInfo.STREAM_TYPE] = getStreamType()
        mediaInfoMap[MediaConstants.MediaInfo.MEDIA_TYPE] = getMediaType().stringValue()
        mediaInfoMap[MediaConstants.MediaInfo.RESUMED] = isResumed()
        mediaInfoMap[MediaConstants.MediaInfo.PREROLL_TRACKING_WAITING_TIME] = getPrerollWaitingTime()
        mediaInfoMap[MediaConstants.MediaInfo.GRANULAR_AD_TRACKING] = isGranularAdTrackingEnabled()

        return mediaInfoMap
    }

    func getId() -> String {
        return id
    }

    func getName() -> String {
        return name
    }

    func getStreamType() -> String {
        return streamType
    }

    func getMediaType() -> MediaType {
        return mediaType
    }

    func getLength() -> Double {
        return length
    }

    func isResumed() -> Bool {
        return resumed
    }

    func getPrerollWaitingTime() -> TimeInterval {
        return prerollWaitingTime
    }

    func isGranularAdTrackingEnabled() -> Bool {
        return granularAdTracking
    }
}

class AdBreakInfo {

}

class AdInfo {

}

class ChapterInfo {

}

class QoEInfo {

}

class StateInfo {

}
