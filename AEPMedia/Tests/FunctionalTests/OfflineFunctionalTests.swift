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

class OfflineFunctionalTests: MediaFunctionalTestBase {
    var session: MediaOfflineSession!
    var mediaState: MediaState!
    var fakeMediaService: FakeMediaService!
    var dispatchQueue: DispatchQueue!
    var mockMediaData: MockMediaData!
    var mediaDBService: MediaDBService!

    override func setUp() {
        super.setupBase()
        mockMediaData = MockMediaData()
        dispatchQueue = DispatchQueue(label: "testOfflineTime")
        mediaState = mockMediaData.mediaState
        mediaState.extractConfigurationInfo(from: mockMediaData.configSharedState)
        mediaState.extractIdentityInfo(from: mockMediaData.identitySharedState)
        mediaState.extractAnalyticsInfo(from: mockMediaData.analyticsSharedState)

        let mediaHitsDatabase = MediaHitsDatabase(databaseName: "test")
        mediaDBService = MediaDBService(mediaHitsDatabase: mediaHitsDatabase)
        session = MediaOfflineSession(id: "sessionID", state: mediaState, dispatchQueue: dispatchQueue, mediaDBService: mediaDBService, dispathFn: { (_: [String: Any]) in })
        session.retryDuration = 0
    }

    override func tearDown() {
        mediaDBService.deleteHits(sessionId: "sessionID")
    }

    func compareJsonArray(expected: [String], payload: String) -> Bool {
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
            result = result && compareMediaHits(actual: actualMediaHit, expected: expectedMediaHit!)
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

    // Tests
    func testTryReportSession_success_shouldDropHitsAfterEnd() {
        // setup
        mockNetworkService.expectedResponse = HttpConnection(data: nil, response: HTTPURLResponse(url: URL(string: "https://www.adobe.com")!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: [:]), error: nil)

        // test
        dispatchQueue.async {
            self.session.handleQueueMediaHit(hit: self.mockMediaData.sessionStart)
            self.session.handleQueueMediaHit(hit: self.mockMediaData.play)
            self.session.handleQueueMediaHit(hit: self.mockMediaData.pause)
            self.session.handleQueueMediaHit(hit: self.mockMediaData.complete)
            self.session.end()
            self.session.handleQueueMediaHit(hit: self.mockMediaData.pause)
            self.session.handleQueueMediaHit(hit: self.mockMediaData.play)
        }
        waitForProcessing()

        // verify
        var expectedResponse = [String]()
        expectedResponse.append(mockMediaData.sessionStartJsonWithState)
        expectedResponse.append(mockMediaData.playJson)
        expectedResponse.append(mockMediaData.pauseJson)
        expectedResponse.append(mockMediaData.completeJson)

        let requests = mockNetworkService.calledNetworkRequests
        XCTAssertEqual(1, requests.count)
        XCTAssertTrue(mockNetworkService.connectAsyncCalled)
        let sessionRequestURLString = requests[0]?.payloadAsString() ?? ""

        XCTAssertTrue(compareJsonArray(expected: expectedResponse, payload: sessionRequestURLString))
    }

    func testTryReportSession_ConnectionError_shouldRetryIndefinitelyUntilNetworkRequestIsSentSuccessfully() {
        // Network disconnected
        mockNetworkService.shouldReturnConnectionError = true
        mockNetworkService.expectedResponse = HttpConnection(data: nil, response: HTTPURLResponse(url: URL(string: "https://www.adobe.com")!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: [:]), error: nil)

        // test
        dispatchQueue.async {
            self.session.handleQueueMediaHit(hit: self.mockMediaData.sessionStart)
            self.session.handleQueueMediaHit(hit: self.mockMediaData.play)
            self.session.handleQueueMediaHit(hit: self.mockMediaData.pause)
            self.session.handleQueueMediaHit(hit: self.mockMediaData.complete)
            self.session.end()
        }
        waitForProcessing()

        let failedNetworkRequestsCount = mockNetworkService.calledNetworkRequests.count

        // Network connected
        mockNetworkService.shouldReturnConnectionError = false
        mockNetworkService.expectedResponse = HttpConnection(data: nil, response: HTTPURLResponse(url: URL(string: "https://www.adobe.com")!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: [:]), error: nil)

        waitForProcessing()

        // verify
        var expectedResponse = [String]()
        expectedResponse.append(mockMediaData.sessionStartJsonWithState)
        expectedResponse.append(mockMediaData.playJson)
        expectedResponse.append(mockMediaData.pauseJson)
        expectedResponse.append(mockMediaData.completeJson)

        let requests = mockNetworkService.calledNetworkRequests
        XCTAssertTrue(mockNetworkService.connectAsyncCalled)
        // Get payload of succeessful network request
        XCTAssertEqual(failedNetworkRequestsCount+1, requests.count)
        let sessionRequestURLString = requests[requests.count-1]?.payloadAsString() ?? ""

        XCTAssertTrue(compareJsonArray(expected: expectedResponse, payload: sessionRequestURLString))
    }

    func testTryAbortSession_ShouldDropAllHitsAndSendNoNetworkRequests() {
        // setup
        mockNetworkService.expectedResponse = HttpConnection(data: nil, response: HTTPURLResponse(url: URL(string: "https://www.adobe.com")!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: [:]), error: nil)

        // test
        dispatchQueue.async {
            self.session.handleQueueMediaHit(hit: self.mockMediaData.sessionStart)
            self.session.handleQueueMediaHit(hit: self.mockMediaData.play)
            self.session.abort()
            self.session.handleQueueMediaHit(hit: self.mockMediaData.pause)
            self.session.handleQueueMediaHit(hit: self.mockMediaData.complete)
        }
        waitForProcessing()

        // verify
        let requests = mockNetworkService.calledNetworkRequests
        XCTAssertEqual(0, requests.count)
        XCTAssertFalse(mockNetworkService.connectAsyncCalled)
    }

    func testHandleEndAfterAbort() {
        // setup
        mockNetworkService.expectedResponse = HttpConnection(data: nil, response: HTTPURLResponse(url: URL(string: "https://www.adobe.com")!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: [:]), error: nil)

        // test
        dispatchQueue.async {
            self.session.handleQueueMediaHit(hit: self.mockMediaData.sessionStart)
            self.session.handleQueueMediaHit(hit: self.mockMediaData.play)
            self.session.abort()
            self.session.handleQueueMediaHit(hit: self.mockMediaData.pause)
            self.session.handleQueueMediaHit(hit: self.mockMediaData.complete)
            self.session.end()
        }
        waitForProcessing()

        // verify
        let requests = mockNetworkService.calledNetworkRequests
        XCTAssertEqual(0, requests.count)
        XCTAssertFalse(mockNetworkService.connectAsyncCalled)
    }

    func testHandleAbortAfterEnd() {
        // setup
        mockNetworkService.expectedResponse = HttpConnection(data: nil, response: HTTPURLResponse(url: URL(string: "https://www.adobe.com")!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: [:]), error: nil)

        // test
        dispatchQueue.async {
            self.session.handleQueueMediaHit(hit: self.mockMediaData.sessionStart)
            self.session.handleQueueMediaHit(hit: self.mockMediaData.play)
            self.session.handleQueueMediaHit(hit: self.mockMediaData.pause)
            self.session.handleQueueMediaHit(hit: self.mockMediaData.complete)
            self.session.end()
            self.session.handleQueueMediaHit(hit: self.mockMediaData.pause)
            self.session.abort()
        }
        waitForProcessing()

        // verify
        var expectedResponse = [String]()
        expectedResponse.append(mockMediaData.sessionStartJsonWithState)
        expectedResponse.append(mockMediaData.playJson)
        expectedResponse.append(mockMediaData.pauseJson)
        expectedResponse.append(mockMediaData.completeJson)

        let requests = mockNetworkService.calledNetworkRequests
        XCTAssertEqual(1, requests.count)
        XCTAssertTrue(mockNetworkService.connectAsyncCalled)
        let sessionRequestURLString = requests[0]?.payloadAsString() ?? ""
        XCTAssertTrue(compareJsonArray(expected: expectedResponse, payload: sessionRequestURLString))
    }

    func testHandleAbortAfterEndButNetworkInRetry_shouldNotDropTheSessionHit() {
        // setup
        mockNetworkService.shouldReturnConnectionError = true

        // test
        dispatchQueue.async {
            self.session.handleQueueMediaHit(hit: self.mockMediaData.sessionStart)
            self.session.handleQueueMediaHit(hit: self.mockMediaData.play)
            self.session.handleQueueMediaHit(hit: self.mockMediaData.pause)
            self.session.handleQueueMediaHit(hit: self.mockMediaData.complete)
            self.session.end()
        }
        waitForProcessing()

        dispatchQueue.async {
            // abort will not go through since session is not active
            self.session.abort()
        }
        waitForProcessing()

        // verify
        let requests = mockNetworkService.calledNetworkRequests
        XCTAssertEqual(4, mediaDBService.getHits(sessionId: "sessionID").count)
        XCTAssertTrue(requests.count > 3)
    }

    func testAbortSessionEndHandler() {
        // setup
        mockNetworkService.expectedResponse = HttpConnection(data: nil, response: HTTPURLResponse(url: URL(string: "https://www.adobe.com")!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: [:]), error: nil)

        // test
        let expectation = XCTestExpectation(description: "SessionEndHandler callback should be called by MediaSession")
        dispatchQueue.async {
            self.session.handleQueueMediaHit(hit: self.mockMediaData.sessionStart)
            self.session.handleQueueMediaHit(hit: self.mockMediaData.play)
            self.session.abort {
                expectation.fulfill()
            }
        }
        self.wait(for: [expectation], timeout: 0.5)
        waitForProcessing()

        // verify
        let requests = mockNetworkService.calledNetworkRequests
        XCTAssertEqual(0, requests.count)
        XCTAssertFalse(mockNetworkService.connectAsyncCalled)
    }

    func testEndSessionEndHandler() {
        // setup
        mockNetworkService.expectedResponse = HttpConnection(data: nil, response: HTTPURLResponse(url: URL(string: "https://www.adobe.com")!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: [:]), error: nil)

        // test
        let expectation = XCTestExpectation(description: "SessionEndHandler callback should be called by MediaSession")
        dispatchQueue.async {
            self.session.handleQueueMediaHit(hit: self.mockMediaData.sessionStart)
            self.session.handleQueueMediaHit(hit: self.mockMediaData.play)
            self.session.end {
                expectation.fulfill()
            }
        }
        self.wait(for: [expectation], timeout: 0.5)
        waitForProcessing()

        // verify
        var expectedResponse = [String]()
        expectedResponse.append(mockMediaData.sessionStartJsonWithState)
        expectedResponse.append(mockMediaData.playJson)
        expectedResponse.append(mockMediaData.sessionEndJson)

        let requests = mockNetworkService.calledNetworkRequests
        XCTAssertEqual(1, requests.count)
        XCTAssertTrue(mockNetworkService.connectAsyncCalled)

        let sessionRequestURLString = requests[0]?.payloadAsString() ?? ""
        XCTAssertTrue(compareJsonArray(expected: expectedResponse, payload: sessionRequestURLString))
    }
}
