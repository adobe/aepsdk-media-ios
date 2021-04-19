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
import XCTest
@testable import AEPCore
@testable import AEPMedia
class MediaEventGenerator: MediaTracker {
    class MediaPublicTrackerMock: MediaPublicTracker {
        var mockTimeStamp: Int64 = 0
        var mockCurrentPlayhead: Double = 0
        override init(dispatch: dispatchFn?, config: [String: Any]?) {
            super.init(dispatch: dispatch, config: config)
        }
        override func getCurrentTimeStamp() -> Int64 {
            return mockTimeStamp
        }
        override func updateCurrentPlayhead(time: Double) {
            mockCurrentPlayhead = time
            super.updateCurrentPlayhead(time: time)
        }
    }
    let tracker: MediaPublicTrackerMock
    let semaphore = DispatchSemaphore(value: 0)
    var dispatchedEvent: Event?
    var usingProvidedDispatchFn = false
    var previousPlayhead: Double = 0
    var coreEventTracker: MediaEventTracking?
    init(config: [String: Any]? = nil, dispatch: ((Event) -> Void)? = nil) {
        // if the passed in dispatch function is nil then create one
        guard let dispatch = dispatch else {
            tracker = MediaPublicTrackerMock(dispatch: nil, config: config)
            tracker.dispatch = { (event: Event) in
                self.dispatchedEvent = event
                self.semaphore.signal()
            }
            return
        }
        // otherwise use the passed in dispatch function
        usingProvidedDispatchFn = true
        tracker = MediaPublicTrackerMock(dispatch: dispatch, config: config)
        tracker.dispatch = dispatch
    }
    func trackSessionStart(info: [String: Any], metadata: [String: String]? = nil) {
        tracker.trackSessionStart(info: info, metadata: metadata)
        waitForTrackerRequest()
    }
    func trackPlay() {
        tracker.trackPlay()
        waitForTrackerRequest()
    }
    func trackPause() {
        tracker.trackPause()
        waitForTrackerRequest()
    }
    func trackComplete() {
        tracker.trackComplete()
        waitForTrackerRequest()
    }
    func trackSessionEnd() {
        tracker.trackSessionEnd()
        waitForTrackerRequest()
    }
    func trackError(errorId: String) {
        tracker.trackError(errorId: errorId)
        waitForTrackerRequest()
    }
    func trackEvent(event: MediaEvent, info: [String: Any]? = nil, metadata: [String: String]? = nil) {
        tracker.trackEvent(event: event, info: info, metadata: metadata)
        waitForTrackerRequest()
    }
    func updateCurrentPlayhead(time: Double) {
        tracker.updateCurrentPlayhead(time: time)
        waitForTrackerRequest()
        self.previousPlayhead = time
    }
    func updateQoEObject(qoe: [String: Any]) {
        tracker.updateQoEObject(qoe: qoe)
        waitForTrackerRequest()
    }
    // Methods for testing
    func connectCoreTracker(tracker: MediaEventTracking?) {
        coreEventTracker = tracker
    }
    func getTimeStamp() -> Int64 {
        return tracker.mockTimeStamp
    }
    func setTimeStamp(value: Int64) {
        tracker.mockTimeStamp = value
    }
    func incrementTimeStamp(value: Int64) {
        tracker.mockTimeStamp += value
    }
    func getCurrentPlayhead() -> Double {
        return tracker.mockCurrentPlayhead
    }
    func incrementCurrentPlayhead(time: Double) {
        tracker.mockCurrentPlayhead += time
        updateCurrentPlayhead(time: tracker.mockCurrentPlayhead)
    }
    private func waitForTrackerRequest() {
        if !usingProvidedDispatchFn {
            semaphore.wait()
            coreEventTracker?.track(eventData: dispatchedEvent?.data)
        }
    }
}
