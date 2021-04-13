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

    let mediaOfflineHitsMock = MockMediaOfflineHits()

    func testGetTrackingUrl() {
        //Setup
        let host = "abc.com"
        //Action
        let url = MediaCollectionReportHelper.getTrackingURL(host: host)
        //Assert
        XCTAssertEqual(url, "https://\(host)/api/v1/sessions")
    }

    func testGetTrackingUrlForEvents() {
        //Setup
        let host = "abc.com"
        let sessionId = "sessionId"
        //Action
        let url = MediaCollectionReportHelper.getTrackingURLForEvents(host: host, sessionId: sessionId)
        //Assert
        XCTAssertEqual(url, "https://\(host)/api/v1/sessions/\(sessionId)/events")
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
        let hit = mediaOfflineHitsMock.sessionStart!
        let state = mediaOfflineHitsMock.mediaState
        let jsonDecoder = JSONDecoder()

        //Action
        let response = MediaCollectionReportHelper.generateHitReport(state: state!, hit: hit)

        let mediaHitActual = try? jsonDecoder.decode(MediaHit.self, from: response!.data(using: .utf8)!)
        let mediaHitExpected = try? jsonDecoder.decode(MediaHit.self, from: mediaOfflineHitsMock.sessionStartJson!.data(using: .utf8)!)
        let mediaHitUpdated = MediaCollectionReportHelper.updateMediaHit(state: mediaOfflineHitsMock.mediaState, mediaHit: mediaHitExpected!)

        //Assert
        XCTAssertNotNil(response)
        XCTAssertTrue(compareMediaHits(actual: mediaHitActual!, expected: mediaHitUpdated))
    }

    func testGenerateDownloadReportWithEmptyList() {
        //setup
        let hits = [MediaHit]()

        //Action
        let report = MediaCollectionReportHelper.generateDownloadReport(state: mediaOfflineHitsMock.mediaState, hits: hits)

        //Assert
        XCTAssertNil(report)
    }

    func testGenerateReportEmptyMediaState() {
        var hits = [MediaHit]()
        hits.append(mediaOfflineHitsMock.sessionStart)
        hits.append(mediaOfflineHitsMock.play)
        hits.append(mediaOfflineHitsMock.adBreakStart)
        hits.append(mediaOfflineHitsMock.adStart)
        hits.append(mediaOfflineHitsMock.adComplete)
        hits.append(mediaOfflineHitsMock.adBreakComplete)
        hits.append(mediaOfflineHitsMock.ping)
        hits.append(mediaOfflineHitsMock.complete)

        var expectedResponse = [String]()
        expectedResponse.append(mediaOfflineHitsMock.sessionStartJson)
        expectedResponse.append(mediaOfflineHitsMock.playJson)
        expectedResponse.append(mediaOfflineHitsMock.adBreakStartJson)
        expectedResponse.append(mediaOfflineHitsMock.adStartJson)
        expectedResponse.append(mediaOfflineHitsMock.adCompleteJson)
        expectedResponse.append(mediaOfflineHitsMock.adBreakCompleteJson)
        expectedResponse.append(mediaOfflineHitsMock.pingJson)
        expectedResponse.append(mediaOfflineHitsMock.completeJson)

        let payload = MediaCollectionReportHelper.generateDownloadReport(state: mediaOfflineHitsMock.mediaStateEmpty, hits: hits)

        XCTAssertTrue(compareJsonArray(expected: expectedResponse, payload: payload!, state: mediaOfflineHitsMock.mediaStateEmpty))
    }

    func testGenerateReportProperMediaState() {
        var hits = [MediaHit]()
        hits.append(mediaOfflineHitsMock.sessionStart)
        hits.append(mediaOfflineHitsMock.play)
        hits.append(mediaOfflineHitsMock.adBreakStart)
        hits.append(mediaOfflineHitsMock.adStart)
        hits.append(mediaOfflineHitsMock.adComplete)
        hits.append(mediaOfflineHitsMock.adBreakComplete)
        hits.append(mediaOfflineHitsMock.ping)
        hits.append(mediaOfflineHitsMock.complete)

        var expectedResponse = [String]()
        expectedResponse.append(mediaOfflineHitsMock.sessionStartJson)
        expectedResponse.append(mediaOfflineHitsMock.playJson)
        expectedResponse.append(mediaOfflineHitsMock.adBreakStartJson)
        expectedResponse.append(mediaOfflineHitsMock.adStartJson)
        expectedResponse.append(mediaOfflineHitsMock.adCompleteJson)
        expectedResponse.append(mediaOfflineHitsMock.adBreakCompleteJson)
        expectedResponse.append(mediaOfflineHitsMock.pingJson)
        expectedResponse.append(mediaOfflineHitsMock.completeJson)

        let payload = MediaCollectionReportHelper.generateDownloadReport(state: mediaOfflineHitsMock.mediaState, hits: hits)

        XCTAssertTrue(compareJsonArray(expected: expectedResponse, payload: payload!, state: mediaOfflineHitsMock.mediaState))
    }

    func testGenerateReportSessionStartChannelPresent() {
        var hits = [MediaHit]()
        hits.append(mediaOfflineHitsMock.sessionStartChannel)
        hits.append(mediaOfflineHitsMock.play)
        hits.append(mediaOfflineHitsMock.ping)
        hits.append(mediaOfflineHitsMock.complete)

        var expectedResponse = [String]()
        expectedResponse.append(mediaOfflineHitsMock.sessionStartChannelJson)
        expectedResponse.append(mediaOfflineHitsMock.playJson)
        expectedResponse.append(mediaOfflineHitsMock.pingJson)
        expectedResponse.append(mediaOfflineHitsMock.completeJson)

        let payload = MediaCollectionReportHelper.generateDownloadReport(state: mediaOfflineHitsMock.mediaStateEmpty, hits: hits)

        XCTAssertTrue(compareJsonArray(expected: expectedResponse, payload: payload!, state: mediaOfflineHitsMock.mediaStateEmpty))
    }

    func test_generateReport_missingSessionStart() {

        var hits = [MediaHit]()
        hits.append(mediaOfflineHitsMock.play)
        hits.append(mediaOfflineHitsMock.ping)
        hits.append(mediaOfflineHitsMock.complete)

        var expectedResponse = [String]()
        expectedResponse.append(mediaOfflineHitsMock.sessionStartJson)
        expectedResponse.append(mediaOfflineHitsMock.playJson)
        expectedResponse.append(mediaOfflineHitsMock.pingJson)
        expectedResponse.append(mediaOfflineHitsMock.completeJson)

        let payload = MediaCollectionReportHelper.generateDownloadReport(state: mediaOfflineHitsMock.mediaStateEmpty, hits: hits)

        XCTAssertNil(payload)
    }

    func testGenerateReportMissingSessionEndOrComplete() {

        var hits = [MediaHit]()
        hits.append(mediaOfflineHitsMock.sessionStart)
        hits.append(mediaOfflineHitsMock.play)
        hits.append(mediaOfflineHitsMock.ping)

        var expectedResponse = [String]()
        expectedResponse.append(mediaOfflineHitsMock.sessionStartJson)
        expectedResponse.append(mediaOfflineHitsMock.playJson)
        expectedResponse.append(mediaOfflineHitsMock.pingJson)
        expectedResponse.append(mediaOfflineHitsMock.forceSessionEndJson)

        let payload = MediaCollectionReportHelper.generateDownloadReport(state: mediaOfflineHitsMock.mediaStateEmpty, hits: hits)

        XCTAssertTrue(compareJsonArray(expected: expectedResponse, payload: payload!, state: mediaOfflineHitsMock.mediaStateEmpty))
    }

    func testGenerateReportDropHitsTillSessionStart() {
        var hits = [MediaHit]()
        hits.append(mediaOfflineHitsMock.play)
        hits.append(mediaOfflineHitsMock.ping)
        hits.append(mediaOfflineHitsMock.sessionStart)
        hits.append(mediaOfflineHitsMock.play)
        hits.append(mediaOfflineHitsMock.ping)
        hits.append(mediaOfflineHitsMock.complete)

        var expectedResponse = [String]()
        expectedResponse.append(mediaOfflineHitsMock.sessionStartJson)
        expectedResponse.append(mediaOfflineHitsMock.playJson)
        expectedResponse.append(mediaOfflineHitsMock.pingJson)
        expectedResponse.append(mediaOfflineHitsMock.completeJson)

        let payload = MediaCollectionReportHelper.generateDownloadReport(state: mediaOfflineHitsMock.mediaStateEmpty, hits: hits)

        XCTAssertTrue(compareJsonArray(expected: expectedResponse, payload: payload!, state: mediaOfflineHitsMock.mediaStateEmpty))
    }

    func testGenerateReportLocHintException() {

        var hits = [MediaHit]()
        hits.append(mediaOfflineHitsMock.sessionStart)
        hits.append(mediaOfflineHitsMock.play)
        hits.append(mediaOfflineHitsMock.ping)
        hits.append(mediaOfflineHitsMock.complete)

        var expectedResponse = [String]()
        expectedResponse.append(mediaOfflineHitsMock.sessionStartJson)
        expectedResponse.append(mediaOfflineHitsMock.playJson)
        expectedResponse.append(mediaOfflineHitsMock.pingJson)
        expectedResponse.append(mediaOfflineHitsMock.completeJson)

        let payload = MediaCollectionReportHelper.generateDownloadReport(state: mediaOfflineHitsMock.mediaStateLocHintException, hits: hits)

        XCTAssertTrue(compareJsonArray(expected: expectedResponse, payload: payload!, state: mediaOfflineHitsMock.mediaStateLocHintException))
    }

    func testGenerateReportDropHitsAfterSessionEnd() {

        var hits = [MediaHit]()
        hits.append(mediaOfflineHitsMock.sessionStart)
        hits.append(mediaOfflineHitsMock.play)
        hits.append(mediaOfflineHitsMock.ping)
        hits.append(mediaOfflineHitsMock.complete)
        hits.append(mediaOfflineHitsMock.play)
        hits.append(mediaOfflineHitsMock.ping)

        var expectedResponse = [String]()
        expectedResponse.append(mediaOfflineHitsMock.sessionStartJson)
        expectedResponse.append(mediaOfflineHitsMock.playJson)
        expectedResponse.append(mediaOfflineHitsMock.pingJson)
        expectedResponse.append(mediaOfflineHitsMock.completeJson)

        let payload = MediaCollectionReportHelper.generateDownloadReport(state: mediaOfflineHitsMock.mediaStateEmpty, hits: hits)

        XCTAssertTrue(compareJsonArray(expected: expectedResponse, payload: payload!, state: mediaOfflineHitsMock.mediaStateEmpty))
    }

    func compareJsonArray(expected: [String], payload: String, state: MediaState) -> Bool {
        var result = true
        guard let jsonArray = try? JSONSerialization.jsonObject(with: payload.data(using: .utf8)!, options: []) as? [[String: Any]] else {
            return false
        }
        for (i, jsonObj) in jsonArray.enumerated() {
            let playertime = jsonObj["playerTime"] as! [String: Double]
            let actualMediaHit = MediaHit(eventType: jsonObj["eventType"] as! String, playhead: playertime["playhead"]!, ts: playertime["ts"]!, params: jsonObj["params"] as? [String: Any], customMetadata: jsonObj["customMetadata"] as? [String: String], qoeData: jsonObj["qoeData"] as? [String: Any])

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
