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

class MediaInfo: Equatable {
    static let LOG_TAG = "MediaInfo"
    static let DEFAULT_PREROLL_WAITING_TIME_IN_MS: Double = 250.0 //250 milliseconds
    let id: String
    let name: String
    let streamType: String
    let mediaType: MediaType
    let length: Double
    let resumed: Bool
    let prerollWaitingTime: Double
    let granularAdTracking: Bool

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

    init?(id: String, name: String, streamType: String, mediaType: MediaType, length: Double, resumed: Bool = false, prerollWaitingTime: TimeInterval = DEFAULT_PREROLL_WAITING_TIME_IN_MS, granularAdTracking: Bool = false) {

        guard !id.isEmpty else {
            Log.debug(label: Self.LOG_TAG, "\(#function) - Error creating MediaInfo, id must not be Empty")
            return nil
        }

        guard !name.isEmpty else {
            Log.debug(label: Self.LOG_TAG, "\(#function) - Error creating MediaInfo, name must not be Empty")
            return nil
        }

        guard !streamType.isEmpty else {
            Log.debug(label: Self.LOG_TAG, "\(#function) - Error creating MediaInfo, stream type must not be Empty")
            return nil
        }

        guard length >= 0 else {
            Log.debug(label: Self.LOG_TAG, "\(#function) - Error creating MediaInfo, length must not be less than zero")
            return nil
        }

        self.id = id
        self.name = name
        self.streamType = streamType
        self.mediaType = mediaType
        self.length = length
        self.resumed = resumed
        self.prerollWaitingTime = prerollWaitingTime
        self.granularAdTracking = granularAdTracking
    }

    convenience init?(info: [String: Any]?) {
        guard info != nil else {
            return nil
        }

        guard let id = info?[MediaConstants.MediaInfo.ID] as? String else {
            Log.debug(label: Self.LOG_TAG, "\(#function) - Error parsing MediaInfo, invalid id")
            return nil
        }

        guard let name = info?[MediaConstants.MediaInfo.NAME] as? String else {
            Log.debug(label: Self.LOG_TAG, "\(#function) - Error parsing MediaInfo, invalid name")
            return nil
        }

        guard let streamType = info?[MediaConstants.MediaInfo.STREAM_TYPE] as? String else {
            Log.debug(label: Self.LOG_TAG, "\(#function) - Error parsing MediaInfo, invalid stream type. Sample values -> {\"VOD\", \"LIVE\" ...}")
            return nil
        }

        guard let mediaTypeString = info?[MediaConstants.MediaInfo.MEDIA_TYPE] as? String else {
            Log.debug(label: Self.LOG_TAG, "\(#function) - Error parsing MediaInfo, invalid media type. Valid values -> {\"video\", \"audio\"}")
            return nil
        }

        guard let mediaType: MediaType = MediaType(rawValue: mediaTypeString) else {
            Log.debug(label: Self.LOG_TAG, "\(#function) - Error parsing MediaInfo, invalid media type")
            return nil
        }

        guard let length = info?[MediaConstants.MediaInfo.LENGTH] as? Double else {
            Log.debug(label: Self.LOG_TAG, "\(#function) - Error parsing MediaInfo, invalid length")
            return nil
        }

        let resumed = info?[MediaConstants.MediaInfo.RESUMED] as? Bool ?? false

        let prerollWaitTimeVal: Double = info?[MediaConstants.MediaInfo.PREROLL_TRACKING_WAITING_TIME] as? Double ?? Self.DEFAULT_PREROLL_WAITING_TIME_IN_MS

        let prerollWaitingTime: TimeInterval = TimeInterval(prerollWaitTimeVal)

        let granularAdTracking = info?[MediaConstants.MediaInfo.GRANULAR_AD_TRACKING] as? Bool ?? false

        self.init(id: id, name: name, streamType: streamType, mediaType: mediaType, length: length, resumed: resumed, prerollWaitingTime: prerollWaitingTime, granularAdTracking: granularAdTracking)
    }

    func toMap() -> [String: Any] {
        var mediaInfoMap: [String: Any] = [:]
        mediaInfoMap[MediaConstants.MediaInfo.ID] = self.id
        mediaInfoMap[MediaConstants.MediaInfo.NAME] = self.name
        mediaInfoMap[MediaConstants.MediaInfo.LENGTH] = self.length
        mediaInfoMap[MediaConstants.MediaInfo.STREAM_TYPE] = self.streamType
        mediaInfoMap[MediaConstants.MediaInfo.MEDIA_TYPE] = self.mediaType.rawValue
        mediaInfoMap[MediaConstants.MediaInfo.RESUMED] = self.resumed
        mediaInfoMap[MediaConstants.MediaInfo.PREROLL_TRACKING_WAITING_TIME] = self.prerollWaitingTime
        mediaInfoMap[MediaConstants.MediaInfo.GRANULAR_AD_TRACKING] = self.granularAdTracking

        return mediaInfoMap
    }
}

class AdBreakInfo: Equatable {
    static let LOG_TAG = "AdBreakInfo"
    let name: String
    let position: Int
    let startTime: Double

    static func == (lhs: AdBreakInfo, rhs: AdBreakInfo) -> Bool {
        return  lhs.name == rhs.name &&
            lhs.position == rhs.position &&
            lhs.startTime == rhs.startTime
    }

    init?(name: String, position: Int, startTime: Double) {

        guard !name.isEmpty else {
            Log.debug(label: Self.LOG_TAG, "\(#function) - Error creating AdBreakInfo, name must not be Empty")
            return nil
        }

        guard position >= 1 else {
            Log.debug(label: Self.LOG_TAG, "\(#function) - Error creating AdBreakInfo, position must be greater than zero")
            return nil
        }

        guard startTime >= 0 else {
            Log.debug(label: Self.LOG_TAG, "\(#function) - Error creating AdBreakInfo, start time must not be less than zero")
            return nil
        }

        self.name = name
        self.position = position
        self.startTime = startTime
    }

    convenience init?(info: [String: Any]?) {
        guard info != nil else {
            return nil
        }

        guard let name = info?[MediaConstants.AdBreakInfo.NAME] as? String else {
            Log.debug(label: Self.LOG_TAG, "\(#function) - Error parsing AdBreakInfo, invalid name")
            return nil
        }

        guard let position = info?[MediaConstants.AdBreakInfo.POSITION] as? Int else {
            Log.debug(label: Self.LOG_TAG, "\(#function) - Error parsing AdBreakInfo, invalid position")
            return nil
        }

        guard let startTime = info?[MediaConstants.AdBreakInfo.START_TIME] as? Double else {
            Log.debug(label: Self.LOG_TAG, "\(#function) - Error parsing AdBreakInfo, invalid start time")
            return nil
        }

        self.init(name: name, position: position, startTime: startTime)
    }

    func toMap() -> [String: Any] {
        var adBreakInfoMap: [String: Any] = [:]
        adBreakInfoMap[MediaConstants.AdBreakInfo.NAME] = self.name
        adBreakInfoMap[MediaConstants.AdBreakInfo.POSITION] = self.position
        adBreakInfoMap[MediaConstants.AdBreakInfo.START_TIME] = self.startTime

        return adBreakInfoMap
    }
}

class AdInfo: Equatable {
    static let LOG_TAG = "AdInfo"
    let id: String
    let name: String
    let position: Int
    let length: Double

    static func == (lhs: AdInfo, rhs: AdInfo) -> Bool {
        return  lhs.id == rhs.id &&
            lhs.name == rhs.name &&
            lhs.position == rhs.position &&
            lhs.length == rhs.length
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

class ChapterInfo: Equatable {
    static let LOG_TAG = "ChapterInfo"
    let name: String
    let position: Int
    let startTime: Double
    let length: Double

    static func == (lhs: ChapterInfo, rhs: ChapterInfo) -> Bool {
        return  lhs.name == rhs.name &&
            lhs.position == rhs.position &&
            lhs.startTime == rhs.startTime &&
            lhs.length == rhs.length
    }

    init?(name: String, position: Int, startTime: Double, length: Double) {

        guard !name.isEmpty else {
            Log.debug(label: Self.LOG_TAG, "\(#function) - Error creating ChapterInfo, name must not be empty")
            return nil
        }

        guard position >= 1 else {
            Log.debug(label: Self.LOG_TAG, "\(#function) - Error creating AdBreakInfo, position must be greater than zero")
            return nil
        }

        guard startTime >= 0 else {
            Log.debug(label: Self.LOG_TAG, "\(#function) - Error creating ChapterInfo, start time must not be less than zero")
            return nil
        }

        guard length >= 0 else {
            Log.debug(label: Self.LOG_TAG, "\(#function) - Error creating ChapterInfo, length must not be less than zero")
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
            Log.debug(label: Self.LOG_TAG, "\(#function) - Error parsing ChapterInfo, invalid name")
            return nil
        }

        guard let position = info?[MediaConstants.ChapterInfo.POSITION] as? Int else {
            Log.debug(label: Self.LOG_TAG, "\(#function) - Error parsing ChapterInfo, invalid position")
            return nil
        }

        guard let startTime = info?[MediaConstants.ChapterInfo.START_TIME] as? Double else {
            Log.debug(label: Self.LOG_TAG, "\(#function) - Error parsing ChapterInfo, invalid start time")
            return nil
        }

        guard let length = info?[MediaConstants.ChapterInfo.LENGTH] as? Double else {
            Log.debug(label: Self.LOG_TAG, "\(#function) - Error parsing ChapterInfo, invalid length")
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

class QoEInfo: Equatable {
    static let LOG_TAG = "QoEInfo"
    let bitrate: Double
    let droppedFrames: Double
    let fps: Double
    let startupTime: Double

    static func == (lhs: QoEInfo, rhs: QoEInfo) -> Bool {
        return  lhs.bitrate == rhs.bitrate &&
            lhs.droppedFrames == rhs.droppedFrames &&
            lhs.fps == rhs.fps &&
            lhs.startupTime == rhs.startupTime
    }

    init?(bitrate: Double, droppedFrames: Double, fps: Double, startupTime: Double) {
        guard bitrate >= 0 else {
            Log.debug(label: Self.LOG_TAG, "\(#function) - Error creating QoEInfo, bitrate must not be less than zero")
            return nil
        }

        guard droppedFrames >= 0 else {
            Log.debug(label: Self.LOG_TAG, "\(#function) - Error creating QoEInfo, dropped frames must not be less than zero")
            return nil
        }

        guard fps >= 0 else {
            Log.debug(label: Self.LOG_TAG, "\(#function) - Error creating QoEInfo, fps must not be less than zero")
            return nil
        }

        guard startupTime >= 0 else {
            Log.debug(label: Self.LOG_TAG, "\(#function) - Error creating QoEInfo, startup time must not be less than zero")
            return nil
        }

        self.bitrate = bitrate
        self.droppedFrames = droppedFrames
        self.fps = fps
        self.startupTime = startupTime
    }

    convenience init?(info: [String: Any]?) {
        guard info != nil else {
            return nil
        }

        guard let bitrate = info?[MediaConstants.QoEInfo.BITRATE] as? Double else {
            Log.debug(label: Self.LOG_TAG, "\(#function) - Error parsing QoEInfo, invalid bitrate")
            return nil
        }

        guard let droppedFrames = info?[MediaConstants.QoEInfo.DROPPED_FRAMES] as? Double else {
            Log.debug(label: Self.LOG_TAG, "\(#function) - Error parsing QoEInfo, invalid dropped frames")
            return nil
        }

        guard let fps = info?[MediaConstants.QoEInfo.FPS] as? Double else {
            Log.debug(label: Self.LOG_TAG, "\(#function) - Error parsing QoEInfo, invalid fps")
            return nil
        }

        guard let startupTime = info?[MediaConstants.QoEInfo.STARTUP_TIME] as? Double else {
            Log.debug(label: Self.LOG_TAG, "\(#function) - Error parsing QoEInfo, invalid start time")
            return nil
        }

        self.init(bitrate: bitrate, droppedFrames: droppedFrames, fps: fps, startupTime: startupTime)
    }

    func toMap() -> [String: Any] {
        var qoeInfoMap: [String: Any] = [:]
        qoeInfoMap[MediaConstants.QoEInfo.BITRATE] = self.bitrate
        qoeInfoMap[MediaConstants.QoEInfo.DROPPED_FRAMES] = self.droppedFrames
        qoeInfoMap[MediaConstants.QoEInfo.FPS] = self.fps
        qoeInfoMap[MediaConstants.QoEInfo.STARTUP_TIME] = self.startupTime

        return qoeInfoMap
    }
}

class StateInfo: Equatable {
    static let LOG_TAG = "StateInfo"
    var stateName: String

    static func == (lhs: StateInfo, rhs: StateInfo) -> Bool {
        return  lhs.stateName == rhs.stateName
    }

    init?(stateName: String) {
        guard !stateName.isEmpty else {
            Log.debug(label: Self.LOG_TAG, "\(#function) - Error creating StateInfo, state name cannot be empty")
            return nil
        }

        let pattern = "^[a-zA-Z0-9_\\.]{1,64}$"
        let s = try! NSRegularExpression(pattern: pattern, options: [])
        let matches = s.matches(in: stateName, options: [], range: NSRange(location: 0, length: stateName.count))
        if matches.isEmpty {
            Log.debug(label: Self.LOG_TAG, "\(#function) - Error creating StateInfo, state name: \(stateName) with length: \(stateName.count)  cannot contain special characters and can only be 64 character long. Only alphabets, digits, '_' and '.' are allowed.")
            return nil
        }

        self.stateName = stateName
    }

    convenience init?(info: [String: Any]?) {
        guard info != nil else {
            return nil
        }

        guard let stateName = info?[MediaConstants.StateInfo.STATE_NAME_KEY] as? String else {
            Log.debug(label: Self.LOG_TAG, "\(#function) - Error parsing StateInfo, no state name")
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
