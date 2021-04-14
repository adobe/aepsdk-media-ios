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

class TestConstants {
    static let standardMediaMetadataMapping = [ MediaConstants.StandardMediaMetadata.SHOW:
        MediaConstants.MediaCollection.StandardMediaMetadata.SHOW, MediaConstants.StandardMediaMetadata.SEASON: MediaConstants.MediaCollection.StandardMediaMetadata.SEASON,
        MediaConstants.MediaCollection.StandardMediaMetadata.EPISODE:
            MediaConstants.MediaCollection.StandardMediaMetadata.EPISODE,
        MediaConstants.MediaCollection.StandardMediaMetadata.ASSET_ID:
            MediaConstants.MediaCollection.StandardMediaMetadata.ASSET_ID,
        MediaConstants.MediaCollection.StandardMediaMetadata.GENRE:
            MediaConstants.MediaCollection.StandardMediaMetadata.GENRE,
        MediaConstants.MediaCollection.StandardMediaMetadata.FIRST_AIR_DATE:
            MediaConstants.MediaCollection.StandardMediaMetadata.FIRST_AIR_DATE,
        MediaConstants.MediaCollection.StandardMediaMetadata.FIRST_DIGITAL_DATE:
            MediaConstants.MediaCollection.StandardMediaMetadata.FIRST_DIGITAL_DATE,
        MediaConstants.MediaCollection.StandardMediaMetadata.RATING:
            MediaConstants.MediaCollection.StandardMediaMetadata.RATING,
        MediaConstants.MediaCollection.StandardMediaMetadata.ORIGINATOR:
            MediaConstants.MediaCollection.StandardMediaMetadata.ORIGINATOR,
        MediaConstants.MediaCollection.StandardMediaMetadata.NETWORK:
            MediaConstants.MediaCollection.StandardMediaMetadata.NETWORK,
        MediaConstants.MediaCollection.StandardMediaMetadata.SHOW_TYPE:
            MediaConstants.MediaCollection.StandardMediaMetadata.SHOW_TYPE,
        MediaConstants.MediaCollection.StandardMediaMetadata.AD_LOAD:
            MediaConstants.MediaCollection.StandardMediaMetadata.AD_LOAD,
        MediaConstants.MediaCollection.StandardMediaMetadata.MVPD:
            MediaConstants.MediaCollection.StandardMediaMetadata.MVPD,
        MediaConstants.MediaCollection.StandardMediaMetadata.AUTH:
            MediaConstants.MediaCollection.StandardMediaMetadata.AUTH,
        MediaConstants.MediaCollection.StandardMediaMetadata.DAY_PART:
            MediaConstants.MediaCollection.StandardMediaMetadata.DAY_PART,
        MediaConstants.MediaCollection.StandardMediaMetadata.FEED:
            MediaConstants.MediaCollection.StandardMediaMetadata.FEED,
        MediaConstants.MediaCollection.StandardMediaMetadata.STREAM_FORMAT:
            MediaConstants.MediaCollection.StandardMediaMetadata.STREAM_FORMAT,
        MediaConstants.MediaCollection.StandardMediaMetadata.ARTIST:
            MediaConstants.MediaCollection.StandardMediaMetadata.ARTIST,
        MediaConstants.MediaCollection.StandardMediaMetadata.ALBUM:
            MediaConstants.MediaCollection.StandardMediaMetadata.ALBUM,
        MediaConstants.MediaCollection.StandardMediaMetadata.LABEL:
            MediaConstants.MediaCollection.StandardMediaMetadata.LABEL,
        MediaConstants.MediaCollection.StandardMediaMetadata.AUTHOR:
            MediaConstants.MediaCollection.StandardMediaMetadata.AUTHOR,
        MediaConstants.MediaCollection.StandardMediaMetadata.STATION:
            MediaConstants.MediaCollection.StandardMediaMetadata.STATION,
        MediaConstants.MediaCollection.StandardMediaMetadata.PUBLISHER:
            MediaConstants.MediaCollection.StandardMediaMetadata.PUBLISHER
    ]

    static let analyticsSharedState: [String: Any] = [
        MediaConstants.Analytics.ANALYTICS_VISITOR_ID: "aid",
        MediaConstants.Analytics.VISITOR_ID: "vid",
    ]

    static let identitySharedState: [String: Any] = [
        MediaConstants.Identity.MARKETING_VISITOR_ID: "ecid",
        MediaConstants.Identity.BLOB: "blob",
        MediaConstants.Identity.LOC_HINT: "lochint",
        MediaConstants.Identity.VISITOR_IDS_LIST: [["id_origin": "orig1", "id_type": "type1", "id": "u111111111", "authentication_state": 0],["id_origin": "orig1", "id_type": "type2", "id": "1234567890", "authentication_state": 1],["id_origin": "orig1", "id_type": "type3", "id": "testPushId", "authentication_state": 2]]
    ]

    static let expectedSerializedCustomerIds = ["type1":["id":"u111111111","authState":0],"type2":["id":"1234567890","authState":1],"type3":["id":"testPushId","authState":2]]

    static let configSharedState: [String: Any] = [
        MediaConstants.Configuration.ANALYTICS_TRACKING_SERVER: "analytics-test.com",
        MediaConstants.Configuration.ANALYTICS_RSID: "rsid",
        MediaConstants.Configuration.GLOBAL_CONFIG_PRIVACY: "optedin",
        MediaConstants.Configuration.EXPERIENCE_CLOUD_ORGID: "orgid",
        MediaConstants.Configuration.MEDIA_OVP: "ovp",
        MediaConstants.Configuration.MEDIA_CHANNEL: "channel",
        MediaConstants.Configuration.MEDIA_PLAYER_NAME: "player",
        MediaConstants.Configuration.MEDIA_APP_VERSION: Media.extensionVersion,
        MediaConstants.Configuration.MEDIA_DEBUG_LOGGING: true,
        MediaConstants.Configuration.MEDIA_TRACKING_SERVER: "media-tracking-test.com",
        MediaConstants.Configuration.MEDIA_COLLECTION_SERVER: "media-collection-test.com"
    ]

}
