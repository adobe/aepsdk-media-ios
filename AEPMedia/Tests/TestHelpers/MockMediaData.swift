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
@testable import AEPMedia
import AEPCore

class MockMediaData {

    var analyticsSharedState: [String: Any]!
    var identitySharedState: [String: Any]!
    var configSharedState: [String: Any]!
    var configSharedStateOptOut: [String: Any]!
    var configSharedStateUnknown: [String: Any]!
    var configSharedStateOptIn: [String: Any]!

    var mediaState: MediaState!
    var mediaStateEmpty: MediaState!
    var mediaStateLocHintException: MediaState!

    var sessionStart: MediaHit!
    var sessionStartJson: String!
    var sessionStartJsonWithState: String!
    var session_start_json_with_configuration_identity_state: String!

    var sessionStartChannel: MediaHit!
    var sessionStartChannelJson: String!

    var adBreakStart: MediaHit!
    var adBreakStartJson: String!

    var adBreakComplete: MediaHit!
    var adBreakCompleteJson: String!

    var adStart: MediaHit!
    var adStartJson: String!
    var adStartJsonWithState: String!

    var adComplete: MediaHit!
    var adCompleteJson: String!

    var play: MediaHit!
    var playJson: String!

    var pause: MediaHit!
    var pauseJson: String!

    var ping: MediaHit!
    var pingJson: String!

    var complete: MediaHit!
    var completeJson: String!

    var forceSessionEndJson: String!
    var forceSessionEndAfterRelaunchJson: String!

    init() {
        mediaStateEmpty = MediaState()

        configSharedStateOptOut = [MediaConstants.Configuration.GLOBAL_CONFIG_PRIVACY: PrivacyStatus.optedOut.rawValue]
        configSharedStateOptIn = [MediaConstants.Configuration.GLOBAL_CONFIG_PRIVACY: PrivacyStatus.optedIn.rawValue]
        configSharedStateUnknown = [MediaConstants.Configuration.GLOBAL_CONFIG_PRIVACY: PrivacyStatus.unknown.rawValue]

        //Config shared state
        configSharedState = [
            MediaConstants.Configuration.GLOBAL_CONFIG_PRIVACY: PrivacyStatus.optedIn.rawValue,
            MediaConstants.Configuration.EXPERIENCE_CLOUD_ORGID: "org_id",
            MediaConstants.Configuration.ANALYTICS_RSID: "rsid",
            MediaConstants.Configuration.ANALYTICS_TRACKING_SERVER: "analytics_server",
            MediaConstants.Configuration.MEDIA_TRACKING_SERVER: "media_server",
            MediaConstants.Configuration.MEDIA_COLLECTION_SERVER: "media_collection_server",
            MediaConstants.Configuration.MEDIA_CHANNEL: "channel",
            MediaConstants.Configuration.MEDIA_PLAYER_NAME: "player_name",
            MediaConstants.Configuration.MEDIA_APP_VERSION: "app_version",
        ]

        //Identity shared state
        var visitorIdList = [[String: Any]]()
        visitorIdList.append(["id": "id_type1", "value": "u111111111", "authstate": 0])
        visitorIdList.append(["id": "id_type2", "value": "1234567890", "authstate": 1])
        visitorIdList.append(["id": "id_type2", "value": "testPushId", "authstate": 2])

        identitySharedState = [
            MediaConstants.Identity.LOC_HINT: "9",
            MediaConstants.Identity.BLOB: "blob",
            MediaConstants.Identity.MARKETING_VISITOR_ID: "mid",
            MediaConstants.Identity.VISITOR_IDS_LIST: visitorIdList
        ]

        //analytics shared state
        analyticsSharedState = [
            MediaConstants.Analytics.VISITOR_ID: "vid",
            MediaConstants.Analytics.ANALYTICS_VISITOR_ID: "aid"
        ]

        //setup Media State
        var sharedState = [String: [String: Any]]()
        sharedState[MediaConstants.Configuration.SHARED_STATE_NAME] = configSharedState
        sharedState[MediaConstants.Identity.SHARED_STATE_NAME] = identitySharedState
        sharedState[MediaConstants.Analytics.SHARED_STATE_NAME] = analyticsSharedState
        mediaState = MediaState()
        mediaState.update(dataMap: sharedState)

        mediaStateLocHintException = MediaState()
        var identitySharedData = [String: Any]()
        identitySharedData[MediaConstants.Identity.LOC_HINT] = "exception"
        mediaStateLocHintException.update(dataMap: [
            MediaConstants.Identity.SHARED_STATE_NAME: identitySharedData
        ])

        //Session Start

        var params = [String: Any]()
        params["media.name"] = "media_name"
        params["media.id"] = "media_id"
        params["media.streamType"] = "video"
        params["media.contentType"] = "vod"
        params["media.length"] = 1800
        params["media.resume"] = false
        params["media.downloaded"] = true

        var metadata = [String: String]()
        metadata["key1"] = "value1"

        var qoeData = [String: Any]()
        qoeData["media.qoe.bitrate"] = 100000
        qoeData["media.qoe.droppedFrames"] = 2
        qoeData["media.qoe.framesPerSecond"] = 23.5
        qoeData["media.qoe.timeToStart"] = 20

        sessionStart = MediaHit(eventType: MediaConstants.MediaCollection.EventType.SESSION_START, playhead: 0, ts: 0, params: params, customMetadata: metadata, qoeData: qoeData)

        sessionStartJson = """
        {
        "playerTime" : {
        "playhead" : 0,
        "ts" : 0
        },
        "customMetadata" : {
        "key1" : "value1"
        },
        "eventType" : "sessionStart",
        "params" : {
        "media.name" : "media_name",
        "media.id" : "media_id",
        "media.streamType" : "video",
        "media.contentType" : "vod",
        "media.length" : 1800,
        "media.downloaded" : true,
        "media.resume" : false,
        "analytics.enableSSL":true,
        "media.libraryVersion":"media-java-1.x.x"
        },
        "qoeData" : {
        "media.qoe.bitrate" : 100000,
        "media.qoe.droppedFrames" : 2,
        "media.qoe.framesPerSecond" : 23.5,
        "media.qoe.timeToStart" : 20
        }
        }
        """

        //channel already present in media hit.
        params["media.channel"] = "media_channel"
        sessionStartChannel = MediaHit(eventType: MediaConstants.MediaCollection.EventType.SESSION_START, playhead: 0, ts: 0, params: params, customMetadata: metadata, qoeData: qoeData)

        sessionStartChannelJson = """
        {
        "playerTime" : {
        "playhead" : 0,
        "ts" : 0
        },
        "customMetadata" : {
        "key1" : "value1"
        },
        "eventType" : "sessionStart",
        "params" : {
        "media.name" : "media_name",
        "media.id" : "media_id",
        "media.streamType" : "video",
        "media.contentType" : "vod",
        "media.length" : 1800,
        "media.downloaded" : true,
        "media.resume" : false,
        "media.channel" : "media_channel",
        "analytics.enableSSL":true,
        "media.libraryVersion":"media-java-1.x.x"
        },
        "qoeData" : {
        "media.qoe.bitrate" : 100000,
        "media.qoe.droppedFrames" : 2,
        "media.qoe.framesPerSecond" : 23.5,
        "media.qoe.timeToStart" : 20
        }
        }
        }

        """

        sessionStartJsonWithState = """
        {
         "playerTime" : {
         "playhead" : 0,
         "ts" : 0
         },
         "customMetadata" : {
         "key1" : "value1"
         },
         "eventType" : "sessionStart",
         "params" : {
         "media.name" : "media_name",
         "media.id" : "media_id",
         "media.streamType" : "video",
         "media.contentType" : "vod",
         "media.length" : 1800,
         "media.downloaded" : true,
         "media.resume" : false,
         "media.channel" : "channel",
         "media.playerName" : "player_name",
         "analytics.enableSSL" : true,
         "analytics.trackingServer" : "analytics_server",
         "analytics.reportSuite" : "rsid",
         "analytics.visitorId" : "vid",
         "analytics.aid" : "aid",
         "visitor.marketingCloudOrgId" : "org_id",
         "visitor.marketingCloudUserId" : "mid",
         "visitor.aamLocationHint" : 9,
         "media.sdkVersion" : "app_version",
         "media.libraryVersion":"media-java-1.x.x",
         "visitor.customerIDs": {
         "id_type1": {
         "id": "u111111111",
         "authState": 0
         },
         "id_type2": {
         "id": "1234567890",
         "authState": 1,
        },
        "id_type3": {
        "id": "testPushId",
        "authState": 2
        }
        }
        },
        "qoeData" : {
        "media.qoe.bitrate" : 100000,
        "media.qoe.droppedFrames" : 2,
        "media.qoe.framesPerSecond" : 23.5,
        "media.qoe.timeToStart" : 20
        }
        }

        """

        sessionStartJsonWithState = """
        {
         "playerTime" : {
         "playhead" : 0,
         "ts" : 0
         },
         "customMetadata" : {
         "key1" : "value1"
         },
         "eventType" : "sessionStart",
         "params" : {
         "media.name" : "media_name",
         "media.id" : "media_id",
         "media.streamType" : "video",
         "media.contentType" : "vod",
         "media.length" : 1800,
         "media.downloaded" : true,
         "media.resume" : false,
         "media.channel" : "channel",
         "media.playerName" : "player_name",
         "analytics.enableSSL" : true,
         "analytics.trackingServer" : "analytics_server",
         "analytics.reportSuite" : "rsid",
         "analytics.visitorId" : "vid",
         "analytics.aid" : "aid",
         "visitor.marketingCloudOrgId" : "org_id",
         "visitor.marketingCloudUserId" : "mid",
         "visitor.aamLocationHint" : 9,
         "media.sdkVersion" : "app_version",
         "media.libraryVersion":"media-java-1.x.x",
         "visitor.customerIDs": {
         "id_type1": {
         "id": "u111111111",
         "authState": 0
         },
         "id_type2": {
         "id": "1234567890",
         "authState": 1,
        },
        "id_type3": {
        "id": "testPushId",
        "authState": 2
        }
        }
        },
        "qoeData" : {
        "media.qoe.bitrate" : 100000,
        "media.qoe.droppedFrames" : 2,
        "media.qoe.framesPerSecond" : 23.5,
        "media.qoe.timeToStart" : 20
        }
        }

        """

        session_start_json_with_configuration_identity_state = """
        {
        "playerTime" : {
        "playhead" : 0,
        "ts" : 0
        },
        "customMetadata" : {
        "key1" : "value1"
        },
         "eventType" : "sessionStart",
         "params" : {
         "media.name" : "media_name",
         "media.id" : "media_id",
         "media.streamType" : "video",
         "media.contentType" : "vod",
         "media.length" : 1800,
         "media.downloaded" : true,
         "media.resume" : false,
         "media.channel" : "channel",
         "media.playerName" : "player_name",
         "analytics.enableSSL" : true,
         "analytics.trackingServer" : "analytics_server",
         "analytics.reportSuite" : "rsid",
         "visitor.marketingCloudOrgId" : "org_id",
         "visitor.marketingCloudUserId" : "mid",
         "visitor.aamLocationHint" : 9,
         "media.sdkVersion" : "app_version",
         "visitor.customerIDs": {
        "id_type1": {
        "id": "u111111111",
        "authState": 0
        },
        "id_type2": {
        "id": "1234567890",
        "authState": 1,
        },
        "id_type3": {
        "id": "testPushId",
        "authState": 2
        }
        }
        },
        "qoeData" : {
        "media.qoe.bitrate" : 100000.0,
        "media.qoe.droppedFrames" : 2.0,
        "media.qoe.framesPerSecond" : 23.5,
        "media.qoe.timeToStart" : 20.0
        }
        }
        """

        //AdBreak Start
        let paramsAdBreak: [String: Any] = [
            "media.ad.podFriendlyName": "adbreak_name",
            "media.ad.podIndex": 1,
            "media.ad.podSecond": 10.0
        ]

        adBreakStart = MediaHit(eventType: MediaConstants.MediaCollection.EventType.ADBREAK_START, playhead: 10, ts: 10000, params: paramsAdBreak, customMetadata: nil, qoeData: nil)

        adBreakStartJson = """
        {
        "playerTime" : {
        "playhead" : 10,
        "ts" : 10000
        },
        "eventType" : "adBreakStart",
        "params" : {
        "media.ad.podFriendlyName" : "adbreak_name",
        "media.ad.podIndex" : 1,
        "media.ad.podSecond" : 10
        }
        }
        """

        //AdBreak Complete
        adBreakComplete = MediaHit(eventType: MediaConstants.MediaCollection.EventType.ADBREAK_COMPLETE, playhead: 10, ts: 30000, params: nil, customMetadata: nil, qoeData: nil)

        adBreakCompleteJson = """
        {
        "playerTime" : {
        "playhead" : 10,
        "ts" : 30000
        },
        "eventType" : "adBreakComplete"
        }
        """

        //Ad Start
        let paramsAdStart: [String: Any] = [
            "media.ad.id": "ad_id",
            "media.ad.name": "ad_name",
            "media.ad.podPosition": 1,
            "media.ad.length": 20
        ]

        adStart = MediaHit(eventType: MediaConstants.MediaCollection.EventType.AD_START, playhead: 10, ts: 10000, params: paramsAdStart, customMetadata: [String: String](), qoeData: [String: Any]())

        adStartJson =
            """
            {
            "playerTime" : {
            "playhead" : 10,
            "ts" : 10000,
            },
            "eventType" : "adStart",
            "params" : {
            "media.ad.id" : "ad_id",
            "media.ad.name" : "ad_name",
            "media.ad.length" : 20,
            "media.ad.podPosition" : 1
            }
            }
            """

        adStartJsonWithState = """
        {
        "playerTime" : {
        "playhead" : 10,
        "ts" : 10000
        },
        "eventType" : "adStart",
        "params" : {
        "media.ad.id" : "ad_id",
        "media.ad.name" : "ad_name",
        "media.ad.length" : 20,
        "media.ad.podPosition" : 1,
        "media.ad.playerName" : "player_name"
        }
        }
        """

        //Ad Complete
        adComplete = MediaHit(eventType: MediaConstants.MediaCollection.EventType.AD_COMPLETE, playhead: 10, ts: 30000, params: nil, customMetadata: nil, qoeData: nil)

        adCompleteJson =  """
        {
        "playerTime" : {
        "playhead" : 10,
        "ts" : 30000
        },
        "eventType" : "adComplete"
        }
        """

        //Play
        play = MediaHit(eventType: MediaConstants.MediaCollection.EventType.PLAY, playhead: 0, ts: 100, params: nil, customMetadata: nil, qoeData: nil)

        playJson = """
        {
        "playerTime" : {
        "playhead" : 0,
        "ts" : 100
        },
        "eventType" : "play"
        }
        """

        //Pause
        pause = MediaHit(eventType: MediaConstants.MediaCollection.EventType.PAUSE_START, playhead: 0, ts: 100, params: nil, customMetadata: nil, qoeData: nil)

        pauseJson = """
                {
                 "playerTime" : {
                        "playhead" : 0,
                        "ts" : 100
                        },
                        "eventType" : "pauseStart"
                        }
        """

        //Ping
        ping = MediaHit(eventType: MediaConstants.MediaCollection.EventType.PING, playhead: 45, ts: 65000, params: nil, customMetadata: nil, qoeData: nil)

        pingJson = """
        {
         "playerTime" : {
               "playhead" : 45,
               "ts" : 65000
               },
               "eventType" : "ping"
               }
        """

        //Session End
        forceSessionEndJson = """
        {
         "playerTime" : {
                         "playhead" : 45,
                          "ts" : 65000
                          },
                          "eventType" : "sessionEnd"
                          }
        """

        //Session End After relaunch
        forceSessionEndAfterRelaunchJson = """
        {
         "playerTime" : {
                         "playhead" : 0,
                          "ts" : 100
                          },
                          "eventType" : "sessionEnd"
                          }
        """

        //Complete
        complete = MediaHit(eventType: MediaConstants.MediaCollection.EventType.SESSION_COMPLETE, playhead: 60, ts: 80000, params: nil, customMetadata: nil, qoeData: nil)

        completeJson = """
        {
         "playerTime" : {
                         "playhead" : 60,
                          "ts" : 80000
                          },
                          "eventType" : "sessionComplete"
                          }
        """
    }
}
