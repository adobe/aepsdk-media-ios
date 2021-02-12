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

class MediaObjectTests: XCTestCase {
    static let validMediaInfo : [String : Any] = [
        MediaConstants.MediaInfo.ID : "testId",
        MediaConstants.MediaInfo.NAME : "testName",
        MediaConstants.MediaInfo.LENGTH : 10.0,
        MediaConstants.MediaInfo.STREAM_TYPE : "aod",
        MediaConstants.MediaInfo.MEDIA_TYPE : "audio",
        MediaConstants.MediaInfo.RESUMED :true,
        MediaConstants.MediaInfo.PREROLL_TRACKING_WAITING_TIME : 2000.0, //2000 milliseconds
        MediaConstants.MediaInfo.GRANULAR_AD_TRACKING : true
    ]
    
    static let values : [Any] = [
        1,
        false,
        2.3,
        "test",
        [:],
        []
    ]
    
    static let valuesOtherThanBool : [Any] = [
        1,
        2.3,
        "test",
        [:],
        []
    ]
    
    static let valuesOtherThanString : [Any] = [
        1,
        false,
        2.3,
        [:],
        []
    ]
    
    static let valuesOtherThanDouble : [Any] = [
        false,
        "test",
        [:],
        [],
        1,
        0,
        -1
    ]
    
    static let numberLessThan0 : [Any] = [
        -1,
        -1.0
    ]
    
    static let numberLessThan1 : [Any] = [
        0.0,
        0,
        -1,
        -1.0
    ]
    
    override func setUp() {
    }

    override func tearDown() {
    }

    // MARK: MediaObject unit tests
    
    // ==========================================================================
    // MediaInfo
    // ==========================================================================
    func testMediaInfo_NilInfo() {
        XCTAssertNil(MediaInfo.createFrom(info: nil))
    }
    
    func testMediaInfoValid() {
        let mediaInfo = MediaInfo.createFrom(info: MediaObjectTests.validMediaInfo)
        
        XCTAssertNotNil(mediaInfo)
        XCTAssertEqual("testId", mediaInfo?.getId())
        XCTAssertEqual("testName", mediaInfo?.getName())
        XCTAssertEqual(10.0, mediaInfo?.getLength())
        XCTAssertEqual("aod", mediaInfo?.getStreamType())
        XCTAssertEqual(MediaType.Audio, mediaInfo?.getMediaType())
        XCTAssertEqual(true, mediaInfo?.isResumed())
        XCTAssertEqual(TimeInterval(2), mediaInfo?.getPrerollWaitingTime())
        XCTAssertEqual(true, mediaInfo?.isGranularAdTrackingEnabled())
    }
    
    func testMediaInfoMissingData() {
        let requiredKeys = [
            MediaConstants.MediaInfo.ID,
            MediaConstants.MediaInfo.NAME,
            MediaConstants.MediaInfo.STREAM_TYPE,
            MediaConstants.MediaInfo.MEDIA_TYPE,
            MediaConstants.MediaInfo.LENGTH
        ]
        
        for key in requiredKeys {
            var info = MediaObjectTests.validMediaInfo
            info.removeValue(forKey: key)
            XCTAssertNil(MediaInfo.createFrom(info: info))
        }
    }
    
    func testMediaInfoInvalidID() {
        for v in MediaObjectTests.valuesOtherThanString {
            var info = MediaObjectTests.validMediaInfo
            info[MediaConstants.MediaInfo.ID] = v
            XCTAssertNil(MediaInfo.createFrom(info: info))
        }
    }
    
    func testMediaInfoInvalidName() {
        for v in MediaObjectTests.valuesOtherThanString {
            var info = MediaObjectTests.validMediaInfo
            info[MediaConstants.MediaInfo.NAME] = v
            XCTAssertNil(MediaInfo.createFrom(info: info))
        }
    }
    
    func testMediaInfoInvalidLength() {
        for v in MediaObjectTests.valuesOtherThanDouble {
            var info = MediaObjectTests.validMediaInfo
            info[MediaConstants.MediaInfo.LENGTH] = v
            XCTAssertNil(MediaInfo.createFrom(info: info))
        }
        
        for v in MediaObjectTests.numberLessThan0 {
            var info = MediaObjectTests.validMediaInfo
            info[MediaConstants.MediaInfo.LENGTH] = v
            XCTAssertNil(MediaInfo.createFrom(info: info))
        }
    }
    
    func testMediaInfoInvalidStreamType() {
        for v in MediaObjectTests.valuesOtherThanString {
            var info = MediaObjectTests.validMediaInfo
            info[MediaConstants.MediaInfo.STREAM_TYPE] = v
            XCTAssertNil(MediaInfo.createFrom(info: info))
        }
    }
    
    func testMediaInfoInvalidMediaType() {
        // non empty string other than audio or video is not valid
        for v in MediaObjectTests.values {
            var info = MediaObjectTests.validMediaInfo
            info[MediaConstants.MediaInfo.MEDIA_TYPE] = v
            XCTAssertNil(MediaInfo.createFrom(info: info))
        }
    }
    
    func testMediaInfoInvalidResumed() {
        for v in MediaObjectTests.valuesOtherThanBool {
            var info = MediaObjectTests.validMediaInfo
            info[MediaConstants.MediaInfo.RESUMED] = v
            let mediaInfo = MediaInfo.createFrom(info: info)
            XCTAssertFalse(mediaInfo?.isResumed() ?? true)
        }
    }
    
    func testMediaInfoInvalidPrerollTrackingWaitTime() {
        for v in MediaObjectTests.valuesOtherThanDouble {
            var info = MediaObjectTests.validMediaInfo
            info[MediaConstants.MediaInfo.PREROLL_TRACKING_WAITING_TIME] = v
            let mediaInfo = MediaInfo.createFrom(info: info)
            XCTAssertEqual(MediaInfo.DEFAULT_PREROLL_WAITING_TIME_IN_MS/1000, mediaInfo?.getPrerollWaitingTime())
        }
    }
    
    func testMediaInfoInvalidGranularAdTracking() {
        for v in MediaObjectTests.valuesOtherThanBool {
            var info = MediaObjectTests.validMediaInfo
            info[MediaConstants.MediaInfo.GRANULAR_AD_TRACKING] = v
            let mediaInfo = MediaInfo.createFrom(info: info)
            XCTAssertFalse(mediaInfo?.isGranularAdTrackingEnabled() ?? true)
        }
    }
    
    func testCreateMediaObjectWithPrerollWaitTimeDefault() {
        let mediaInfo = MediaInfo.create(id: "id", name: name, streamType: "vod", mediaType: MediaType.Audio, length: 60.0)
        
        XCTAssertEqual(MediaInfo.DEFAULT_PREROLL_WAITING_TIME_IN_MS/1000, mediaInfo?.getPrerollWaitingTime())
    }
    
    func testCreateMediaObjectWithGranularAdTrackingValueCustom() {
        let mediaInfo = MediaInfo.create(id: "id", name: name, streamType: "vod", mediaType: MediaType.Audio, length: 60.0, prerollWaitingTime: 2000)
        
        XCTAssertEqual(2000/1000, mediaInfo?.getPrerollWaitingTime())
    }
    
    func testCreateMediaObjectWithGranularAdTrackingValueDefault() {
        let mediaInfo = MediaInfo.create(id: "id", name: name, streamType: "vod", mediaType: MediaType.Audio, length: 60.0)
        
        XCTAssertFalse(mediaInfo?.isGranularAdTrackingEnabled() ?? true)
    }
    
    func testCreateMediaObjectWithGranularAdTrackingValueDisbaled() {
        let mediaInfo = MediaInfo.create(id: "id", name: name, streamType: "vod", mediaType: MediaType.Audio, length: 60.0, granularAdTracking: false)
        
        XCTAssertFalse(mediaInfo?.isGranularAdTrackingEnabled() ?? true)
    }
    
    
    func testCreateMediaObjectWithDefaultGranularAdTrackingValue() {
        let mediaInfo = MediaInfo.create(id: "id", name: name, streamType: "vod", mediaType: MediaType.Audio, length: 60.0, granularAdTracking: true)
        
        XCTAssertTrue(mediaInfo?.isGranularAdTrackingEnabled() ?? false)
    }
    
    func testMediaInfoValidMediaType() {
        var info = MediaObjectTests.validMediaInfo
        let audioInfo = MediaInfo.createFrom(info: info)
        
        XCTAssertEqual(MediaType.Audio, audioInfo?.getMediaType() ?? MediaType.Video)
        
        info[MediaConstants.MediaInfo.MEDIA_TYPE] = MediaInfo.MEDIA_TYPE_VIDEO
        
        let videoInfo = MediaInfo.createFrom(info: info)
        
        XCTAssertEqual(MediaType.Video, videoInfo?.getMediaType() ?? MediaType.Audio)
    }
    
    func testMediaInfoEqual() {
        let mediaInfo1 = MediaInfo.createFrom(info: MediaObjectTests.validMediaInfo)
        
        let mediaInfo2 = MediaInfo.create(id: "testId", name: "testName", streamType: "aod", mediaType: MediaType.Audio, length: 10.0, resumed: true, prerollWaitingTime: 2000, granularAdTracking: true)
        
        XCTAssertEqual(mediaInfo1, mediaInfo2)
    }
}
