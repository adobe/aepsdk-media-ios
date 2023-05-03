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
import AEPCore
import AEPIdentity
import AEPServices
@testable import AEPMedia

class MediaFunctionalTestBase: XCTestCase {
    var media: Media!
    var mockRuntime: TestableExtensionRuntime!
    var mockNetworkService: MockNetworking!
    var timer: DispatchSourceTimer!

    func setupBase(disableIdRequest: Bool = true) {
        FileManager.default.clearCache()
        mockNetworkService = MockNetworking()
        ServiceProvider.shared.networkService = mockNetworkService
        resetExtension()
    }

    func resetExtension() {
        mockRuntime = TestableExtensionRuntime()
        media = Media(runtime: mockRuntime)
        media.onRegistered()
    }

    func waitForProcessing(interval: TimeInterval = 1) {
        let expectation = XCTestExpectation()
        DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + interval - 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: interval)
    }

    func simulateConfigState(data: [String: Any], event: Event? = nil) {
        mockRuntime.simulateSharedState(extensionName: MediaConstants.Configuration.SHARED_STATE_NAME,
                                        event: nil,
                                        data: (data, .set))

        let event = Event(name: "", type: EventType.configuration, source: EventSource.responseContent, data: data)
        mockRuntime.simulateComingEvent(event: event)
    }

    func simulateIdentityState(data: [String: Any], event: Event? = nil) {
        mockRuntime.simulateSharedState(extensionName: MediaConstants.Identity.SHARED_STATE_NAME,
                                        event: nil,
                                        data: (data, .set))
    }

    func simulateAnalyticsState(data: [String: Any], event: Event? = nil) {
        mockRuntime.simulateSharedState(extensionName: MediaConstants.Analytics.SHARED_STATE_NAME,
                                        event: nil,
                                        data: (data, .set))
    }

    func dispatchDefaultConfigAndSharedStates(configData: [String: Any]? = nil) {

        simulateAnalyticsState(data: TestConstants.analyticsSharedState)

        simulateIdentityState(data: TestConstants.identitySharedState)

        var mergedConfigState = TestConstants.configSharedState
        if let configData = configData {
            mergedConfigState.merge(configData) { (_, newValue) in
                return newValue
            }
        }
        simulateConfigState(data: mergedConfigState)
    }
}
