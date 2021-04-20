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
        // Setup default network response.
        let headers = ["Location": "/api/v1/sessions/0160be5e22b37eb526c085b82b782d757a328c2b0fa248cc83bd92db452722ac"]
        mockNetworkService?.expectedResponse = HttpConnection(data: nil, response: HTTPURLResponse(url: URL(string: "test.com")!, statusCode: 200, httpVersion: nil, headerFields: headers), error: nil)
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

    // MARK: event verification and helpers for offline and realtime tracker events
    func verifyEvent(eventName: String, payload: [String: Any] = [:], expectedInfo: [String: Any] = [:],
                     expectedMetadata: [String: String] = [:], expectedQoe: [String: Any] = [:],
                     playhead: Double, ts: Int64, isDownloadedSession: Bool = false) {
        let playerTime = payload["playerTime"] as? [String: Any] ?? [:]
        let eventType = payload["eventType"] as? String ?? ""
        let actualParams = payload["params"] as? [String: Any] ?? [:]
        let actualCustomMetadata = payload["customMetadata"] as? [String: String] ?? [:]
        let actualQoe = payload["qoeData"] as? [String: Any] ?? [:]

        // verify session start events
        if eventName == MediaConstants.MediaCollection.EventType.SESSION_START {
            XCTAssertEqual(eventName, eventType)
            verifyPlayerTime(eventName: eventName, actualPlayerTime: playerTime, expectedPlayhead: playhead, expectedTs: ts)
            verifySessionStartParams(expectedInfo: expectedInfo, actualParams: actualParams, isDownloadedSession: isDownloadedSession)
            XCTAssertTrue(isEqual(map1: actualCustomMetadata, map2: extractMediaMetadata(metadata: expectedMetadata)))
            XCTAssertTrue(isEqual(map1: actualQoe, map2: expectedQoe))
            return
        }
        // verification for all other events
        XCTAssertEqual(eventName, eventType)
        verifyPlayerTime(eventName: eventName, actualPlayerTime: playerTime, expectedPlayhead: playhead, expectedTs: ts)
        XCTAssertTrue(isEqual(map1: actualQoe, map2: expectedQoe))
    }

    private func verifyPlayerTime(eventName: String, actualPlayerTime: [String: Any], expectedPlayhead: Double, expectedTs: Int64) {
        let delta = TimeInterval(2)
        // verify playhead
        guard let actualPlayhead = actualPlayerTime[MediaConstants.MediaCollection.PlayerTime.PLAYHEAD] as? Double else {
            XCTFail("Unable to get actual playhead for event: \(eventName)")
            return
        }
        let expectation = XCTestExpectation(description: "for event \(eventName), the actual playhead \(actualPlayhead) should almost be equal to the expected playhead \(expectedPlayhead)")
        if actualPlayhead.isAlmostEqualWithinDelta(expectedPlayhead, delta: delta) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.1)
        // verify timestamp
        guard let actualTs = actualPlayerTime[MediaConstants.MediaCollection.PlayerTime.TS] as? Int64 else {
            XCTFail("Unable to get actual timestamp for event: \(eventName)")
            return
        }
        let expectation2 = XCTestExpectation(description: "for event \(eventName), the actual timestamp \(actualTs) should almost be equal to the expected timestamp \(expectedTs)")
        if actualTs == expectedTs {
            expectation2.fulfill()
        }
        wait(for: [expectation2], timeout: 0.1)
    }

    private func verifySessionStartParams(expectedInfo: [String: Any], actualParams: [String: Any], isDownloadedSession: Bool) {
        if actualParams.count == 0 && expectedInfo.count > 0 {
            XCTFail("expectedInfo size:(\(expectedInfo.count)) present but actualParams is empty")
        }
        // verify offline or realtime
        XCTAssertEqual(isDownloadedSession, actualParams[MediaConstants.MediaCollection.Media.DOWNLOADED] as? Bool)
        // verify analytics
        XCTAssertEqual("analytics-test.com", actualParams[MediaConstants.MediaCollection.Session.ANALYTICS_TRACKING_SERVER] as? String)
        XCTAssertEqual("rsid", actualParams[MediaConstants.MediaCollection.Session.ANALYTICS_RSID] as? String)
        XCTAssertEqual("vid", actualParams[MediaConstants.MediaCollection.Session.ANALYTICS_VISITOR_ID] as? String)
        XCTAssertEqual("aid", actualParams[MediaConstants.MediaCollection.Session.ANALYTICS_AID] as? String)
        // verify identity
        XCTAssertEqual("ecid", actualParams[MediaConstants.MediaCollection.Session.VISITOR_MCUSER_ID] as? String)
        XCTAssertEqual("orgid", actualParams[MediaConstants.MediaCollection.Session.VISITOR_MCORG_ID] as? String)
        verifySerializedCustomerIds(idsToVerify: actualParams[MediaConstants.MediaCollection.Session.VISITOR_CUSTOMER_IDS] as? [String: [String: Any]])
        // verify mediaInfo
        XCTAssertEqual(expectedInfo[MediaConstants.MediaInfo.NAME] as? String, actualParams[MediaConstants.MediaCollection.Media.NAME] as? String)
        XCTAssertEqual(expectedInfo[MediaConstants.MediaInfo.ID] as? String, actualParams[MediaConstants.MediaCollection.Media.ID] as? String)
        XCTAssertEqual(expectedInfo[MediaConstants.MediaInfo.LENGTH] as? Double, actualParams[MediaConstants.MediaCollection.Media.LENGTH] as? Double)
        XCTAssertEqual(expectedInfo[MediaConstants.MediaInfo.STREAM_TYPE] as? String, actualParams[MediaConstants.MediaCollection.Media.CONTENT_TYPE] as? String)
        XCTAssertEqual(expectedInfo[MediaConstants.MediaInfo.RESUMED] as? Bool, actualParams[MediaConstants.MediaCollection.Media.RESUME] as? Bool)
        XCTAssertEqual(Media.extensionVersion, actualParams[MediaConstants.MediaCollection.Media.SDK_VERSION] as? String)
        // verify media config
        XCTAssertEqual("player", actualParams[MediaConstants.Configuration.MEDIA_PLAYER_NAME] as? String)
        XCTAssertEqual("channel", actualParams[MediaConstants.Configuration.MEDIA_CHANNEL] as? String)
    }

    private func extractMediaMetadata(metadata: [String: String]) -> [String: String] {
        var retDict = [String: String]()
        // standard metadata is removed and only custom metadata will be returned.
        for (key, value) in metadata {
            if TestConstants.standardMediaMetadataMapping[key] == nil {
                retDict[key] = value
            }
        }

        return retDict
    }

    private func verifySerializedCustomerIds(idsToVerify: [String: [String: Any]]?) {
        guard let idsToVerify = idsToVerify else {
            XCTFail("the ids to verify were nil")
            return
        }
        for (idKey, idValue) in idsToVerify {
            XCTAssertTrue(isEqual(map1: idValue, map2: TestConstants.expectedSerializedCustomerIds[idKey]))
        }
    }

//    func waitFor(_ secondsToWait: Int, updatePlayhead: Bool, tracker: MediaEventGenerator, semaphore: DispatchSemaphore) {
//        let timestampIncrement = Int64(1)
//        var elapsedTime = 0
//        let queue = DispatchQueue(label: "trackerTimer")
//        timer = DispatchSource.makeTimerSource(queue: queue)
//        timer.schedule(deadline: .now(), repeating: .seconds(1))
//        timer.setEventHandler { [weak self] in
//            if elapsedTime == secondsToWait {
//                self?.timer = nil
//                semaphore.signal()
//            }
//            /// only update the playhead if the timestamp has changed
//            if tracker.getCurrentTimeStamp() != tracker.getLastEventTimeStamp() {
//                if updatePlayhead {
//                    tracker.updateCurrentPlayhead(time: tracker.previousPlayhead + Double(elapsedTime))
//                } else {
//                    /// for paused, seek, or buffer events we want to call updateCurrentPlayhead without incrementing it
//                    /// (similar to the behavior of the MediaPublicTracker dispatching an internal track event)
//                    tracker.updateCurrentPlayhead(time: tracker.previousPlayhead)
//                }
//            }
//            elapsedTime += 1
//            tracker.incrementTimeStamp(value: timestampIncrement)
//        }
//        timer.resume()
//    }

    /// Returns true if the two passed in dictionaries are equal, false otherwise
    func isEqual(map1: [String: Any]?, map2: [String: Any]?) -> Bool {
        if map1 == nil && map2 == nil {
            return true
        }

        guard let map1 = map1, let map2 = map2 else {
            return false
        }

        guard map1.count == map2.count else {
            return false
        }

        for (k1, v1) in map1 {
            guard let v2 = map2[k1] else { return false }
            switch (v1, v2) {
            case (let v1 as Double, let v2 as Double): if !v1.isAlmostEqual(v2) { return false }
            case (let v1 as Int, let v2 as Int): if v1 != v2 { return false }
            case (let v1 as String, let v2 as String): if v1 != v2 { return false }
            case (let v1 as Bool, let v2 as Bool): if v1 != v2 { return false }
            default: return false
            }
        }
        return true
    }
}
