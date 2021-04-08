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
@testable import AEPMedia

class MediaTrackerAPITests: MediaFunctionalTestBase {

    private typealias EventType = MediaConstants.MediaCollection.EventType
    private typealias Media = MediaConstants.MediaCollection.Media
    var fakeMediaService: FakeMediaHitProcessor!
    var mediaTracker: MediaEventTracking!
    var mediaEventGenerator: MediaEventGenerator!
    var mediaInfo = MediaInfo(id: "mediaID", name: "mediaName", streamType: "aod", mediaType: MediaType.Audio, length: 30.0)!

    override func setUp() {
        super.setupBase()
        fakeMediaService = FakeMediaHitProcessor()

    }

    func getExpectedSessionStartHit(info: MediaInfo, metadata: [String: String] = [:], qoeData: [String: Any] = [:], downloaded: Bool = false, ts: Double = 0, playhead: Double = 0) -> MediaHit {
        var expectedMediaInfo = MediaCollectionHelper.generateMediaParams(mediaInfo: info, metadata: metadata)
        expectedMediaInfo[Media.DOWNLOADED] = downloaded

        return MediaHit(eventType: EventType.SESSION_START, playhead: playhead, ts: ts, params: expectedMediaInfo, customMetadata: metadata, qoeData: qoeData)
    }

    func createTracker(downloaded: Bool = false) {
        let config = [MediaConstants.TrackerConfig.DOWNLOADED_CONTENT: downloaded]
        mediaTracker = MediaEventTracker(hitProcessor: fakeMediaService, config: config)
        mediaEventGenerator = MediaEventGenerator(config: config)
        mediaEventGenerator.setTimeStamp(value: 0)
    }

    // TrackSessionStart
    func testTrackSessionStartWithoutMetadata() {
        createTracker()

        mediaEventGenerator.trackSessionStart(info: mediaInfo.toMap())
        let event = mediaEventGenerator.dispatchedEvent!
        mediaTracker.track(eventData: event.data)

        waitForProcessing()

        let expectedHit = getExpectedSessionStartHit(info: mediaInfo)
        let actualHit = fakeMediaService.getHitFromActiveSession(index: 0)

        XCTAssertEqual(expectedHit, actualHit)
    }
}
