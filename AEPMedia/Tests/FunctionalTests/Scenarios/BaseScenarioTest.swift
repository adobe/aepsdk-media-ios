/*
 Copyright 2020 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0
 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

import XCTest
@testable import AEPMedia

class BaseScenarioTest: XCTestCase {
    var mediaTracker: MediaEventGenerator!
    var fakeMediaService: FakeMediaHitProcessor!
    var mediaEventTracker: MediaEventTracking!

    func setup() {
        self.fakeMediaService = FakeMediaHitProcessor()
        createTracker()
    }

    func createTracker(downloaded: Bool = false) {
        let config = [MediaConstants.TrackerConfig.DOWNLOADED_CONTENT: downloaded]
        mediaEventTracker = MediaEventTracker(hitProcessor: fakeMediaService, config: config)
        mediaTracker = MediaEventGenerator(config: config)
        mediaTracker.connectCoreTracker(tracker: mediaEventTracker)
        mediaTracker.setTimeStamp(value: 0)
    }

    func waitFor(time: Int, updatePlayhead: Bool) {
        for _ in 1...time/1000 {
            mediaTracker.incrementTimeStamp(value: 1000)
            mediaTracker.incrementCurrentPlayhead(time: updatePlayhead ? 1 : 0)
        }
    }

    func checkHits(expectedHits: [MediaHit], sessionId: String = "0", actualHitIndexList: [Int] = []) {
        if actualHitIndexList.count != 0 {
            XCTAssertEqual(expectedHits.count, actualHitIndexList.count, "No of expected hits (\(expectedHits.count)) not equal to actual hits (\(actualHitIndexList.count))")

            for i in 0...expectedHits.count-1 {
                XCTAssertEqual(expectedHits[i], processHit(fakeMediaService.getHit(sessionId: sessionId, index: actualHitIndexList[i])))
            }
        } else {
            let actualHitsCount = fakeMediaService.getHitCount(sessionId: sessionId)
            XCTAssertEqual(expectedHits.count, actualHitsCount, "No of expected hits (\(expectedHits.count)) not equal to actual hits (\(actualHitsCount))")
            for i in 0...expectedHits.count-1 {
                XCTAssertEqual(expectedHits[i], processHit(fakeMediaService.getHit(sessionId: sessionId, index: i)))
            }
        }
    }

    func processHit(_ mediaHit: MediaHit?) -> MediaHit? {
        // If sessionStart, check if present and remove client session id from the hit.
        guard let hit = mediaHit, hit.eventType == MediaConstants.MediaCollection.EventType.SESSION_START else { return mediaHit }

        XCTAssertTrue(hit.params?.keys.contains(MediaConstants.Tracker.SESSION_ID) ?? false)
        var params = hit.params
        params?.removeValue(forKey: MediaConstants.Tracker.SESSION_ID)
        return MediaHit(eventType: hit.eventType, playhead: hit.playhead, ts: hit.timestamp, params: params, customMetadata: hit.metadata, qoeData: hit.qoeData)
    }
}
