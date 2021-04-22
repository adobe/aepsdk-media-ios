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

    static let standardMediaMetadataMapping = [
        MediaConstants.VideoMetadataKeys.SHOW: MediaConstants.MediaCollection.StandardMediaMetadata.SHOW,
        MediaConstants.VideoMetadataKeys.SEASON: MediaConstants.MediaCollection.StandardMediaMetadata.SEASON,
        MediaConstants.VideoMetadataKeys.EPISODE: MediaConstants.MediaCollection.StandardMediaMetadata.EPISODE,
        MediaConstants.VideoMetadataKeys.ASSET_ID: MediaConstants.MediaCollection.StandardMediaMetadata.ASSET_ID,
        MediaConstants.VideoMetadataKeys.GENRE: MediaConstants.MediaCollection.StandardMediaMetadata.GENRE,
        MediaConstants.VideoMetadataKeys.FIRST_AIR_DATE: MediaConstants.MediaCollection.StandardMediaMetadata.FIRST_AIR_DATE,
        MediaConstants.VideoMetadataKeys.FIRST_DIGITAL_DATE: MediaConstants.MediaCollection.StandardMediaMetadata.FIRST_DIGITAL_DATE,
        MediaConstants.VideoMetadataKeys.RATING: MediaConstants.MediaCollection.StandardMediaMetadata.RATING,
        MediaConstants.VideoMetadataKeys.ORIGINATOR: MediaConstants.MediaCollection.StandardMediaMetadata.ORIGINATOR,
        MediaConstants.VideoMetadataKeys.NETWORK: MediaConstants.MediaCollection.StandardMediaMetadata.NETWORK,
        MediaConstants.VideoMetadataKeys.SHOW_TYPE: MediaConstants.MediaCollection.StandardMediaMetadata.SHOW_TYPE,
        MediaConstants.VideoMetadataKeys.AD_LOAD: MediaConstants.MediaCollection.StandardMediaMetadata.AD_LOAD,
        MediaConstants.VideoMetadataKeys.MVPD: MediaConstants.MediaCollection.StandardMediaMetadata.MVPD,
        MediaConstants.VideoMetadataKeys.AUTHORIZED: MediaConstants.MediaCollection.StandardMediaMetadata.AUTH,
        MediaConstants.VideoMetadataKeys.DAY_PART: MediaConstants.MediaCollection.StandardMediaMetadata.DAY_PART,
        MediaConstants.VideoMetadataKeys.FEED: MediaConstants.MediaCollection.StandardMediaMetadata.FEED,
        MediaConstants.VideoMetadataKeys.STREAM_FORMAT: MediaConstants.MediaCollection.StandardMediaMetadata.STREAM_FORMAT,
        MediaConstants.AudioMetadataKeys.ARTIST: MediaConstants.MediaCollection.StandardMediaMetadata.ARTIST,
        MediaConstants.AudioMetadataKeys.ALBUM: MediaConstants.MediaCollection.StandardMediaMetadata.ALBUM,
        MediaConstants.AudioMetadataKeys.LABEL: MediaConstants.MediaCollection.StandardMediaMetadata.LABEL,
        MediaConstants.AudioMetadataKeys.AUTHOR: MediaConstants.MediaCollection.StandardMediaMetadata.AUTHOR,
        MediaConstants.AudioMetadataKeys.STATION: MediaConstants.MediaCollection.StandardMediaMetadata.STATION,
        MediaConstants.AudioMetadataKeys.PUBLISHER: MediaConstants.MediaCollection.StandardMediaMetadata.PUBLISHER
    ]

    static let analyticsSharedState: [String: Any] = [
        MediaConstants.Analytics.ANALYTICS_VISITOR_ID: "aid",
        MediaConstants.Analytics.VISITOR_ID: "vid",
    ]

    static let identitySharedState: [String: Any] = [
        MediaConstants.Identity.MARKETING_VISITOR_ID: "ecid",
        MediaConstants.Identity.BLOB: "blob",
        MediaConstants.Identity.LOC_HINT: "lochint",
        MediaConstants.Identity.VISITOR_IDS_LIST: [["id_origin": "orig1", "id_type": "type1", "id": "u111111111", "authentication_state": 0], ["id_origin": "orig1", "id_type": "type2", "id": "1234567890", "authentication_state": 1], ["id_origin": "orig1", "id_type": "type3", "id": "testPushId", "authentication_state": 2]]
    ]

    static let expectedSerializedCustomerIds = ["type1": ["id": "u111111111", "authState": 0], "type2": ["id": "1234567890", "authState": 1], "type3": ["id": "testPushId", "authState": 2]]

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
