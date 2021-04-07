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

enum MediaConstants {
    static let EXTENSION_NAME                           = "com.adobe.module.media"
    static let FRIENDLY_NAME                            = "Media Analytics"
    static let EXTENSION_VERSION                        = "0.0.1"
    static let DATASTORE_NAME                           = EXTENSION_NAME
    static let DATABASE_NAME                            = "com.adobe.module.media"

    enum Networking {
        static let HTTP_TIMEOUT_SECONDS: TimeInterval = 5
        static let HTTP_SUCCESS_RANGE = 200..<300
        static let REQUEST_HEADERS = ["Content-type": "application/json"]
        static let INVALID_RESPONSE = -1
    }

    enum TrackerConfig {
        static let CHANNEL = "config.channel"
        static let DOWNLOADED_CONTENT = "config.downloadedcontent"
    }

    enum Configuration {
        static let SHARED_STATE_NAME = "com.adobe.module.configuration"
        static let GLOBAL_CONFIG_PRIVACY = "global.privacy"
        static let EXPERIENCE_CLOUD_ORGID = "experienceCloud.org"
        static let ANALYTICS_RSID = "analytics.rsids"
        static let ANALYTICS_TRACKING_SERVER = "analytics.server"
        static let MEDIA_TRACKING_SERVER = "media.trackingServer"
        static let MEDIA_COLLECTION_SERVER = "media.collectionServer"
        static let MEDIA_CHANNEL = "media.channel"
        static let MEDIA_OVP = "media.ovp"
        static let MEDIA_PLAYER_NAME = "media.playerName"
        static let MEDIA_APP_VERSION = "media.appVersion"
        static let MEDIA_DEBUG_LOGGING = "media.debugLogging"
    }

    enum Identity {
        static let SHARED_STATE_NAME = "com.adobe.module.identity"
        static let LOC_HINT = "locationhint"
        static let BLOB = "blob"
        static let MARKETING_VISITOR_ID = "mid"
        static let VISITOR_IDS_LIST = "visitoridslist"

    }

    enum Analytics {
        static let SHARED_STATE_NAME = "com.adobe.module.analytics"
        static let VISITOR_ID = "vid"
        static let ANALYTICS_VISITOR_ID = "aid"
    }

    enum Media {
        static let EVENT_TYPE = "com.adobe.eventtype.media"
        static let EVENT_SOURCE_TRACKER_REQUEST = "com.adobe.eventsource.media.requesttracker"
        static let EVENT_SOURCE_TRACKER_RESPONSE = "com.adobe.eventsource.media.responsetracker"
        static let EVENT_SOURCE_TRACK_MEDIA = "com.adobe.eventsource.media.trackmedia"
        static let EVENT_NAME_CREATE_TRACKER = "Media::CreateTrackerRequest"
        static let EVENT_NAME_TRACK_MEDIA = "Media::TrackMedia"
    }

    enum MediaConfig {
        static let CHANNEL = "config.channel"
        static let DOWNLOADED_CONTENT = "config.downloadedcontent"
    }

    enum EventName {
        static let SESSION_START = "sessionstart"
        static let SESSION_END = "sessionend"
        static let PLAY = "play"
        static let PAUSE = "pause"
        static let COMPLETE = "mediacomplete"
        static let BUFFER_START = "bufferstart"
        static let BUFFER_COMPLETE = "buffercomplete"
        static let SEEK_START = "seekstart"
        static let SEEK_COMPLETE = "seekcomplete"
        static let ADBREAK_START = "adbreakstart"
        static let ADBREAK_COMPLETE = "adbreakcomplete"
        static let AD_START = "adstart"
        static let AD_COMPLETE = "adcomplete"
        static let AD_SKIP = "adskip"
        static let CHAPTER_START = "chapterstart"
        static let CHAPTER_COMPLETE = "chaptercomplete"
        static let CHAPTER_SKIP = "chapterskip"
        static let BITRATE_CHANGE = "bitratechange"
        static let ERROR = "error"
        static let QOE_UPDATE = "qoeupdate"
        static let PLAYHEAD_UPDATE = "playheadupdate"
        static let STATE_START = "statestart"
        static let STATE_END = "stateend"
    }

    enum MediaInfo {
        static let NAME   = "media.name"
        static let ID     = "media.id"
        static let LENGTH = "media.length"
        static let MEDIA_TYPE = "media.type"
        static let STREAM_TYPE = "media.streamtype"
        static let RESUMED  = "media.resumed"
        static let PREROLL_TRACKING_WAITING_TIME  = "media.prerollwaitingtime"
        static let GRANULAR_AD_TRACKING  = "media.granularadtracking"
    }

    enum AdBreakInfo {
        static let NAME = "adbreak.name"
        static let POSITION = "adbreak.position"
        static let START_TIME = "adbreak.starttime"
    }
    enum AdInfo {
        static let ID = "ad.id"
        static let NAME = "ad.name"
        static let POSITION = "ad.position"
        static let LENGTH = "ad.length"
    }

    enum ChapterInfo {
        static let NAME = "chapter.name"
        static let POSITION = "chapter.position"
        static let START_TIME = "chapter.starttime"
        static let LENGTH = "chapter.length"
    }

    enum QoEInfo {
        static let BITRATE = "qoe.bitrate"
        static let DROPPED_FRAMES = "qoe.droppedframes"
        static let FPS = "qoe.fps"
        static let STARTUP_TIME = "qoe.startuptime"
    }

    enum ErrorInfo {
        static let ID = "error.id"
        static let SOURCE = "error.source"
    }

    enum StateInfo {
        static let STATE_NAME_KEY = "state.name"
        static let STATE_LIMIT = 10
    }

    enum StandardMediaMetadata {
        static let SHOW = "a.media.show"
        static let SEASON = "a.media.season"
        static let EPISODE = "a.media.episode"
        static let ASSET_ID = "a.media.asset"
        static let GENRE = "a.media.genre"
        static let FIRST_AIR_DATE = "a.media.airDate"
        static let FIRST_DIGITAL_DATE = "a.media.digitalDate"
        static let RATING = "a.media.rating"
        static let ORIGINATOR = "a.media.originator"
        static let NETWORK = "a.media.network"
        static let SHOW_TYPE = "a.media.type"
        static let AD_LOAD = "a.media.adLoad"
        static let MVPD = "a.media.pass.mvpd"
        static let AUTH = "a.media.pass.auth"
        static let DAY_PART = "a.media.dayPart"
        static let FEED = "a.media.feed"
        static let STREAM_FORMAT = "a.media.format"
        static let ARTIST    = "a.media.artist"
        static let ALBUM     = "a.media.album"
        static let LABEL     = "a.media.label"
        static let AUTHOR    = "a.media.author"
        static let STATION   = "a.media.station"
        static let PUBLISHER = "a.media.publisher"
    }

    enum StandardAdMetadata {
        static let ADVERTISER = "a.media.ad.advertiser"
        static let CAMPAIGN_ID = "a.media.ad.campaign"
        static let CREATIVE_ID = "a.media.ad.creative"
        static let PLACEMENT_ID = "a.media.ad.placement"
        static let SITE_ID = "a.media.ad.site"
        static let CREATIVE_URL = "a.media.ad.creativeURL"
    }

    enum Tracker {
        static let ID = "trackerid"
        static let SESSION_ID = "sessionid"
        static let CREATED = "trackercreated"
        static let EVENT_NAME = "event.name"
        static let EVENT_PARAM = "event.param"
        static let EVENT_METADATA = "event.metadata"
        static let EVENT_TIMESTAMP = "event.timestamp"
        static let EVENT_INTERNAL = "event.internal"
        static let PLAYHEAD = "time.playhead"
    }

    enum PingInterval {
        static let DEFAULT_OFFLINE = TimeInterval(50)
        static let DEFAULT_ONLINE = TimeInterval(10)
        static let GRANULAR_AD = TimeInterval(1)
    }

    enum MediaCollection {
        enum EventType {
            static let SESSION_START = "sessionStart"
            static let SESSION_COMPLETE = "sessionComplete"
            static let SESSION_END = "sessionEnd"

            static let ADBREAK_START = "adBreakStart"
            static let ADBREAK_COMPLETE = "adBreakComplete"

            static let AD_START = "adStart"
            static let AD_COMPLETE = "adComplete"
            static let AD_SKIP = "adSkip"

            static let CHAPTER_START = "chapterStart"
            static let CHAPTER_COMPLETE = "chapterComplete"
            static let CHAPTER_SKIP = "chapterSkip"

            static let PLAY = "play"
            static let PING = "ping"
            static let BUFFER_START =  "bufferStart"
            static let PAUSE_START = "pauseStart"

            static let BITRATE_CHANGE = "bitrateChange"
            static let ERROR = "error"

            static let STATE_START = "stateStart"
            static let STATE_END = "stateEnd"
        }

        enum QoE {
            static let BITRATE = "media.qoe.bitrate"
            static let DROPPED_FRAMES = "media.qoe.droppedFrames"
            static let FPS = "media.qoe.framesPerSecond"
            static let STARTUP_TIME = "media.qoe.timeToStart"
            static let ERROR_ID = "media.qoe.errorID"
            static let ERROR_SOURCE = "media.qoe.errorSource"
            static let ERROR_SOURCE_PLAYER = "player"
            static let ERROR_SOURCE_EXTERNAL = "external"
        }

        enum AdBreak {
            static let POD_FRIENDLY_NAME = "media.ad.podFriendlyName"
            static let POD_INDEX = "media.ad.podIndex"
            static let POD_SECOND = "media.ad.podSecond"
        }

        enum Ad {
            static let NAME = "media.ad.name"
            static let ID = "media.ad.id"
            static let LENGTH = "media.ad.length"
            static let POD_POSITION = "media.ad.podPosition"
            static let PLAYER_NAME = "media.ad.playerName"
        }

        enum StandardMediaMetadata {
            static let SHOW = "media.show"
            static let SEASON = "media.season"
            static let EPISODE = "media.episode"
            static let ASSET_ID = "media.assetId"
            static let GENRE = "media.genre"
            static let FIRST_AIR_DATE = "media.firstAirDate"
            static let FIRST_DIGITAL_DATE = "media.firstDigitalDate"
            static let RATING = "media.rating"
            static let ORIGINATOR = "media.originator"
            static let NETWORK = "media.network"
            static let SHOW_TYPE = "media.showType"
            static let AD_LOAD = "media.adLoad"
            static let MVPD = "media.pass.mvpd"
            static let AUTH = "media.pass.auth"
            static let DAY_PART = "media.dayPart"
            static let FEED = "media.feed"
            static let STREAM_FORMAT = "media.streamFormat"
            static let ARTIST = "media.artist"
            static let ALBUM = "media.album"
            static let LABEL = "media.label"
            static let AUTHOR = "media.author"
            static let STATION = "media.station"
            static let PUBLISHER = "media.publisher"
        }

        enum Chapter {
            static let FRIENDLY_NAME = "media.chapter.friendlyName"
            static let LENGTH = "media.chapter.length"
            static let OFFSET = "media.chapter.offset"
            static let INDEX = "media.chapter.index"
        }

        enum StandardAdMetadata {
            static let ADVERTISER = "media.ad.advertiser"
            static let CAMPAIGN_ID = "media.ad.campaignId"
            static let CREATIVE_ID = "media.ad.creativeId"
            static let SITE_ID = "media.ad.siteId"
            static let CREATIVE_URL = "media.ad.creativeURL"
            static let PLACEMENT_ID = "media.ad.placementId"
        }

        enum Media {
            static let ID = "media.id"
            static let NAME = "media.name"
            static let LENGTH = "media.length"
            static let CONTENT_TYPE = "media.contentType"
            static let STREAM_TYPE = "media.streamType"
            static let PLAYER_NAME = "media.playerName"
            static let RESUME = "media.resume"
            static let DOWNLOADED = "media.downloaded"

            static let CHANNEL = "media.channel"
            static let PUBLISHER = "media.publisher"
            static let SDK_VERSION = "media.sdkVersion"
        }                

        enum PlayerTime {
            static let TS = "ts"
            static let PLAYHEAD = "playhead"
        }

        enum Session {
            static let ANALYTICS_TRACKING_SERVER = "analytics.trackingServer"
            static let ANALYTICS_SSL = "analytics.enableSSL"
            static let ANALYTICS_RSID = "analytics.reportSuite"
            static let ANALYTICS_VISITOR_ID = "analytics.visitorId"
            static let ANALYTICS_AID = "analytics.aid"
            static let VISITOR_MCORG_ID = "visitor.marketingCloudOrgId"
            static let VISITOR_MCUSER_ID = "visitor.marketingCloudUserId"
            static let VISITOR_AAM_LOC_HINT = "visitor.aamLocationHint"
            static let VISITOR_CUSTOMER_IDS = "visitor.customerIDs"
            static let MEDIA_CHANNEL = "media.channel"
            static let MEDIA_PLAYER_NAME = "media.playerName"
            static let SDK_VERSION = "media.sdkVersion"
            static let MEDIA_VERSION = "media.libraryVersion"
            static let VISITOR_ID_TYPE = "id_type"
            static let VISITOR_ID = "id"
            static let VISITOR_ID_AUTHENTICATION_STATE = "authentication_state"
        }
    }
}
