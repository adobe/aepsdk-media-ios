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

@objc(AEPMediaTracker)
public class MediaTracker: NSObject, MediaUtil {

    static let LOG_TAG = "MediaTracker"

    typealias dispatchFn = (Event) -> Void

    let TICK_INTERVAL = TimeInterval(0.75)
    let EVENT_TIMEOUT = TimeInterval(0.5)
    private let dispatchQueue: DispatchQueue = DispatchQueue(label: LOG_TAG)

    var dispatch: dispatchFn?
    let config: [String: Any]?
    let trackerId: String?
    var sessionId: String?
    var resetSessionId = false
    var inSession = false
    var lastEventTs = TimeInterval()
    var lastPlayheadParams: [String: Any]?
    var timer: Timer?

    init(dispatch: @escaping dispatchFn, config: [String: Any]?) {
        self.dispatch = dispatch
        self.config = config
        self.trackerId = MediaTracker.getUniqueId()
        self.sessionId = MediaTracker.getUniqueId()
        super.init()

        let eventData: [String: Any] = [MediaConstants.Tracker.ID: trackerId, MediaConstants.Tracker.EVENT_PARAM: config ?? [:]]
        let event = Event(name: MediaConstants.Media.EVENT_NAME_CREATE_TRACKER, type: MediaConstants.Media.EVENT_TYPE, source: MediaConstants.Media.EVENT_SOURCE_TRACKER_REQUEST, data: eventData)

        dispatch(event)
        Log.debug(label: Self.LOG_TAG, "\(#function): Tracker request event was sent to event hub.")
    }

    func trackSessionStart(info: [String: Any], metadata: [String: String] = [:]) {
        dispatchQueue.async {
            self.trackInternal(eventName: MediaConstants.EventName.SESSION_START, params: info, metadata: metadata)
        }
    }

    func trackPlay() {
        dispatchQueue.async {
            self.trackInternal(eventName: MediaConstants.EventName.PLAY)
        }
    }

    func trackPause() {
        dispatchQueue.async {
            self.trackInternal(eventName: MediaConstants.EventName.PAUSE)
        }
    }

    func trackComplete() {
        dispatchQueue.async {
            self.trackInternal(eventName: MediaConstants.EventName.COMPLETE)
        }
    }

    func trackSessionEnd() {
        dispatchQueue.async {
            self.trackInternal(eventName: MediaConstants.EventName.SESSION_END)
        }
    }

    func trackError(errorId: String) {
        dispatchQueue.async {
            let params: [String: Any] = [MediaConstants.ErrorInfo.ID: errorId]
            self.trackInternal(eventName: MediaConstants.EventName.ERROR, params: params)
        }
    }

    func trackEvent(event: String, info: [String: Any], metadata: [String: String]) {
        dispatchQueue.async {
            self.trackInternal(eventName: event, params: info, metadata: metadata)
        }
    }

    func updateCurrentPlayhead(time: Double) {
        dispatchQueue.async {
            let params: [String: Any] = [MediaConstants.Tracker.PLAYHEAD: time]
            self.trackInternal(eventName: MediaConstants.EventName.PLAYHEAD_UPDATE, params: params)
        }
    }

    func updateQoEObject(qoe: [String: Any]) {
        dispatchQueue.async {
            self.trackInternal(eventName: MediaConstants.EventName.QOE_UPDATE, params: qoe)
        }
    }

    private func trackInternal(eventName: String, params: [String: Any]? = nil, metadata: [String: String]? = nil, internalEvent: Bool = false) {
        if eventName == MediaConstants.EventName.SESSION_START {
            // Internal Tracker starts a new session only when we are not in an active session and we follow the same.
            if params != nil {
                let validMediaParams = MediaInfo(info: params) != nil
                if validMediaParams {
                    if resetSessionId {
                        sessionId = MediaTracker.getUniqueId()
                        resetSessionId = false
                    }

                    inSession = true
                }
            }
        } else if eventName == MediaConstants.EventName.COMPLETE || eventName == MediaConstants.EventName.SESSION_END {
            inSession = false

            // We still don't reset the session id till the next time we get session_start
            // Any API call we receive after complete or session end is an error and is
            // sent with same session_id.
            resetSessionId = true
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

        let ts = MediaTracker.getCurrentTimeStamp()
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

            let currentTs = MediaTracker.getCurrentTimeStamp()
            if (currentTs - self.lastEventTs) > self.EVENT_TIMEOUT {
                // We have not got any public api call for 500 ms.
                // We manually send an event to keep our internal processsing alive (idle tracking / ping processing).
                self.trackInternal(eventName: MediaConstants.EventName.PLAYHEAD_UPDATE, params: self.lastPlayheadParams, internalEvent: true)
            }
        }
    }

    private func startTimer() {
        if timer == nil {
            timer = Timer.scheduledTimer(withTimeInterval: TICK_INTERVAL, repeats: true, block: { (_) in
                self.tick()
            })
            timer?.fire()
        }
    }

    private func stopTimer() {
        timer?.invalidate()
    }

    static func getCurrentTimeStamp() -> TimeInterval {
        return Date().timeIntervalSince1970
    }

    static func getUniqueId() -> String {
        return UUID().uuidString
    }
}

protocol MediaUtil {
    static func getCurrentTimeStamp() -> TimeInterval
    static func getUniqueId() -> String
}
