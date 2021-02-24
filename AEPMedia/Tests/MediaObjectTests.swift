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
    
    static let numberLessThan0 : [Double] = [
        -1,
        -1.0
    ]
    
    static let numberLessThan1 : [Double] = [
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
    func testMediaInfo_ConvenienceInit_NilInfo() {
        XCTAssertNil(MediaInfo(info: nil))
    }
    
    func testMediaInfo_Init_Valid_WithAllRequiredParams_DefaultOptionalValues() {
        let mediaInfo = MediaInfo(id: "testId", name: "testName", streamType: "aod", mediaType: MediaType.Audio, length: 10.1)
        XCTAssertNotNil(mediaInfo)
        
        XCTAssertEqual("testId", mediaInfo?.id)
        XCTAssertEqual("testName", mediaInfo?.name)
        XCTAssertEqual(10.1, mediaInfo?.length)
        XCTAssertEqual("aod", mediaInfo?.streamType)
        XCTAssertEqual(MediaType.Audio, mediaInfo?.mediaType)
        XCTAssertEqual(false, mediaInfo?.resumed)
        XCTAssertEqual(MediaInfo.DEFAULT_PREROLL_WAITING_TIME_IN_MS, mediaInfo?.prerollWaitingTime)
        XCTAssertEqual(false, mediaInfo?.granularAdTracking)
    }
    
    func testMediaInfo_Init_Valid_WithAllParams() {
        let mediaInfo = MediaInfo(id: "testId", name: "testName", streamType: "aod", mediaType: MediaType.Audio, length: 10.1, resumed: true, prerollWaitingTime: 2000, granularAdTracking: true)
        XCTAssertNotNil(mediaInfo)
        
        XCTAssertNotNil(mediaInfo)
        XCTAssertEqual("testId", mediaInfo?.id)
        XCTAssertEqual("testName", mediaInfo?.name)
        XCTAssertEqual(10.1, mediaInfo?.length)
        XCTAssertEqual("aod", mediaInfo?.streamType)
        XCTAssertEqual(MediaType.Audio, mediaInfo?.mediaType)
        XCTAssertEqual(true, mediaInfo?.resumed)
        XCTAssertEqual(2000, mediaInfo?.prerollWaitingTime)
        XCTAssertEqual(true, mediaInfo?.granularAdTracking)
    }
    
    func testMediaInfo_ConvenienceInit_Valid() {
        let mediaInfo = MediaInfo(info: MediaObjectTests.validMediaInfo)
        
        XCTAssertNotNil(mediaInfo)
        XCTAssertEqual("testId", mediaInfo?.id)
        XCTAssertEqual("testName", mediaInfo?.name)
        XCTAssertEqual(10.0, mediaInfo?.length)
        XCTAssertEqual("aod", mediaInfo?.streamType)
        XCTAssertEqual(MediaType.Audio, mediaInfo?.mediaType)
        XCTAssertEqual(true, mediaInfo?.resumed)
        XCTAssertEqual(2000, mediaInfo?.prerollWaitingTime)
        XCTAssertEqual(true, mediaInfo?.granularAdTracking)
    }
    
    func testMediaInfo_ConvenienceInit_MissingData() {
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
            XCTAssertNil(MediaInfo(info: info))
        }
    }
    
    func testMediaInfo_Init_Valid_WithAllRequiredParams_EmptyIdValue() {
        let mediaInfo = MediaInfo(id: "", name: "testName", streamType: "aod", mediaType: MediaType.Audio, length: 10.1)
        XCTAssertNil(mediaInfo)
    }
    
    func testMediaInfo_ConvenienceInit_InvalidID() {
        for v in MediaObjectTests.valuesOtherThanString {
            var info = MediaObjectTests.validMediaInfo
            info[MediaConstants.MediaInfo.ID] = v
            XCTAssertNil(MediaInfo(info: info))
        }
    }
    
    func testMediaInfo_Init_Valid_WithAllRequiredParams_EmptyNameValue() {
        let mediaInfo = MediaInfo(id: "testId", name: "", streamType: "aod", mediaType: MediaType.Audio, length: 10.1)
        XCTAssertNil(mediaInfo)
    }
    
    func testMediaInfo_ConvenienceInit_InvalidName() {
        for v in MediaObjectTests.valuesOtherThanString {
            var info = MediaObjectTests.validMediaInfo
            info[MediaConstants.MediaInfo.NAME] = v
            XCTAssertNil(MediaInfo(info: info))
        }
    }
    
    func testMediaInfo_Init_Valid_WithAllRequiredParams_InvalidLength() {
        for v in MediaObjectTests.numberLessThan0 {
            let mediaInfo = MediaInfo(id: "testId", name: "testName", streamType: "", mediaType: MediaType.Audio, length: v)
            XCTAssertNil(mediaInfo)
        }
        
    }
    
    func testMediaInfo_ConvenienceInit_InvalidLength() {
        for v in MediaObjectTests.valuesOtherThanDouble {
            var info = MediaObjectTests.validMediaInfo
            info[MediaConstants.MediaInfo.LENGTH] = v
            XCTAssertNil(MediaInfo(info: info))
        }
        
        for v in MediaObjectTests.numberLessThan0 {
            var info = MediaObjectTests.validMediaInfo
            info[MediaConstants.MediaInfo.LENGTH] = v
            XCTAssertNil(MediaInfo(info: info))
        }
    }
    
    func testMediaInfo_Init_Valid_WithAllRequiredParams_EmptyStreamTypeValue() {
        let mediaInfo = MediaInfo(id: "testId", name: "testName", streamType: "", mediaType: MediaType.Audio, length: 10.1)
        XCTAssertNil(mediaInfo)
    }
    
    func testMediaInfo_ConvenienceInit_InvalidStreamType() {
        for v in MediaObjectTests.valuesOtherThanString {
            var info = MediaObjectTests.validMediaInfo
            info[MediaConstants.MediaInfo.STREAM_TYPE] = v
            XCTAssertNil(MediaInfo(info: info))
        }
    }
    
    func testMediaInfo_ConvenienceInit_InvalidMediaType() {
        // non empty string other than audio or video is not valid
        for v in MediaObjectTests.values {
            var info = MediaObjectTests.validMediaInfo
            info[MediaConstants.MediaInfo.MEDIA_TYPE] = v
            XCTAssertNil(MediaInfo(info: info))
        }
    }
    
    func testMediaInfo_ConvenienceInit_InvalidResumed() {
        for v in MediaObjectTests.valuesOtherThanBool {
            var info = MediaObjectTests.validMediaInfo
            info[MediaConstants.MediaInfo.RESUMED] = v
            let mediaInfo = MediaInfo(info: info)
            XCTAssertFalse(mediaInfo?.resumed ?? true)
        }
    }
    
    func testMediaInfo_ConvenienceInit_InvalidPrerollTrackingWaitTime() {
        for v in MediaObjectTests.valuesOtherThanDouble {
            var info = MediaObjectTests.validMediaInfo
            info[MediaConstants.MediaInfo.PREROLL_TRACKING_WAITING_TIME] = v
            let mediaInfo = MediaInfo(info: info)
            XCTAssertEqual(MediaInfo.DEFAULT_PREROLL_WAITING_TIME_IN_MS, mediaInfo?.prerollWaitingTime)
        }
    }
    
    func testMediaInfo_ConvenienceInit_InvalidGranularAdTracking() {
        for v in MediaObjectTests.valuesOtherThanBool {
            var info = MediaObjectTests.validMediaInfo
            info[MediaConstants.MediaInfo.GRANULAR_AD_TRACKING] = v
            let mediaInfo = MediaInfo(info: info)
            XCTAssertFalse(mediaInfo?.granularAdTracking ?? true)
        }
    }
    
    func testCreateMediaObjectWithGranularAdTrackingValueCustom() {
        let mediaInfo = MediaInfo(id: "id", name: name, streamType: "vod", mediaType: MediaType.Audio, length: 60.0, prerollWaitingTime: 2000)
        
        XCTAssertEqual(2000.0, mediaInfo?.prerollWaitingTime)
    }
    
    func testCreateMediaObjectWithGranularAdTrackingValueDisabled() {
        let mediaInfo = MediaInfo(id: "id", name: name, streamType: "vod", mediaType: MediaType.Audio, length: 60.0, granularAdTracking: false)
        
        XCTAssertFalse(mediaInfo?.granularAdTracking ?? true)
    }
    
    
    func testCreateMediaObjectWithGranularAdTrackingEnabled() {
        let mediaInfo = MediaInfo(id: "id", name: name, streamType: "vod", mediaType: MediaType.Audio, length: 60.0, granularAdTracking: true)
        
        XCTAssertTrue(mediaInfo?.granularAdTracking ?? false)
    }
    
    func testMediaInfoValidMediaType() {
        var info = MediaObjectTests.validMediaInfo
        let audioInfo = MediaInfo(info: info)
        
        XCTAssertEqual(MediaType.Audio, audioInfo?.mediaType ?? MediaType.Video)
        
        info[MediaConstants.MediaInfo.MEDIA_TYPE] = MediaType.Video.rawValue
        
        let videoInfo = MediaInfo(info: info)
        
        XCTAssertEqual(MediaType.Video, videoInfo?.mediaType ?? MediaType.Audio)
    }
    
    func testMediaInfoEqual() {
        let mediaInfo1 = MediaInfo(info: MediaObjectTests.validMediaInfo)
        
        let mediaInfo2 = MediaInfo(id: "testId", name: "testName", streamType: "aod", mediaType: MediaType.Audio, length: 10.0, resumed: true, prerollWaitingTime: 2000, granularAdTracking: true)
        
        XCTAssertEqual(mediaInfo1, mediaInfo2)
    }
    
    func testMediaInfoToMap() {
        let mediaInfo = MediaInfo(info: MediaObjectTests.validMediaInfo)
        let mediaInfoMap = mediaInfo?.toMap()
        
        XCTAssertEqual(Self.validMediaInfo[MediaConstants.MediaInfo.ID] as! String, mediaInfoMap?[MediaConstants.MediaInfo.ID] as? String ?? "")
        XCTAssertEqual(Self.validMediaInfo[MediaConstants.MediaInfo.NAME] as! String, mediaInfoMap?[MediaConstants.MediaInfo.NAME] as? String ?? "")
        XCTAssertEqual(Self.validMediaInfo[MediaConstants.MediaInfo.LENGTH] as! Double, mediaInfoMap?[MediaConstants.MediaInfo.LENGTH] as? Double ?? 0.0)
        XCTAssertEqual(Self.validMediaInfo[MediaConstants.MediaInfo.STREAM_TYPE] as! String, mediaInfoMap?[MediaConstants.MediaInfo.STREAM_TYPE] as? String ?? "")
        XCTAssertEqual(Self.validMediaInfo[MediaConstants.MediaInfo.MEDIA_TYPE] as! String, mediaInfoMap?[MediaConstants.MediaInfo.MEDIA_TYPE] as? String ?? "")
        XCTAssertEqual(Self.validMediaInfo[MediaConstants.MediaInfo.RESUMED] as! Bool, mediaInfoMap?[MediaConstants.MediaInfo.RESUMED] as? Bool ?? false)
        XCTAssertEqual(Self.validMediaInfo[MediaConstants.MediaInfo.PREROLL_TRACKING_WAITING_TIME] as! Double, mediaInfoMap?[MediaConstants.MediaInfo.PREROLL_TRACKING_WAITING_TIME] as? Double ?? 1000.0)
        XCTAssertEqual(Self.validMediaInfo[MediaConstants.MediaInfo.GRANULAR_AD_TRACKING] as! Bool, mediaInfoMap?[MediaConstants.MediaInfo.GRANULAR_AD_TRACKING] as? Bool ?? false)
    }
}
