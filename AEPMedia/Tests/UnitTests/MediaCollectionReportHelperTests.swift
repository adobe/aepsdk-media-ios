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
import XCTest
@testable import AEPMedia
import AEPCore

class MediaCollectionReportHelperTests: XCTestCase {

    let mockMediaData = MockMediaData()

    func testGetTrackingUrl() {
        //Setup
        let host = "abc.com"
        //Action
        let url = MediaCollectionReportHelper.getTrackingURL(host: host)
        //Assert
        XCTAssertEqual(url, URL(string: "https://\(host)/api/v1/sessions"))
    }

    func testGetTrackingUrlForEvents() {
        //Setup
        let host = "abc.com"
        let sessionId = "sessionId"
        //Action
        let url = MediaCollectionReportHelper.getTrackingURLForEvents(host: host, sessionId: sessionId)
        //Assert
        XCTAssertEqual(url, URL(string: "https://\(host)/api/v1/sessions/\(sessionId)/events"))
    }

    func testHasAllTrackingParameterReturnsTrue() {
        //Setup
        let sharedData = [
            MediaConstants.Configuration.SHARED_STATE_NAME: [
                MediaConstants.Configuration.GLOBAL_CONFIG_PRIVACY: PrivacyStatus.optedIn.rawValue,
                MediaConstants.Configuration.EXPERIENCE_CLOUD_ORGID: "orgid",
                MediaConstants.Configuration.ANALYTICS_TRACKING_SERVER: "analytics_tracking_Server",
                MediaConstants.Configuration.MEDIA_COLLECTION_SERVER: "media_collection_Server",
                MediaConstants.Configuration.ANALYTICS_RSID: "analytics_rsid"
            ],
            MediaConstants.Identity.SHARED_STATE_NAME: [
                MediaConstants.Identity.MARKETING_VISITOR_ID: "ecid"
            ]
        ]
        let state = MediaState()
        //Action
        state.update(dataMap: sharedData)
        let hasAllTrackingParams = MediaCollectionReportHelper.hasAllTrackingParams(state: state)

        //Assert
        XCTAssertTrue(hasAllTrackingParams)
    }

    func testHasAllTrackingParameterReturnsFalse() {
        //Setup
        let sharedData = [
            MediaConstants.Configuration.SHARED_STATE_NAME: [
                MediaConstants.Configuration.GLOBAL_CONFIG_PRIVACY: PrivacyStatus.optedIn.rawValue,
                MediaConstants.Configuration.ANALYTICS_TRACKING_SERVER: "analytics_tracking_Server",
                MediaConstants.Configuration.MEDIA_COLLECTION_SERVER: "media_collection_Server",
                MediaConstants.Configuration.ANALYTICS_RSID: "analytics_rsid"
            ],
            MediaConstants.Identity.SHARED_STATE_NAME: [
                MediaConstants.Identity.MARKETING_VISITOR_ID: "ecid"
            ]
        ]
        let state = MediaState()
        //Action
        state.update(dataMap: sharedData)
        let hasAllTrackingParams = MediaCollectionReportHelper.hasAllTrackingParams(state: state)

        //Assert
        XCTAssertFalse(hasAllTrackingParams)
    }

    func testExtractSessionIdSuccess() {
        //Setup
        let sessionIdActual = "1337d8e42b67c1c9be55b5b3ebdd3ea145006c3adb5877949ed407fe2d50ec5d"
        let sessionResponseFragment = "/api/v1/sessions/\(sessionIdActual)"
        //Action
        let sessionId = MediaCollectionReportHelper.extractSessionID(sessionResponseFragment: sessionResponseFragment)
        //Assert
        XCTAssertEqual(sessionId, sessionIdActual)
    }

    func testExtractSessionIdFailure() {
        //Setup
        let sessionIdActual = "1337d8e42b67c1c9be55b5b3ebdd3ea145006c3adb5877949ed407fe2d50ec5d"
        let sessionResponseFragment = "/api/v1/\(sessionIdActual)"
        //Action
        let sessionId = MediaCollectionReportHelper.extractSessionID(sessionResponseFragment: sessionResponseFragment)
        //Assert
        XCTAssertNil(sessionId)
    }

    func testGenerateHitReport() {
        //Setup
        let hit = mockMediaData.sessionStart!
        let state = mockMediaData.mediaState
        let jsonDecoder = JSONDecoder()

        //Action
        let response = MediaCollectionReportHelper.generateHitReport(state: state!, hit: hit)

        let mediaHitActual = try? jsonDecoder.decode(MediaHit.self, from: response!.data(using: .utf8)!)
        let mediaHitExpected = try? jsonDecoder.decode(MediaHit.self, from: mockMediaData.sessionStartJson!.data(using: .utf8)!)
        let mediaHitUpdated = MediaCollectionReportHelper.updateMediaHit(state: mockMediaData.mediaState, mediaHit: mediaHitExpected!)

        //Assert
        XCTAssertNotNil(response)
        XCTAssertTrue(compareMediaHits(actual: mediaHitActual!, expected: mediaHitUpdated))
    }

    func testGenerateDownloadReportWithEmptyList() {
        //setup
        let hits = [MediaHit]()

        //Action
        let report = MediaCollectionReportHelper.generateDownloadReport(state: mockMediaData.mediaState, hits: hits)

        //Assert
        XCTAssertNil(report)
    }

    func testGenerateReportEmptyMediaState() {
        var hits = [MediaHit]()
        hits.append(mockMediaData.sessionStart)
        hits.append(mockMediaData.play)
        hits.append(mockMediaData.adBreakStart)
        hits.append(mockMediaData.adStart)
        hits.append(mockMediaData.adComplete)
        hits.append(mockMediaData.adBreakComplete)
        hits.append(mockMediaData.ping)
        hits.append(mockMediaData.complete)

        var expectedResponse = [String]()
        expectedResponse.append(mockMediaData.sessionStartJson)
        expectedResponse.append(mockMediaData.playJson)
        expectedResponse.append(mockMediaData.adBreakStartJson)
        expectedResponse.append(mockMediaData.adStartJson)
        expectedResponse.append(mockMediaData.adCompleteJson)
        expectedResponse.append(mockMediaData.adBreakCompleteJson)
        expectedResponse.append(mockMediaData.pingJson)
        expectedResponse.append(mockMediaData.completeJson)

        let payload = MediaCollectionReportHelper.generateDownloadReport(state: mockMediaData.mediaStateEmpty, hits: hits)

        XCTAssertTrue(compareJsonArray(expected: expectedResponse, payload: payload!, state: mockMediaData.mediaStateEmpty))
    }

    func testGenerateReportProperMediaState() {
        var hits = [MediaHit]()
        hits.append(mockMediaData.sessionStart)
        hits.append(mockMediaData.play)
        hits.append(mockMediaData.adBreakStart)
        hits.append(mockMediaData.adStart)
        hits.append(mockMediaData.adComplete)
        hits.append(mockMediaData.adBreakComplete)
        hits.append(mockMediaData.ping)
        hits.append(mockMediaData.complete)

        var expectedResponse = [String]()
        expectedResponse.append(mockMediaData.sessionStartJson)
        expectedResponse.append(mockMediaData.playJson)
        expectedResponse.append(mockMediaData.adBreakStartJson)
        expectedResponse.append(mockMediaData.adStartJson)
        expectedResponse.append(mockMediaData.adCompleteJson)
        expectedResponse.append(mockMediaData.adBreakCompleteJson)
        expectedResponse.append(mockMediaData.pingJson)
        expectedResponse.append(mockMediaData.completeJson)

        let payload = MediaCollectionReportHelper.generateDownloadReport(state: mockMediaData.mediaState, hits: hits)

        XCTAssertTrue(compareJsonArray(expected: expectedResponse, payload: payload!, state: mockMediaData.mediaState))
    }

    func testGenerateReportSessionStartChannelPresent() {
        var hits = [MediaHit]()
        hits.append(mockMediaData.sessionStartChannel)
        hits.append(mockMediaData.play)
        hits.append(mockMediaData.ping)
        hits.append(mockMediaData.complete)

        var expectedResponse = [String]()
        expectedResponse.append(mockMediaData.sessionStartChannelJson)
        expectedResponse.append(mockMediaData.playJson)
        expectedResponse.append(mockMediaData.pingJson)
        expectedResponse.append(mockMediaData.completeJson)

        let payload = MediaCollectionReportHelper.generateDownloadReport(state: mockMediaData.mediaStateEmpty, hits: hits)

        XCTAssertTrue(compareJsonArray(expected: expectedResponse, payload: payload!, state: mockMediaData.mediaStateEmpty))
    }

    func test_generateReport_missingSessionStart() {

        var hits = [MediaHit]()
        hits.append(mockMediaData.play)
        hits.append(mockMediaData.ping)
        hits.append(mockMediaData.complete)

        var expectedResponse = [String]()
        expectedResponse.append(mockMediaData.sessionStartJson)
        expectedResponse.append(mockMediaData.playJson)
        expectedResponse.append(mockMediaData.pingJson)
        expectedResponse.append(mockMediaData.completeJson)

        let payload = MediaCollectionReportHelper.generateDownloadReport(state: mockMediaData.mediaStateEmpty, hits: hits)

        XCTAssertNil(payload)
    }

    func testGenerateReportMissingSessionEndOrComplete() {

        var hits = [MediaHit]()
        hits.append(mockMediaData.sessionStart)
        hits.append(mockMediaData.play)
        hits.append(mockMediaData.ping)

        var expectedResponse = [String]()
        expectedResponse.append(mockMediaData.sessionStartJson)
        expectedResponse.append(mockMediaData.playJson)
        expectedResponse.append(mockMediaData.pingJson)
        expectedResponse.append(mockMediaData.forceSessionEndJson)

        let payload = MediaCollectionReportHelper.generateDownloadReport(state: mockMediaData.mediaStateEmpty, hits: hits)

        XCTAssertTrue(compareJsonArray(expected: expectedResponse, payload: payload!, state: mockMediaData.mediaStateEmpty))
    }

    func testGenerateReportDropHitsTillSessionStart() {
        var hits = [MediaHit]()
        hits.append(mockMediaData.play)
        hits.append(mockMediaData.ping)
        hits.append(mockMediaData.sessionStart)
        hits.append(mockMediaData.play)
        hits.append(mockMediaData.ping)
        hits.append(mockMediaData.complete)

        var expectedResponse = [String]()
        expectedResponse.append(mockMediaData.sessionStartJson)
        expectedResponse.append(mockMediaData.playJson)
        expectedResponse.append(mockMediaData.pingJson)
        expectedResponse.append(mockMediaData.completeJson)

        let payload = MediaCollectionReportHelper.generateDownloadReport(state: mockMediaData.mediaStateEmpty, hits: hits)

        XCTAssertTrue(compareJsonArray(expected: expectedResponse, payload: payload!, state: mockMediaData.mediaStateEmpty))
    }

    func testGenerateReportLocHintException() {

        var hits = [MediaHit]()
        hits.append(mockMediaData.sessionStart)
        hits.append(mockMediaData.play)
        hits.append(mockMediaData.ping)
        hits.append(mockMediaData.complete)

        var expectedResponse = [String]()
        expectedResponse.append(mockMediaData.sessionStartJson)
        expectedResponse.append(mockMediaData.playJson)
        expectedResponse.append(mockMediaData.pingJson)
        expectedResponse.append(mockMediaData.completeJson)

        let payload = MediaCollectionReportHelper.generateDownloadReport(state: mockMediaData.mediaStateLocHintException, hits: hits)

        XCTAssertTrue(compareJsonArray(expected: expectedResponse, payload: payload!, state: mockMediaData.mediaStateLocHintException))
    }

    func testGenerateReportDropHitsAfterSessionEnd() {

        var hits = [MediaHit]()
        hits.append(mockMediaData.sessionStart)
        hits.append(mockMediaData.play)
        hits.append(mockMediaData.ping)
        hits.append(mockMediaData.complete)
        hits.append(mockMediaData.play)
        hits.append(mockMediaData.ping)

        var expectedResponse = [String]()
        expectedResponse.append(mockMediaData.sessionStartJson)
        expectedResponse.append(mockMediaData.playJson)
        expectedResponse.append(mockMediaData.pingJson)
        expectedResponse.append(mockMediaData.completeJson)

        let payload = MediaCollectionReportHelper.generateDownloadReport(state: mockMediaData.mediaStateEmpty, hits: hits)

        XCTAssertTrue(compareJsonArray(expected: expectedResponse, payload: payload!, state: mockMediaData.mediaStateEmpty))
    }

    func compareJsonArray(expected: [String], payload: String, state: MediaState) -> Bool {
        var result = true
        guard let jsonArray = try? JSONSerialization.jsonObject(with: payload.data(using: .utf8)!, options: []) as? [[String: Any]] else {
            return false
        }
        for (i, jsonObj) in jsonArray.enumerated() {
            let playertime = jsonObj["playerTime"] as? [String: Double] ?? [:]

            let eventType = jsonObj["eventType"] as? String ?? ""
            let playhead =  playertime["playhead"] ?? 0.0
            let ts = playertime["ts"] ?? 0.0
            let actualMediaHit = MediaHit(eventType: eventType, playhead: playhead, ts: Int64(ts), params: jsonObj["params"] as? [String: Any], customMetadata: jsonObj["customMetadata"] as? [String: String], qoeData: jsonObj["qoeData"] as? [String: Any])

            let expectedMediaHit = try? JSONDecoder().decode(MediaHit.self, from: expected[i].data(using: .utf8)!)
            result = result && compareMediaHits(actual: actualMediaHit, expected: MediaCollectionReportHelper.updateMediaHit(state: state, mediaHit: expectedMediaHit!))
        }
        return result
    }

    func compareMediaHits(actual: MediaHit, expected: MediaHit) -> Bool {
        var result = true
        result = result && actual.eventType == expected.eventType
        result = result && actual.timestamp == expected.timestamp
        result = result && actual.playhead == expected.playhead
        result = result && actual.params?.count ?? 0 == expected.params?.count ?? 0
        result = result && actual.metadata?.count ?? 0 == expected.metadata?.count ?? 0
        result = result && actual.qoeData?.count ?? 0 == expected.qoeData?.count ?? 0
        return result
    }
}
