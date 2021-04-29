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

@objc(AEPMediaTracker)
public protocol MediaTracker {

    /// API to track the start of a viewing session.
    /// - Parameter:
    ///   - info: Dictionary created using `createMediaObject` API.
    ///   - metadata: Dictionary containing the context data associated with the media session.
    @objc(trackSessionStart:metadata:)
    func trackSessionStart(info: [String: Any], metadata: [String: String]?)

    /// API to track media play or resume after a previous pause.
    @objc(trackPlay)
    func trackPlay()

    /// API to track media pause.
    @objc(trackPause)
    func trackPause()

    /// API to track media complete.
    @objc(trackComplete)
    func trackComplete()

    /// API to track the end of a viewing session.
    /// This API must be called even if the user does not view the media to completion.
    @objc(trackSessionEnd)
    func trackSessionEnd()

    /// API to track an error in media playback.
    /// - Parameter:
    ///   - errorId: `String` Identifier describing the error.
    @objc(trackError:)
    func trackError(errorId: String)

    /// API to track media event.
    /// - Parameter:
    ///   - event: `MediaEvent` describing the event to track `ChapterStart`, `ChapterComplete`, `AdBreakStart`, `AdBreakComplete`, `AdStart`, `AdComplete`, `SeekStart`, `SeekComplete`, `BufferStart`,
    ///   `BufferComplete`, `BitrateChange`.
    ///   - info: `Dictionary` created using `createChapterObject`, `createAdBreakObject`, `createAdObject`, `createStateObject` API  with for `AdBreakStart`, `AdStart`, `ChapterStart`, `StateStart` and `StateEnd` events respectively. Pass nil for other events.
    ///   - metadata: `Dictionary` containing context data for `AdStart` and `ChapterStart` events. Pass nil for other events.
    @objc(trackEvent:info:metadata:)
    func trackEvent(event: MediaEvent, info: [String: Any]?, metadata: [String: String]?)

    /// API to update playhead value for the content playback.
    /// This API should be called when media playhead changes for accurate tracking.
    /// - Parameter:
    ///   - time: Current position of the playhead. For VOD, value is specified in seconds from the beginning of the media item.
    ///   For live streaming, return playhead position if available or the current UTC time in seconds otherwise.
    @objc(updateCurrentPlayhead:)
    func updateCurrentPlayhead(time: Double)

    /// API to update the QoE data from the player to track.
    /// This API should be called during a playback session with recently available QoE data.
    /// - Parameter:
    ///   - qoe: `Dictionary` containing current QoE information
    @objc(updateQoEObject:)
    func updateQoEObject(qoe: [String: Any])
}
