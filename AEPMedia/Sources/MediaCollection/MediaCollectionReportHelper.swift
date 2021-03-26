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

class MediaCollectionReportHelper {

    private init() {}

    static func getTrackingURL(url: String) -> String {
        //TODO Define this function
        return url
    }

    static func getTrackingURLForEvents(url: String, sessionId: String?) -> String {
        //TODO Define this function.
        return ""
    }

    static func generateHitReport(state: MediaState, hit: [MediaHit]) -> String {
        //TDOO implement this function.
        return "{}" //TODO: Need to modify Unit test: testQueueHit once this function is defined
    }

    static func extractSessionID(sessionResponseFragment: String) -> String? {
        //TDOO implement this function.
        return ""
    }
}
