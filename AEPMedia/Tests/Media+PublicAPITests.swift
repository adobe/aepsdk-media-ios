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
@testable import AEPServices
@testable import AEPMedia

class MediaPublicAPITests: XCTestCase {
    var capturedEvent: Event?
    var mediaTracker: MediaTracker?

    override func setUp() {
        EventHub.reset()
        MockExtension.reset()
        EventHub.shared.start()
        registerMockExtension(MockExtension.self)
    }

    private func registerMockExtension<T: Extension> (_ type: T.Type) {
        let semaphore = DispatchSemaphore(value: 0)
        EventHub.shared.registerExtension(type) { (error) in
            semaphore.signal()
        }

        semaphore.wait()
    }

    func dispatch(event: Event) {
        capturedEvent = event
    }

    //MARK: MediaPublicAPI Unit Tests

    // ==========================================================================
    // createTracker
    // ==========================================================================
    func testCreateTracker() {
        mediaTracker = Media.createTracker()
        XCTAssertNotNil(mediaTracker)
    }
}
