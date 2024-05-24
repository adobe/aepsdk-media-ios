/*
 Copyright 2021 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0
 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific languag governing permissions and limitations under the License.
 */

import Foundation
import AEPServices

class MockNetworking: Networking {
    public var connectAsyncCalled: Bool = false
    public var connectAsyncCalledWithNetworkRequest: NetworkRequest?
    public var connectAsyncCalledWithCompletionHandler: ((HttpConnection) -> Void)?
    public var expectedResponse: HttpConnection?
    public var calledNetworkRequests: [NetworkRequest?] = []
    public var shouldReturnRecoverableURLError: Bool = false
    public var shouldReturnUnrecoverableURLError: Bool = false
    public var shouldReturnRecoverableHTTPError: Bool = false
    public var shouldReturnUnrecoverableHTTPError: Bool = false

    public var shouldReturnGenericError: Bool = false
    private enum error: Error {
        case genericError
    }

    private let gatewayTimeoutHTTPError = HttpConnection(data: nil, response: HTTPURLResponse(url: URL(string: "test.com")!, statusCode: 504, httpVersion: nil, headerFields: nil), error: nil)
    private let notFoundHTTPError = HttpConnection(data: nil, response: HTTPURLResponse(url: URL(string: "test.com")!, statusCode: 400, httpVersion: nil, headerFields: nil), error: nil)
    private let notConnectedToInternetErrorConnection = HttpConnection(data: nil, response: nil, error: URLError(URLError.notConnectedToInternet))
    private let badURLErrorConnection = HttpConnection(data: nil, response: nil, error: URLError(URLError.badURL))
    private let genericErrorConnection = HttpConnection(data: nil, response: nil, error: error.genericError)

    func connectAsync(networkRequest: NetworkRequest, completionHandler: ((HttpConnection) -> Void)? = nil) {
        print("Do nothing \(networkRequest)")
        connectAsyncCalled = true
        connectAsyncCalledWithNetworkRequest = networkRequest
        connectAsyncCalledWithCompletionHandler = completionHandler

        if shouldReturnRecoverableURLError {
            completionHandler?(notConnectedToInternetErrorConnection)
        } else if shouldReturnUnrecoverableURLError {
            completionHandler?(badURLErrorConnection)
        } else if shouldReturnRecoverableHTTPError {
            completionHandler?(gatewayTimeoutHTTPError)
        } else if shouldReturnUnrecoverableHTTPError {
            completionHandler?(notFoundHTTPError)
        } else {
            if let expectedResponse = expectedResponse {
                completionHandler?(expectedResponse)
            }
        }
        calledNetworkRequests.append(networkRequest)
    }

    func reset() {
        connectAsyncCalled = false
        connectAsyncCalledWithNetworkRequest = nil
        connectAsyncCalledWithCompletionHandler = nil
        calledNetworkRequests = []
        shouldReturnRecoverableURLError = false
        shouldReturnUnrecoverableURLError = false
        shouldReturnRecoverableHTTPError = false
        shouldReturnUnrecoverableHTTPError = false
        shouldReturnGenericError = false
    }
}
