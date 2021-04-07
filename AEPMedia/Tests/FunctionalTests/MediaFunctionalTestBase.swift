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
import AEPServices
@testable import AEPMedia

class MediaFunctionalTestBase: XCTestCase {
    var media: Media!
    var mockRuntime: TestableExtensionRuntime!

    let analyticsSharedState: [String: Any] = [
        MediaConstants.Analytics.ANALYTICS_VISITOR_ID: "aid",
        MediaConstants.Analytics.VISITOR_ID: "vid",
    ]

    let identitySharedState: [String: Any] = [
        MediaConstants.Identity.MARKETING_VISITOR_ID: "mid",
        MediaConstants.Identity.BLOB: "blob",
        MediaConstants.Identity.LOC_HINT: "lochint",
        MediaConstants.Identity.VISITOR_IDS_LIST: [["id_origin": "orig1", "id_type": "type1", "id": "97717", "authentication_state": 1]]
    ]

    func setupBase(disableIdRequest: Bool = true) {
        resetExtension()
    }

    func resetExtension() {
        mockRuntime = TestableExtensionRuntime()
        media = Media(runtime: mockRuntime)
        media.onRegistered()
    }

    func waitForProcessing(interval: TimeInterval = 0.5) {
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

        simulateAnalyticsState(data: analyticsSharedState)

        simulateIdentityState(data: identitySharedState)

        var configSharedState: [String: Any] = [
            MediaConstants.Configuration.ANALYTICS_TRACKING_SERVER: "analytics-test.com",
            MediaConstants.Configuration.ANALYTICS_RSID: "rsid",
            MediaConstants.Configuration.GLOBAL_CONFIG_PRIVACY: "optedin",
            MediaConstants.Configuration.EXPERIENCE_CLOUD_ORGID: "orgid",
            MediaConstants.Configuration.MEDIA_OVP: "ovp",
            MediaConstants.Configuration.MEDIA_CHANNEL: "channel",
            MediaConstants.Configuration.MEDIA_PLAYER_NAME: "player",
            MediaConstants.Configuration.MEDIA_APP_VERSION: "1.0",
            MediaConstants.Configuration.MEDIA_DEBUG_LOGGING: true,
            MediaConstants.Configuration.MEDIA_TRACKING_SERVER: "media-tracking-test.com",
            MediaConstants.Configuration.MEDIA_COLLECTION_SERVER: "media-collection-test.com"
        ]
        if let configData = configData {
            configSharedState.merge(configData) { (_, newValue) in
                return newValue
            }
        }
        simulateConfigState(data: configSharedState)
    }
}
