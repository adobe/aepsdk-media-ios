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

class QoEInfo: Equatable {
    private static let LOG_TAG = "QoEInfo"
    let bitrate: Double
    let droppedFrames: Double
    let fps: Double
    let startupTime: Double

    static func == (lhs: QoEInfo, rhs: QoEInfo) -> Bool {
        return  lhs.bitrate.isAlmostEqual(rhs.bitrate) &&
            lhs.droppedFrames.isAlmostEqual(rhs.droppedFrames) &&
            lhs.fps.isAlmostEqual(rhs.fps) &&
            lhs.startupTime.isAlmostEqual(rhs.startupTime)
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
