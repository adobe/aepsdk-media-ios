/*
 Copyright 2021 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0
 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES  REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

import Foundation

protocol MediaProcessor {

    /// Creates a new `session` and return its `sessionId`.
    ///
    /// - Returns: Unique SessionId for the session.
    func createSession(config: [String:Any]) -> String?

    /// Process the Media Session with id `sessionId`
    ///
    /// - Parameters:
    ///     - sessionId: The id of session to process.
    ///     - hit: object of `MediaHit` to process.
    func processHit(sessionId: String, hit: MediaHit)

    /// Ends the session with id `sessionId`
    ///
    /// - Parameters:
    ///     - sessionId: The id of session to end.
    func endSession(sessionId: String)
}
