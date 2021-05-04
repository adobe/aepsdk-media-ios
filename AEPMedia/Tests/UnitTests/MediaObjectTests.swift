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
    static let validMediaInfo: [String: Any] = [
        MediaConstants.MediaInfo.ID: "testId",
        MediaConstants.MediaInfo.NAME: "testName",
        MediaConstants.MediaInfo.LENGTH: 10.0,
        MediaConstants.MediaInfo.STREAM_TYPE: "aod",
        MediaConstants.MediaInfo.MEDIA_TYPE: "audio",
        MediaConstants.MediaInfo.RESUMED: true,
        MediaConstants.MediaInfo.PREROLL_TRACKING_WAITING_TIME: 2000, //2000 milliseconds
        MediaConstants.MediaInfo.GRANULAR_AD_TRACKING: true
    ]

    static let validAdbreakInfo: [String: Any] = [
        MediaConstants.AdBreakInfo.NAME: "Adbreakname",
        MediaConstants.AdBreakInfo.POSITION: 1,
        MediaConstants.AdBreakInfo.START_TIME: 0.0
    ]

    static let validAdInfo: [String: Any] = [
        MediaConstants.AdInfo.ID: "AdID",
        MediaConstants.AdInfo.NAME: "AdName",
        MediaConstants.AdInfo.POSITION: 1,
        MediaConstants.AdInfo.LENGTH: 2.5
    ]

    static let validChapterInfo: [String: Any] = [
        MediaConstants.ChapterInfo.NAME: "ChapterName",
        MediaConstants.ChapterInfo.POSITION: 3,
        MediaConstants.ChapterInfo.START_TIME: 3.0,
        MediaConstants.ChapterInfo.LENGTH: 5.0
    ]

    static let validQoEInfo: [String: Any] = [
        MediaConstants.QoEInfo.BITRATE: 24.0,
        MediaConstants.QoEInfo.DROPPED_FRAMES: 2.0,
        MediaConstants.QoEInfo.FPS: 30.0,
        MediaConstants.QoEInfo.STARTUP_TIME: 0.0
    ]

    static let validStateInfo: [String: Any] = [
        MediaConstants.StateInfo.STATE_NAME_KEY: "fullscreen._"
    ]

    static let validStateInfo64Long: [String: Any] = [
        MediaConstants.StateInfo.STATE_NAME_KEY: "1234567890123456789012345678901234567890123456789012345678901234"
    ]

    static let values: [Any] = [
        1,
        false,
        2.3,
        "test",
        [:],
        []
    ]

    static let valuesOtherThanBool: [Any] = [
        1,
        2.3,
        "test",
        [:],
        []
    ]

    static let valuesOtherThanString: [Any] = [
        1,
        false,
        2.3,
        [:],
        []
    ]

    static let valuesOtherThanDouble: [Any] = [
        false,
        "test",
        [:],
        [],
        1,
        0,
        -1
    ]

    static let valuesOtherThanInt: [Any] = [
        false,
        "test",
        [:],
        [],
        1.0
    ]

    static let numberLessThan0Int: [Int] = [
        -1,
    ]

    static let numberLessThan0: [Double] = [
        -1,
        -1.0
    ]

    static let numberLessThan1: [Double] = [
        0.0,
        0,
        -1,
        -1.0
    ]

    static let invalidStateName: [String] = [
        "fullscreen!!",
        "fullscreen@",
        "fullscreen/",
        "fullscreen-",
        "mu$$te",
        "12345678901234567890123456789012345678901234567890123456789012345"
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
        for v in MediaObjectTests.valuesOtherThanInt {
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

        XCTAssertEqual(2000, mediaInfo?.prerollWaitingTime)
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
        XCTAssertEqual(Self.validMediaInfo[MediaConstants.MediaInfo.PREROLL_TRACKING_WAITING_TIME] as! Int, mediaInfoMap?[MediaConstants.MediaInfo.PREROLL_TRACKING_WAITING_TIME] as? Int ?? 1000)
        XCTAssertEqual(Self.validMediaInfo[MediaConstants.MediaInfo.GRANULAR_AD_TRACKING] as! Bool, mediaInfoMap?[MediaConstants.MediaInfo.GRANULAR_AD_TRACKING] as? Bool ?? false)
    }

    // ==========================================================================
    // AdbreakInfo
    // ==========================================================================
    func testAdbreakInfo_ConvenienceInit_NilInfo() {
        XCTAssertNil(AdBreakInfo(info: nil))
    }

    func testAdBreakInfo_Init_Valid_WithAllRequiredParams() {
        let adBreakInfo = AdBreakInfo(name: "adbreakName", position: 3, startTime: 5.5)
        XCTAssertNotNil(adBreakInfo)

        XCTAssertEqual("adbreakName", adBreakInfo?.name)
        XCTAssertEqual(3, adBreakInfo?.position)
        XCTAssertEqual(5.5, adBreakInfo?.startTime)
    }

    func testAdBreakInfo_ConvenienceInit_Valid() {
        let adBreakInfo = AdBreakInfo(info: MediaObjectTests.validAdbreakInfo)

        XCTAssertNotNil(adBreakInfo)
        XCTAssertEqual("Adbreakname", adBreakInfo?.name)
        XCTAssertEqual(1, adBreakInfo?.position)
        XCTAssertEqual(0.0, adBreakInfo?.startTime)
    }

    func testAdBreakInfo_ConvenienceInit_MissingData() {
        let requiredKeys = [
            MediaConstants.AdBreakInfo.NAME,
            MediaConstants.AdBreakInfo.POSITION,
            MediaConstants.AdBreakInfo.START_TIME,
        ]

        for key in requiredKeys {
            var info = MediaObjectTests.validAdbreakInfo
            info.removeValue(forKey: key)
            XCTAssertNil(AdBreakInfo(info: info))
        }
    }

    func testAdBreakInfo_Init_Valid_WithAllRequiredParams_EmptyNameValue() {
        let adBreakInfo = AdBreakInfo(name: "", position: 3, startTime: 5.5)
        XCTAssertNil(adBreakInfo)
    }

    func testAdBreakInfoInvalidName() {
        for v in MediaObjectTests.valuesOtherThanString {
            var info = MediaObjectTests.validAdbreakInfo
            info[MediaConstants.AdBreakInfo.NAME] = v
            XCTAssertNil(AdBreakInfo(info: info))
        }
    }

    func testAdBreakInfo_Init_Valid_WithAllRequiredParams_InvalidPosition() {
        for v in MediaObjectTests.numberLessThan0Int {
            let adBreakInfo = AdBreakInfo(name: "adName", position: v, startTime: 5.5)
            XCTAssertNil(adBreakInfo)
        }
    }

    func testMediaInfoInvalidPosition() {
        for v in MediaObjectTests.numberLessThan1 {
            var info = MediaObjectTests.validAdbreakInfo
            info[MediaConstants.AdBreakInfo.POSITION] = v
            XCTAssertNil(AdBreakInfo(info: info))
        }

        for v2 in MediaObjectTests.valuesOtherThanInt {
            var info = MediaObjectTests.validAdbreakInfo
            info[MediaConstants.AdBreakInfo.POSITION] = v2
            XCTAssertNil(AdBreakInfo(info: info))
        }
    }

    func testAdBreakInfo_Init_Valid_WithAllRequiredParams_InvalidStartTime() {
        for v in MediaObjectTests.numberLessThan0 {
            let adBreakInfo = AdBreakInfo(name: "adName", position: 2, startTime: v)
            XCTAssertNil(adBreakInfo)
        }
    }

    func testMediaInfoInvalidStartTime() {

        for v in MediaObjectTests.valuesOtherThanDouble {
            var info = MediaObjectTests.validAdbreakInfo
            info[MediaConstants.AdBreakInfo.START_TIME] = v
            XCTAssertNil(AdBreakInfo(info: info))
        }

        for v2 in MediaObjectTests.numberLessThan0 {
            var info = MediaObjectTests.validAdbreakInfo
            info[MediaConstants.AdBreakInfo.START_TIME] = v2
            XCTAssertNil(AdBreakInfo(info: info))
        }
    }

    func testAdBreakInfoEqual() {
        let adBreakInfo1 = AdBreakInfo(info: MediaObjectTests.validAdbreakInfo)

        let adBreakInfo2 = AdBreakInfo(name: "Adbreakname", position: 1, startTime: 0.0)

        XCTAssertEqual(adBreakInfo1, adBreakInfo2)
    }

    func testAdBreakInfoToMap() {
        let adBreakInfo = AdBreakInfo(info: MediaObjectTests.validAdbreakInfo)
        let adBreakInfoMap = adBreakInfo?.toMap()

        XCTAssertEqual(Self.validAdbreakInfo[MediaConstants.AdBreakInfo.NAME] as! String, adBreakInfoMap?[MediaConstants.AdBreakInfo.NAME] as? String ?? "")
        XCTAssertEqual(Self.validAdbreakInfo[MediaConstants.AdBreakInfo.POSITION] as! Int, adBreakInfoMap?[MediaConstants.AdBreakInfo.POSITION] as? Int ?? 0)
        XCTAssertEqual(Self.validAdbreakInfo[MediaConstants.AdBreakInfo.START_TIME] as! Double, adBreakInfoMap?[MediaConstants.AdBreakInfo.POSITION] as? Double ?? 0.0)
    }

    // ==========================================================================
    // AdInfo
    // ==========================================================================
    func testAdInfo_ConvenienceInfo_NilInfo() {
        XCTAssertNil(AdInfo(info: nil))
    }

    func testAdInfo_Init_Valid_WithAllRequiredParams() {
        let adInfo = AdInfo(id: "testID", name: "adName", position: 3, length: 30.0)
        XCTAssertNotNil(adInfo)

        XCTAssertEqual("testID", adInfo?.id)
        XCTAssertEqual("adName", adInfo?.name)
        XCTAssertEqual(3, adInfo?.position)
        XCTAssertEqual(30.0, adInfo?.length)
    }

    func testAdInfo_ConvenienceInit_Valid() {
        let adInfo = AdInfo(info: MediaObjectTests.validAdInfo)

        XCTAssertNotNil(adInfo)
        XCTAssertEqual("AdID", adInfo?.id)
        XCTAssertEqual("AdName", adInfo?.name)
        XCTAssertEqual(1, adInfo?.position)
        XCTAssertEqual(2.5, adInfo?.length)
    }

    func testAdInfo_ConvenienceInit_MissingData() {
        let requiredKeys = [
            MediaConstants.AdInfo.ID,
            MediaConstants.AdInfo.NAME,
            MediaConstants.AdInfo.POSITION,
            MediaConstants.AdInfo.LENGTH
        ]

        for key in requiredKeys {
            var info = MediaObjectTests.validAdInfo
            info.removeValue(forKey: key)
            XCTAssertNil(AdInfo(info: info))
        }
    }

    func testAdInfo_Init_Valid_WithAllRequiredParams_EmptyIdValue() {
        let adInfo = AdInfo(id: "", name: "adTestName", position: 5, length: 60.0)
        XCTAssertNil(adInfo)
    }

    func testAdInfo_ConvenienceInit_InvalidId() {
        for v in MediaObjectTests.valuesOtherThanString {
            var info = MediaObjectTests.validAdInfo
            info[MediaConstants.AdInfo.ID] = v
            XCTAssertNil(AdInfo(info: info))
        }
    }

    func testAdInfo_Init_Valid_WithAllRequiredParams_EmptyNameValue() {
        let adInfo = AdInfo(id: "AdId", name: "", position: 5, length: 60.0)
        XCTAssertNil(adInfo)
    }

    func testAdInfo_ConvenienceInit_InvalidName() {
        for v in MediaObjectTests.valuesOtherThanString {
            var info = MediaObjectTests.validAdInfo
            info[MediaConstants.AdInfo.NAME] = v
            XCTAssertNil(AdInfo(info: info))
        }
    }

    func testAdInfo_ConvenienceInit_InvalidPosition() {
        for v in MediaObjectTests.valuesOtherThanInt {
            var adinfo = MediaObjectTests.validAdInfo
            adinfo[MediaConstants.AdInfo.POSITION] = v
            XCTAssertNil(AdInfo(info: adinfo))
        }

        for v in MediaObjectTests.numberLessThan0 {
            var info = MediaObjectTests.validMediaInfo
            info[MediaConstants.MediaInfo.LENGTH] = v
            XCTAssertNil(AdInfo(info: info))
        }
    }

    func testAdInfo_Init_Valid_WithAllRequiredParams_InvalidLength() {
        for v in MediaObjectTests.numberLessThan0 {
            let adInfo = AdInfo(id: "AdId", name: "adName", position: 5, length: v)
            XCTAssertNil(adInfo)
        }
    }

    func testAdInfo_ConvenienceInit_InvalidLength() {
        for v in MediaObjectTests.valuesOtherThanDouble {
            var adinfo = MediaObjectTests.validAdInfo
            adinfo[MediaConstants.AdInfo.LENGTH] = v
            XCTAssertNil(AdInfo(info: adinfo))
        }

        for v in MediaObjectTests.numberLessThan0 {
            var adinfo = MediaObjectTests.validAdInfo
            adinfo[MediaConstants.AdInfo.LENGTH] = v
            XCTAssertNil(AdInfo(info: adinfo))
        }
    }

    func testAdInfoEqual() {
        let adInfo1 = AdInfo(info: MediaObjectTests.validAdInfo)

        let adInfo2 = AdInfo(id: "AdID", name: "AdName", position: 1, length: 2.5)

        XCTAssertEqual(adInfo1, adInfo2)
    }

    func testAdInfoToMap() {
        let adInfo = AdInfo(info: MediaObjectTests.validAdInfo)
        let adInfoMap = adInfo?.toMap()

        XCTAssertEqual(Self.validAdInfo[MediaConstants.AdInfo.ID] as! String, adInfoMap?[MediaConstants.AdInfo.ID] as? String ?? "")
        XCTAssertEqual(Self.validAdInfo[MediaConstants.AdInfo.NAME] as! String, adInfoMap?[MediaConstants.AdInfo.NAME] as? String ?? "")
        XCTAssertEqual(Self.validAdInfo[MediaConstants.AdInfo.POSITION] as! Int, adInfoMap?[MediaConstants.AdInfo.POSITION] as? Int ?? 0)
        XCTAssertEqual(Self.validAdInfo[MediaConstants.AdInfo.LENGTH] as! Double, adInfoMap?[MediaConstants.AdInfo.LENGTH] as? Double ?? 0.0)
    }

    // ==========================================================================
    // ChapterInfo
    // ==========================================================================
    func testChapterInfo_ConvenienceInfo_NilInfo() {
        XCTAssertNil(ChapterInfo(info: nil))
    }

    func testChapterInfo_Init_Valid_WithAllRequiredParams() {
        let chapterInfo = ChapterInfo(name: "chapterName", position: 2, startTime: 5.0, length: 60.0)
        XCTAssertNotNil(chapterInfo)

        XCTAssertEqual("chapterName", chapterInfo?.name)
        XCTAssertEqual(2, chapterInfo?.position)
        XCTAssertEqual(5.0, chapterInfo?.startTime)
        XCTAssertEqual(60.0, chapterInfo?.length)
    }

    func testChapterInfo_ConvenienceInit_Valid() {
        let chapterInfo = ChapterInfo(info: MediaObjectTests.validChapterInfo)

        XCTAssertNotNil(chapterInfo)
        XCTAssertEqual("ChapterName", chapterInfo?.name)
        XCTAssertEqual(3, chapterInfo?.position)
        XCTAssertEqual(3.0, chapterInfo?.startTime)
        XCTAssertEqual(5.0, chapterInfo?.length)
    }

    func testChapterInfo_ConvenienceInit_MissingData() {
        let requiredKeys = [
            MediaConstants.ChapterInfo.NAME,
            MediaConstants.ChapterInfo.POSITION,
            MediaConstants.ChapterInfo.START_TIME,
            MediaConstants.ChapterInfo.LENGTH
        ]

        for key in requiredKeys {
            var info = MediaObjectTests.validChapterInfo
            info.removeValue(forKey: key)
            XCTAssertNil(ChapterInfo(info: info))
        }
    }

    func testChapterInfo_Init_Valid_WithAllRequiredParams_EmptyNameValue() {
        let chapterInfo = ChapterInfo(name: "", position: 2, startTime: 5.0, length: 60.0)
        XCTAssertNil(chapterInfo)
    }

    func testChapterInfo_ConvenienceInit_InvalidName() {
        for v in MediaObjectTests.valuesOtherThanString {
            var info = MediaObjectTests.validChapterInfo
            info[MediaConstants.ChapterInfo.NAME] = v
            XCTAssertNil(ChapterInfo(info: info))
        }
    }

    func testChapterInfo_ConvenienceInit_InvalidPosition() {
        for v in MediaObjectTests.valuesOtherThanDouble {
            var chapterInfo = MediaObjectTests.validAdInfo
            chapterInfo[MediaConstants.ChapterInfo.POSITION] = v
            XCTAssertNil(ChapterInfo(info: chapterInfo))
        }

        for v in MediaObjectTests.numberLessThan0 {
            var info = MediaObjectTests.validChapterInfo
            info[MediaConstants.ChapterInfo.POSITION] = v
            XCTAssertNil(ChapterInfo(info: info))
        }
    }

    func testChapterInfo_Init_Valid_WithAllRequiredParams_InvalidStartTimeValue() {
        for v in MediaObjectTests.numberLessThan0 {
            let chapterInfo = ChapterInfo(name: "chapterName", position: 2, startTime: v, length: 60.0)
            XCTAssertNil(chapterInfo)
        }
    }

    func testChapterInfo_ConvenienceInit_InvalidStartTimeValue() {
        for v in MediaObjectTests.valuesOtherThanDouble {
            var chapterinfo = MediaObjectTests.validChapterInfo
            chapterinfo[MediaConstants.ChapterInfo.START_TIME] = v
            XCTAssertNil(ChapterInfo(info: chapterinfo))
        }

        for v in MediaObjectTests.numberLessThan0 {
            var chapterinfo = MediaObjectTests.validAdInfo
            chapterinfo[MediaConstants.ChapterInfo.START_TIME] = v
            XCTAssertNil(ChapterInfo(info: chapterinfo))
        }
    }

    func testChapterInfo_Init_Valid_WithAllRequiredParams_InvalidLength() {
        for v in MediaObjectTests.numberLessThan0 {
            let chapterInfo = ChapterInfo(name: "chapterName", position: 2, startTime: v, length: 60.0)
            XCTAssertNil(chapterInfo)
        }
    }

    func testChapterInfo_ConvenienceInit_InvalidLength() {
        for v in MediaObjectTests.valuesOtherThanDouble {
            var chapterinfo = MediaObjectTests.validChapterInfo
            chapterinfo[MediaConstants.ChapterInfo.LENGTH] = v
            XCTAssertNil(ChapterInfo(info: chapterinfo))
        }

        for v in MediaObjectTests.numberLessThan0 {
            var chapterinfo = MediaObjectTests.validChapterInfo
            chapterinfo[MediaConstants.ChapterInfo.LENGTH] = v
            XCTAssertNil(ChapterInfo(info: chapterinfo))
        }
    }

    func testChapterInfoEqual() {
        let chapterInfo1 = ChapterInfo(info: MediaObjectTests.validChapterInfo)

        let chapterInfo2 = ChapterInfo(name: "ChapterName", position: 3, startTime: 3.0, length: 5.0)

        XCTAssertEqual(chapterInfo1, chapterInfo2)
    }

    func testChapterInfoToMap() {
        let chapterInfo = ChapterInfo(info: MediaObjectTests.validChapterInfo)
        let chapterInfoMap = chapterInfo?.toMap()

        XCTAssertEqual(Self.validChapterInfo[MediaConstants.ChapterInfo.NAME] as! String, chapterInfoMap?[MediaConstants.ChapterInfo.NAME] as? String ?? "")
        XCTAssertEqual(Self.validChapterInfo[MediaConstants.ChapterInfo.POSITION] as! Int, chapterInfoMap?[MediaConstants.ChapterInfo.POSITION] as? Int ?? 0)
        XCTAssertEqual(Self.validChapterInfo[MediaConstants.ChapterInfo.START_TIME] as! Double, chapterInfoMap?[MediaConstants.ChapterInfo.START_TIME] as? Double ?? 0.0)
        XCTAssertEqual(Self.validChapterInfo[MediaConstants.ChapterInfo.LENGTH] as! Double, chapterInfoMap?[MediaConstants.ChapterInfo.LENGTH] as? Double ?? 0.0)
    }

    // ==========================================================================
    // QoEInfo
    // ==========================================================================
    func testQoEInfo_ConvenienceInfo_NilInfo() {
        XCTAssertNil(QoEInfo(info: nil))
    }

    func testQoEInfo_Init_Valid_WithAllRequiredParams() {
        let qoeInfo = QoEInfo(bitrate: 30.0, droppedFrames: 20.0, fps: 5.0, startupTime: 10.0)
        XCTAssertNotNil(qoeInfo)

        XCTAssertEqual(30.0, qoeInfo?.bitrate)
        XCTAssertEqual(20.0, qoeInfo?.droppedFrames)
        XCTAssertEqual(5.0, qoeInfo?.fps)
        XCTAssertEqual(10.0, qoeInfo?.startupTime)
    }

    func testQoEInfo_ConvenienceInit_Valid() {
        let qoeInfo = QoEInfo(info: MediaObjectTests.validQoEInfo)
        XCTAssertNotNil(qoeInfo)

        XCTAssertEqual(24.0, qoeInfo?.bitrate)
        XCTAssertEqual(2.0, qoeInfo?.droppedFrames)
        XCTAssertEqual(30.0, qoeInfo?.fps)
        XCTAssertEqual(0.0, qoeInfo?.startupTime)
    }

    func testQoEInfo_ConvenienceInit_MissingData() {
        let requiredKeys = [
            MediaConstants.QoEInfo.BITRATE,
            MediaConstants.QoEInfo.DROPPED_FRAMES,
            MediaConstants.QoEInfo.FPS,
            MediaConstants.QoEInfo.STARTUP_TIME
        ]

        for key in requiredKeys {
            var info = MediaObjectTests.validQoEInfo
            info.removeValue(forKey: key)
            XCTAssertNil(QoEInfo(info: info))
        }
    }

    func testQoEInfo_Init_Valid_WithAllRequiredParams_InvalidBitrare() {
        for v in MediaObjectTests.numberLessThan0 {
            let qoeInfo = QoEInfo(bitrate: v, droppedFrames: 20.0, fps: 5.0, startupTime: 10.0)
            XCTAssertNil(qoeInfo)
        }
    }

    func testQoEInfo_ConvenienceInit_InvalidBitrate() {
        for v in MediaObjectTests.valuesOtherThanDouble {
            var qoeInfo = MediaObjectTests.validQoEInfo
            qoeInfo[MediaConstants.QoEInfo.BITRATE] = v
            XCTAssertNil(QoEInfo(info: qoeInfo))
        }

        for v in MediaObjectTests.numberLessThan0 {
            var qoeInfo = MediaObjectTests.validQoEInfo
            qoeInfo[MediaConstants.QoEInfo.BITRATE] = v
            XCTAssertNil(QoEInfo(info: qoeInfo))
        }
    }

    func testQoEInfo_Init_Valid_WithAllRequiredParams_InvalidDroppedFramaes() {
        for v in MediaObjectTests.numberLessThan0 {
            let qoeInfo = QoEInfo(bitrate: 30.0, droppedFrames: v, fps: 5.0, startupTime: 10.0)
            XCTAssertNil(qoeInfo)
        }
    }

    func testQoEInfo_ConvenienceInit_InvalidDroppedFrames() {
        for v in MediaObjectTests.valuesOtherThanDouble {
            var qoeInfo = MediaObjectTests.validQoEInfo
            qoeInfo[MediaConstants.QoEInfo.DROPPED_FRAMES] = v
            XCTAssertNil(QoEInfo(info: qoeInfo))
        }

        for v in MediaObjectTests.numberLessThan0 {
            var qoeInfo = MediaObjectTests.validQoEInfo
            qoeInfo[MediaConstants.QoEInfo.DROPPED_FRAMES] = v
            XCTAssertNil(QoEInfo(info: qoeInfo))
        }
    }

    func testQoEInfo_Init_Valid_WithAllRequiredParams_InvalidFPS() {
        for v in MediaObjectTests.numberLessThan0 {
            let qoeInfo = QoEInfo(bitrate: 30.0, droppedFrames: 20.0, fps: v, startupTime: 10.0)
            XCTAssertNil(qoeInfo)
        }
    }

    func testQoEInfo_ConvenienceInit_InvalidDroppedFPS() {
        for v in MediaObjectTests.valuesOtherThanDouble {
            var qoeInfo = MediaObjectTests.validQoEInfo
            qoeInfo[MediaConstants.QoEInfo.FPS] = v
            XCTAssertNil(QoEInfo(info: qoeInfo))
        }

        for v in MediaObjectTests.numberLessThan0 {
            var qoeInfo = MediaObjectTests.validQoEInfo
            qoeInfo[MediaConstants.QoEInfo.FPS] = v
            XCTAssertNil(QoEInfo(info: qoeInfo))
        }
    }

    func testQoEInfo_Init_Valid_WithAllRequiredParams_InvalidStartupTime() {
        for v in MediaObjectTests.numberLessThan0 {
            let qoeInfo = QoEInfo(bitrate: 30.0, droppedFrames: 20.0, fps: 5.0, startupTime: v)
            XCTAssertNil(qoeInfo)
        }
    }

    func testQoEInfo_ConvenienceInit_InvalidStartupTime() {
        for v in MediaObjectTests.valuesOtherThanDouble {
            var qoeInfo = MediaObjectTests.validQoEInfo
            qoeInfo[MediaConstants.QoEInfo.STARTUP_TIME] = v
            XCTAssertNil(QoEInfo(info: qoeInfo))
        }

        for v in MediaObjectTests.numberLessThan0 {
            var qoeInfo = MediaObjectTests.validQoEInfo
            qoeInfo[MediaConstants.QoEInfo.STARTUP_TIME] = v
            XCTAssertNil(QoEInfo(info: qoeInfo))
        }
    }

    func testQoEInfoEqual() {
        let qoeInfo1 = QoEInfo(info: MediaObjectTests.validQoEInfo)

        let qoeInfo2 = QoEInfo(bitrate: 24.0, droppedFrames: 2.0, fps: 30.0, startupTime: 0.0)

        XCTAssertEqual(qoeInfo1, qoeInfo2)
    }

    func testQoEInfoToMap() {
        let qoeInfo = QoEInfo(info: MediaObjectTests.validQoEInfo)
        let qoeInfoMap = qoeInfo?.toMap()

        XCTAssertEqual(Self.validQoEInfo[MediaConstants.QoEInfo.BITRATE] as! Double, qoeInfoMap?[MediaConstants.QoEInfo.BITRATE] as? Double ?? 0.0)
        XCTAssertEqual(Self.validQoEInfo[MediaConstants.QoEInfo.DROPPED_FRAMES] as! Double, qoeInfoMap?[MediaConstants.QoEInfo.DROPPED_FRAMES] as? Double ?? 0.0)
        XCTAssertEqual(Self.validQoEInfo[MediaConstants.QoEInfo.FPS] as! Double, qoeInfoMap?[MediaConstants.QoEInfo.FPS] as? Double ?? 0.0)
        XCTAssertEqual(Self.validQoEInfo[MediaConstants.QoEInfo.STARTUP_TIME] as! Double, qoeInfoMap?[MediaConstants.QoEInfo.STARTUP_TIME] as? Double ?? 0.0)
    }

    // ==========================================================================
    // StateInfo
    // ==========================================================================
    func testStateInfo_NilInfo() {
        XCTAssertNil(StateInfo(info: nil))
    }

    func testStateInfo_Init_Valid_WithAllRequiredParams() {
        let stateInfo = StateInfo(stateName: "fullscreen")
        XCTAssertNotNil(stateInfo)

        XCTAssertEqual("fullscreen", stateInfo?.stateName)
    }

    func testStateInfo_ConvenienceInit_Valid() {
        let stateInfo = StateInfo(info: MediaObjectTests.validStateInfo)

        XCTAssertNotNil(stateInfo)
        XCTAssertEqual("fullscreen._", stateInfo?.stateName)
    }

    func testStateInfo_ConvenienceInit_Valid64LongValue() {
        let stateInfo = StateInfo(info: MediaObjectTests.validStateInfo64Long)

        XCTAssertNotNil(stateInfo)
        XCTAssertEqual("1234567890123456789012345678901234567890123456789012345678901234", stateInfo?.stateName)
    }

    func testStateInfo_ConvenienceInit_MissingData() {
        let requiredKeys = [
            MediaConstants.StateInfo.STATE_NAME_KEY
        ]

        for key in requiredKeys {
            var info = MediaObjectTests.validStateInfo
            info.removeValue(forKey: key)
            XCTAssertNil(StateInfo(info: info))
        }
    }

    func testStateInfo_EmptyNameValue() {
        let mediaInfo = StateInfo(stateName: "")
        XCTAssertNil(mediaInfo)
    }

    func testStateInfo_InvalidName() {
        for v in MediaObjectTests.invalidStateName {
            var info = MediaObjectTests.validStateInfo
            info[MediaConstants.StateInfo.STATE_NAME_KEY] = v
            XCTAssertNil(StateInfo(info: info))
        }
    }

    func testStateInfoEqual() {
        let stateInfo1 = StateInfo(info: MediaObjectTests.validStateInfo)

        let stateInfo2 = StateInfo(stateName: "fullscreen._")

        XCTAssertEqual(stateInfo1, stateInfo2)
    }

    func testStateInfoToMap() {
        let stateInfo = StateInfo(info: MediaObjectTests.validStateInfo)
        let stateInfoMap = stateInfo?.toMap()

        XCTAssertEqual(Self.validStateInfo[MediaConstants.StateInfo.STATE_NAME_KEY] as! String, stateInfoMap?[MediaConstants.StateInfo.STATE_NAME_KEY] as? String ?? "")
    }
}
