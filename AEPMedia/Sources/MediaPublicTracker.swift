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

class MediaPublicTracker: MediaTracker {

    private static let LOG_TAG = MediaConstants.LOG_TAG
    private static let CLASS_NAME = "MediaPublicTracker"

    typealias dispatchFn = (Event) -> Void

    let TICK_INTERVAL = TimeInterval(0.5)
    let EVENT_TIMEOUT_MS: Int64 = 1000
    private let dispatchQueue: DispatchQueue = DispatchQueue(label: LOG_TAG)

    var dispatch: dispatchFn?
    let config: [String: Any]?
    let trackerId: String
    var sessionId: String
    var inSession = true
    var lastEventTs: Int64 = 0
    var lastPlayheadParams: [String: Any]?
    var timer: DispatchSourceTimer?

    // MediaTracker Impl
    init(dispatch: dispatchFn?, config: [String: Any]?) {
        self.dispatch = dispatch
        self.config = config
        self.trackerId = UUID().uuidString
        self.sessionId = UUID().uuidString

        let eventData: [String: Any] = [
            MediaConstants.Tracker.ID: self.trackerId,
            MediaConstants.Tracker.EVENT_PARAM: self.config ?? [:]
        ]
        let event = Event(name: MediaConstants.Media.EVENT_NAME_CREATE_TRACKER,
                          type: MediaConstants.Media.EVENT_TYPE,
                          source: MediaConstants.Media.EVENT_SOURCE_TRACKER_REQUEST,
                          data: eventData)

        dispatch?(event)
        Log.debug(label: Self.LOG_TAG, "[\(Self.CLASS_NAME)<\(#function)>]: Tracker request event was sent to event hub.")
    }

    deinit {
        stopTimer()
    }

    public func trackSessionStart(info: [String: Any], metadata: [String: String]? = nil) {
        dispatchQueue.async {
            self.trackInternal(eventName: MediaConstants.EventName.SESSION_START, params: info, metadata: metadata)
            self.startTimer()
        }
    }

    public func trackPlay() {
        dispatchQueue.async {
            self.trackInternal(eventName: MediaConstants.EventName.PLAY)
        }
    }

    public func trackPause() {
        dispatchQueue.async {
            self.trackInternal(eventName: MediaConstants.EventName.PAUSE)
        }
    }

    public func trackComplete() {
        dispatchQueue.async {
            self.trackInternal(eventName: MediaConstants.EventName.COMPLETE)
        }
    }

    public func trackSessionEnd() {
        dispatchQueue.async {
            self.trackInternal(eventName: MediaConstants.EventName.SESSION_END)
        }
    }

    public func trackError(errorId: String) {
        dispatchQueue.async {
            let params: [String: Any] = [MediaConstants.ErrorInfo.ID: errorId]
            self.trackInternal(eventName: MediaConstants.EventName.ERROR, params: params)
        }
    }

    public func trackEvent(event: MediaEvent, info: [String: Any]? = nil, metadata: [String: String]? = nil) {
        dispatchQueue.async {
            self.trackInternal(eventName: event.rawValue, params: info, metadata: metadata)
        }
    }

    public func updateCurrentPlayhead(time: Double) {
        dispatchQueue.async {
            let params: [String: Any] = [MediaConstants.Tracker.PLAYHEAD: time]
            self.trackInternal(eventName: MediaConstants.EventName.PLAYHEAD_UPDATE, params: params)
        }
    }

    public func updateQoEObject(qoe: [String: Any]) {
        dispatchQueue.async {
            self.trackInternal(eventName: MediaConstants.EventName.QOE_UPDATE, params: qoe)
        }
    }

    private func trackInternal(eventName: String, params: [String: Any]? = nil, metadata: [String: String]? = nil, internalEvent: Bool = false) {
        if eventName == MediaConstants.EventName.SESSION_START {
            // Internal Tracker starts a new session only when we are not in an active session and we follow the same.
            if !inSession, MediaInfo(info: params) != nil {
                sessionId = UUID().uuidString
                inSession = true
            }
        } else if eventName == MediaConstants.EventName.COMPLETE || eventName == MediaConstants.EventName.SESSION_END {
            inSession = false
        }

        var eventData: [String: Any] = [:]
        eventData[MediaConstants.Tracker.ID] = self.trackerId
        eventData[MediaConstants.Tracker.SESSION_ID] = self.sessionId
        eventData[MediaConstants.Tracker.EVENT_NAME] = eventName
        eventData[MediaConstants.Tracker.EVENT_INTERNAL] = internalEvent

        if params != nil {
            eventData[MediaConstants.Tracker.EVENT_PARAM] = params
        }

        if metadata != nil {
            eventData[MediaConstants.Tracker.EVENT_METADATA] = metadata
        }

        let ts = getCurrentTimeStamp()
        eventData[MediaConstants.Tracker.EVENT_TIMESTAMP] = ts

        let event = Event(name: MediaConstants.Media.EVENT_NAME_TRACK_MEDIA, type: MediaConstants.Media.EVENT_TYPE, source: MediaConstants.Media.EVENT_SOURCE_TRACK_MEDIA, data: eventData)

        dispatch?(event)

        lastEventTs = ts
        if eventName == MediaConstants.EventName.PLAYHEAD_UPDATE && params != nil {
            lastPlayheadParams = params
        }
    }

    private func tick() {
        dispatchQueue.async {
            guard self.inSession else {
                return
            }

            let currentTs = self.getCurrentTimeStamp()
            if (currentTs - self.lastEventTs) > self.EVENT_TIMEOUT_MS {
                // We have not got any public api call for 1 second.
                // We manually send an event to keep our internal processsing alive (idle tracking / ping processing).
                self.trackInternal(eventName: MediaConstants.EventName.PLAYHEAD_UPDATE, params: self.lastPlayheadParams, internalEvent: true)
            }
        }
    }

    private func startTimer() {
        if timer == nil {
            timer = DispatchSource.makeTimerSource(queue: dispatchQueue)
            timer?.setEventHandler { [weak self] in
                self?.tick()
            }
            timer?.schedule(deadline: .now(), repeating: self.TICK_INTERVAL)
            timer?.resume()
        }
    }

    private func stopTimer() {
        if let timer = self.timer, !timer.isCancelled {
            self.timer?.cancel()
            self.timer = nil
        }
    }

    func getCurrentTimeStamp() -> Int64 {
        return Date().millisecondsSince1970
    }
}

private extension Date {
    var millisecondsSince1970: Int64 {
        return Int64((timeIntervalSince1970 * 1000.0).rounded())
    }

}
