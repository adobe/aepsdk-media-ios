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

class RealTimeFunctionalTests: MediaFunctionalTestBase {
    var session: MediaRealTimeSession!
    var mediaState: MediaState!
    var fakeMediaService: FakeMediaService!
    var dispatchQueue: DispatchQueue!
    var mockMediaData: MockMediaData!

    override func setUp() {
        super.setupBase()
        mockMediaData = MockMediaData()
        dispatchQueue = DispatchQueue(label: "testRealTime")

        mediaState = mockMediaData.mediaState
        mediaState.extractConfigurationInfo(from: mockMediaData.configSharedState)
        mediaState.extractIdentityInfo(from: mockMediaData.identitySharedState)
        mediaState.extractAnalyticsInfo(from: mockMediaData.analyticsSharedState)

        session = MediaRealTimeSession(id: "sessionID", state: mediaState, dispatchQueue: dispatchQueue)
        session.retryDuration = 0
    }

    func compareJsonArray(expected: String, payload: String) -> Bool {
        var result = true
        guard let jsonObj = try? JSONSerialization.jsonObject(with: payload.data(using: .utf8)!, options: []) as? [String: Any] else {
            return false
        }

        let playertime = jsonObj["playerTime"] as? [String: Double] ?? [:]

        let eventType = jsonObj["eventType"] as? String ?? ""
        let playhead =  playertime["playhead"] ?? 0.0
        let ts = playertime["ts"] ?? 0.0
        let actualMediaHit = MediaHit(eventType: eventType, playhead: playhead, ts: Int64(ts), params: jsonObj["params"] as? [String: Any], customMetadata: jsonObj["customMetadata"] as? [String: String], qoeData: jsonObj["qoeData"] as? [String: Any])

        let expectedMediaHit = try? JSONDecoder().decode(MediaHit.self, from: expected.data(using: .utf8)!)
        result = result && compareMediaHits(actual: actualMediaHit, expected: expectedMediaHit!)

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

    func testTrySendHit_success() {
        // setup
        mockNetworkService.expectedResponse = HttpConnection(data: nil, response: HTTPURLResponse(url: URL(string: "https://www.adobe.com")!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: ["Location": "/api/test/sessions/MediaCollectionServerSessionId"]), error: nil)

        // test
        session.handleQueueMediaHit(hit: mockMediaData.sessionStart)
        waitForProcessing()

        let requests = mockNetworkService.calledNetworkRequests
        XCTAssertEqual(1, requests.count)
        XCTAssertTrue(mockNetworkService.connectAsyncCalled)
    }

    func testTrySendHit_ConnectionError_fail_shouldRetry3times() {
        // setup
        mockNetworkService.shouldReturnConnectionError = true

        // test
        session.handleQueueMediaHit(hit: mockMediaData.sessionStart)
        waitForProcessing()

        // verify
        let requests = mockNetworkService.calledNetworkRequests
        XCTAssertEqual(0, session.hits.count)
        XCTAssertEqual(3, requests.count)
        XCTAssertTrue(mockNetworkService.connectAsyncCalled)
    }

    func testTrySendHit_ConnectionError_PassAfter2Retries_UnableToExtractMCSessionID_ShouldNotDeleteHitFromSession() {
        // setup
        session.retryDuration = 1
        mockNetworkService.shouldReturnConnectionError = true

        // test
        session.handleQueueMediaHit(hit: mockMediaData.sessionStart)
        // 1st try
        waitForProcessing(interval: 1)
        // 2nd try
        waitForProcessing(interval: 1)

        // make network request pass
        mockNetworkService.shouldReturnConnectionError = false

        // 3rd try
        waitForProcessing(interval: 1)

        // verify
        let requests = mockNetworkService.calledNetworkRequests
        XCTAssertEqual(1, session.hits.count)
        XCTAssertEqual(3, requests.count)
        XCTAssertTrue(mockNetworkService.connectAsyncCalled)
    }

    func testTrySendHit_ConnectionError_PassAfter2Retries_ExtractMCSessionID_DeleteHitFromSession() {
        // setup
        session.retryDuration = 1
        mockNetworkService.shouldReturnConnectionError = true
        mockNetworkService.expectedResponse = HttpConnection(data: nil, response: HTTPURLResponse(url: URL(string: "https://www.adobe.com")!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: ["Location": "/api/test/sessions/MediaCollectionServerSessionId"]), error: nil)

        // test
        session.handleQueueMediaHit(hit: mockMediaData.sessionStart)
        // 1st try
        waitForProcessing(interval: 1)
        // 2nd try
        waitForProcessing(interval: 1)

        // make network request pass
        mockNetworkService.shouldReturnConnectionError = false

        // 3rd try
        waitForProcessing(interval: 1)

        // verify
        let requests = mockNetworkService.calledNetworkRequests
        XCTAssertEqual(0, session.hits.count)
        XCTAssertEqual(3, requests.count)
        XCTAssertTrue(mockNetworkService.connectAsyncCalled)
    }

    func testTrySendHit_ConnectionError_ShouldNotRetryAfterMaxRetries() {
        // setup
        session.retryDuration = 1
        mockNetworkService.shouldReturnConnectionError = true

        // test
        session.handleQueueMediaHit(hit: mockMediaData.sessionStart)
        // 1st try
        waitForProcessing(interval: 1)

        // make network request pass
        mockNetworkService.shouldReturnConnectionError = false

        // 2nd try
        waitForProcessing(interval: 1)

        // verify
        let requests = mockNetworkService.calledNetworkRequests
        XCTAssertEqual(2, requests.count)
        XCTAssertTrue(mockNetworkService.connectAsyncCalled)
    }

    func testTrySendHitSessionStart_MissingSessionIDResponse_MaxRetries_DropHits() {
        // setup
        mockNetworkService.expectedResponse = HttpConnection(data: nil, response: HTTPURLResponse(url: URL(string: "https://www.adobe.com")!, statusCode: 200, httpVersion: nil, headerFields: [:]), error: nil)

        // test
        dispatchQueue.async {
            self.session.handleQueueMediaHit(hit: self.mockMediaData.sessionStart)
            self.session.handleQueueMediaHit(hit: self.mockMediaData.play)
        }
        waitForProcessing()

        // verify
        let requests = mockNetworkService.calledNetworkRequests
        // dropped the hits
        XCTAssertEqual(0, session.hits.count)
        // play ping not sent
        XCTAssertEqual(3, requests.count)
        XCTAssertTrue(mockNetworkService.connectAsyncCalled)
    }

    func testTrySendHit_Play_Success() {
        // setup
        mockNetworkService.expectedResponse = HttpConnection(data: nil, response: HTTPURLResponse(url: URL(string: "https://www.adobe.com")!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: ["Location": "/api/test/sessions/MediaCollectionServerSessionId"]), error: nil)

        // test
        dispatchQueue.async {
            self.session.handleQueueMediaHit(hit: self.mockMediaData.sessionStart)
            self.session.handleQueueMediaHit(hit: self.mockMediaData.play)
        }
        waitForProcessing()

        // verify
        let requests = mockNetworkService.calledNetworkRequests
        XCTAssertEqual(2, requests.count)
        XCTAssertTrue(mockNetworkService.connectAsyncCalled)

        let sessionStartRequest = requests[0]
        let sessionStartRequestURLString = sessionStartRequest?.connectPayload ?? ""
        let playRequest = requests[1]
        let playRequestURLString = playRequest?.connectPayload ?? ""

        XCTAssertTrue(playRequest?.url.absoluteString.contains("MediaCollectionServerSessionId") ?? false)
        XCTAssertTrue(compareJsonArray(expected: mockMediaData.sessionStartJsonWithState, payload: sessionStartRequestURLString))
        XCTAssertTrue(compareJsonArray(expected: mockMediaData.playJson, payload: playRequestURLString))
    }

    func testAbort_shouldDropRequestInQueueButNotBeingSent() {
        // setup
        mockNetworkService.expectedResponse = HttpConnection(data: nil, response: HTTPURLResponse(url: URL(string: "https://www.adobe.com")!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: ["Location": "/api/test/sessions/MediaCollectionServerSessionId"]), error: nil)

        // test
        dispatchQueue.async {
            self.session.handleQueueMediaHit(hit: self.mockMediaData.sessionStart)
            self.session.handleQueueMediaHit(hit: self.mockMediaData.play)
            self.session.handleQueueMediaHit(hit: self.mockMediaData.pause)
            self.session.handleQueueMediaHit(hit: self.mockMediaData.play)
            self.session.handleQueueMediaHit(hit: self.mockMediaData.complete)
            self.session.abort()
            self.session.handleQueueMediaHit(hit: self.mockMediaData.pause)
            self.session.handleQueueMediaHit(hit: self.mockMediaData.play)
        }
        waitForProcessing()

        // verify
        let requests = mockNetworkService.calledNetworkRequests
        XCTAssertEqual(0, session.hits.count)
        XCTAssertEqual(1, requests.count)
        XCTAssertTrue(mockNetworkService.connectAsyncCalled)

        let sessionStartRequest = requests[0]
        let sessionStartRequestURLString = sessionStartRequest?.connectPayload ?? ""

        XCTAssertTrue(compareJsonArray(expected: mockMediaData.sessionStartJsonWithState, payload: sessionStartRequestURLString))
    }

    func testEnd_ShouldSendAllTheQueuedNetworkRequests_ShouldDropRequestsAfterEnd() {
        // setup
        mockNetworkService.expectedResponse = HttpConnection(data: nil, response: HTTPURLResponse(url: URL(string: "https://www.adobe.com")!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: ["Location": "/api/test/sessions/MediaCollectionServerSessionId"]), error: nil)

        // test
        dispatchQueue.async {
            self.session.handleQueueMediaHit(hit: self.mockMediaData.sessionStart)
            self.session.handleQueueMediaHit(hit: self.mockMediaData.play)
            self.session.handleQueueMediaHit(hit: self.mockMediaData.pause)
            self.session.handleQueueMediaHit(hit: self.mockMediaData.play)
            self.session.handleQueueMediaHit(hit: self.mockMediaData.complete)
            self.session.end()
            self.session.handleQueueMediaHit(hit: self.mockMediaData.pause)
            self.session.handleQueueMediaHit(hit: self.mockMediaData.play)
        }
        waitForProcessing()

        // verify
        let requests = mockNetworkService.calledNetworkRequests
        XCTAssertEqual(0, session.hits.count)
        XCTAssertEqual(5, requests.count)
        XCTAssertTrue(mockNetworkService.connectAsyncCalled)

        let sessionStartRequestURLString = requests[0]?.connectPayload ?? ""
        let playRequestURLString1 = requests[1]?.connectPayload ?? ""
        let pauseRequestURLString = requests[2]?.connectPayload ?? ""
        let playRequestURLString2 = requests[1]?.connectPayload ?? ""
        let completeRequestURLString = requests[4]?.connectPayload ?? ""

        XCTAssertTrue(compareJsonArray(expected: mockMediaData.sessionStartJsonWithState, payload: sessionStartRequestURLString))
        XCTAssertTrue(compareJsonArray(expected: mockMediaData.playJson, payload: playRequestURLString1))
        XCTAssertTrue(compareJsonArray(expected: mockMediaData.pauseJson, payload: pauseRequestURLString))
        XCTAssertTrue(compareJsonArray(expected: mockMediaData.playJson, payload: playRequestURLString2))
        XCTAssertTrue(compareJsonArray(expected: mockMediaData.completeJson, payload: completeRequestURLString))
    }

    func testHandleAbortAfterEnd() {
        // setup
        mockNetworkService.expectedResponse = HttpConnection(data: nil, response: HTTPURLResponse(url: URL(string: "https://www.adobe.com")!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: ["Location": "/api/test/sessions/MediaCollectionServerSessionId"]), error: nil)

        // test
        dispatchQueue.async {
            self.session.handleQueueMediaHit(hit: self.mockMediaData.sessionStart)
            self.session.handleQueueMediaHit(hit: self.mockMediaData.play)
            self.session.end()
            self.session.handleQueueMediaHit(hit: self.mockMediaData.play)
            self.session.abort()
            self.session.handleQueueMediaHit(hit: self.mockMediaData.pause)
        }
        waitForProcessing()

        // verify
        let requests = mockNetworkService.calledNetworkRequests
        XCTAssertEqual(0, session.hits.count)
        XCTAssertEqual(2, requests.count)
        XCTAssertTrue(mockNetworkService.connectAsyncCalled)

        let sessionStartRequestURLString = requests[0]?.connectPayload ?? ""
        let playRequestURLString1 = requests[1]?.connectPayload ?? ""

        XCTAssertTrue(compareJsonArray(expected: mockMediaData.sessionStartJsonWithState, payload: sessionStartRequestURLString))
        XCTAssertTrue(compareJsonArray(expected: mockMediaData.playJson, payload: playRequestURLString1))
    }

    func testHandleEndAfterAbort() {
        // setup
        mockNetworkService.expectedResponse = HttpConnection(data: nil, response: HTTPURLResponse(url: URL(string: "https://www.adobe.com")!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: ["Location": "/api/test/sessions/MediaCollectionServerSessionId"]), error: nil)

        // test
        dispatchQueue.async {
            self.session.handleQueueMediaHit(hit: self.mockMediaData.sessionStart)
            self.session.handleQueueMediaHit(hit: self.mockMediaData.play)
            self.session.abort()
            self.session.handleQueueMediaHit(hit: self.mockMediaData.play)
            self.session.end()
            self.session.handleQueueMediaHit(hit: self.mockMediaData.pause)
        }
        waitForProcessing()

        // verify
        let requests = mockNetworkService.calledNetworkRequests
        XCTAssertEqual(0, session.hits.count)
        XCTAssertEqual(1, requests.count)
        XCTAssertTrue(mockNetworkService.connectAsyncCalled)

        let sessionStartRequestURLString = requests[0]?.connectPayload ?? ""

        XCTAssertTrue(compareJsonArray(expected: mockMediaData.sessionStartJsonWithState, payload: sessionStartRequestURLString))
    }

    func testAbortSessionEndHandler() {
        // setup
        mockNetworkService.expectedResponse = HttpConnection(data: nil, response: HTTPURLResponse(url: URL(string: "https://www.adobe.com")!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: ["Location": "/api/test/sessions/MediaCollectionServerSessionId"]), error: nil)

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
        XCTAssertEqual(0, session.hits.count)
        XCTAssertEqual(1, requests.count)
        XCTAssertTrue(mockNetworkService.connectAsyncCalled)

        let sessionStartRequestURLString = requests[0]?.connectPayload ?? ""

        XCTAssertTrue(compareJsonArray(expected: mockMediaData.sessionStartJsonWithState, payload: sessionStartRequestURLString))
    }

    func testEndSessionEndHandler() {
        // setup
        mockNetworkService.expectedResponse = HttpConnection(data: nil, response: HTTPURLResponse(url: URL(string: "https://www.adobe.com")!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: ["Location": "/api/test/sessions/MediaCollectionServerSessionId"]), error: nil)

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
        let requests = mockNetworkService.calledNetworkRequests
        XCTAssertEqual(0, session.hits.count)
        XCTAssertEqual(2, requests.count)
        XCTAssertTrue(mockNetworkService.connectAsyncCalled)
    }
}
