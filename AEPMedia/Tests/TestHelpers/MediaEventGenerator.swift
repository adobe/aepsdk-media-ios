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
        var mockTimeStamp = TimeInterval()

        override init(dispatch: dispatchFn?, config: [String: Any]?) {
            super.init(dispatch: dispatch, config: config)
        }

        override func getCurrentTimeStamp() -> TimeInterval {
            return mockTimeStamp
        }

        func setTimeStamp(value: TimeInterval) {
            mockTimeStamp = value
        }

        func incrementTimeStamp(value: TimeInterval) {
            mockTimeStamp += value
        }
    }

    let tracker: MediaPublicTrackerMock
    let semaphore = DispatchSemaphore(value: 0)
    var dispatchedEvent: Event?
    var usingProvidedDispatchFn = false

    init(config: [String: Any]? = nil, dispatch: ((Event) -> Void)? = nil) {
        tracker = MediaPublicTrackerMock(dispatch: dispatch, config: config)
        guard let dispatch = dispatch else {
            tracker.dispatch = { (event: Event) in
                self.dispatchedEvent = event
                self.semaphore.signal()
            }
            return
        }
        usingProvidedDispatchFn = true
        tracker.dispatch = dispatch
    }

    func trackSessionStart(info: [String: Any], metadata: [String: String]? = nil) {
        tracker.trackSessionStart(info: info, metadata: metadata)
        if !usingProvidedDispatchFn { semaphore.wait() }
    }

    func trackPlay() {
        tracker.trackPlay()
        if !usingProvidedDispatchFn { semaphore.wait() }
    }

    func trackPause() {
        tracker.trackPause()
        if !usingProvidedDispatchFn { semaphore.wait() }
    }

    func trackComplete() {
        tracker.trackComplete()
        if !usingProvidedDispatchFn { semaphore.wait() }
    }

    func trackSessionEnd() {
        tracker.trackSessionEnd()
        if !usingProvidedDispatchFn { semaphore.wait() }
    }

    func trackError(errorId: String) {
        tracker.trackError(errorId: errorId)
        if !usingProvidedDispatchFn { semaphore.wait() }
    }

    func trackEvent(event: MediaEvent, info: [String: Any]? = nil, metadata: [String: String]? = nil) {
        tracker.trackEvent(event: event, info: info, metadata: metadata)
        if !usingProvidedDispatchFn { semaphore.wait() }
    }

    func updateCurrentPlayhead(time: Double) {
        tracker.updateCurrentPlayhead(time: time)
        if !usingProvidedDispatchFn { semaphore.wait() }
    }

    func updateQoEObject(qoe: [String: Any]) {
        tracker.updateQoEObject(qoe: qoe)
        if !usingProvidedDispatchFn { semaphore.wait() }
    }

    func setTimeStamp(value: TimeInterval) {
        tracker.setTimeStamp(value: value)
    }

    func incrementTimeStamp(value: TimeInterval) {
        tracker.incrementTimeStamp(value: value)
    }
    
    func getTrackerId() -> String {
        return tracker.trackerId ?? ""
    }
}
