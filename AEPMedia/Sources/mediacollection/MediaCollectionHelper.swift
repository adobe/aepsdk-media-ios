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

// TODO: replace with final implementation
class MediaCollectionHelper {
    let LOG_TAG = "MediaCollectionHelper"

    private static let standardMediaMetadataMapping = [ MediaConstants.StandardMediaMetadata.SHOW:
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

    private static let standardAdMetadataMapping = [ MediaConstants.StandardAdMetadata.ADVERTISER: MediaConstants.MediaCollection.StandardAdMetadata.ADVERTISER,
                                                     MediaConstants.StandardAdMetadata.CAMPAIGN_ID:
                                                         MediaConstants.MediaCollection.StandardAdMetadata.CAMPAIGN_ID,
                                                     MediaConstants.StandardAdMetadata.CREATIVE_ID:
                                                         MediaConstants.MediaCollection.StandardAdMetadata.CREATIVE_ID,
                                                     MediaConstants.StandardAdMetadata.PLACEMENT_ID:
                                                         MediaConstants.MediaCollection.StandardAdMetadata.PLACEMENT_ID,
                                                     MediaConstants.StandardAdMetadata.SITE_ID:
                                                         MediaConstants.MediaCollection.StandardAdMetadata.SITE_ID,
                                                     MediaConstants.StandardAdMetadata.CREATIVE_URL:
                                                         MediaConstants.MediaCollection.StandardAdMetadata.CREATIVE_URL
    ]

    static func extractMediaParams(mediaContext: MediaContext) -> [String: Any] {
        var retDict = [String: Any]()

        let mediaInfo = mediaContext.getMediaInfo()
        retDict[MediaConstants.MediaCollection.Media.ID] = mediaInfo.id
        retDict[MediaConstants.MediaCollection.Media.NAME] = mediaInfo.name
        retDict[MediaConstants.MediaCollection.Media.LENGTH] = mediaInfo.length
        retDict[MediaConstants.MediaCollection.Media.CONTENT_TYPE] = mediaInfo.streamType
        retDict[MediaConstants.MediaCollection.Media.STREAM_TYPE] = mediaInfo.mediaType
        retDict[MediaConstants.MediaCollection.Media.RESUME] = mediaInfo.resumed

        let metadata = mediaContext.getMediaMetadata()

        // standard metadata keys are transformed and reported as part of media param
        for (key,value) in metadata {
            let newKey = standardMediaMetadataMapping[key] ?? key
            retDict[newKey] = value
        }

        return retDict
    }

    static func extractMediaMetadata(mediaContext: MediaContext) -> [String: String] {
        var retDict = [String: String]()

        let metadata = mediaContext.getMediaMetadata()

        // standard metadata is removed and only custom metadata will be returned.
        for (key,value) in metadata {
            if standardMediaMetadataMapping[key] == nil {
                retDict[key] = value
            }
        }

        return retDict
    }

    // TODO: stub
    static func extractAdBreakParams(mediaContext: MediaContext) -> [String: Any] {
        var retDict = [String: Any]()

        return retDict
    }

    // TODO: stub
    static func extractAdParams(mediaContext: MediaContext) -> [String: Any] {
        var retDict = [String: Any]()

        return retDict
    }

    // TODO: stub
    static func extractAdMetadata(mediaContext: MediaContext) -> [String: String] {
        var retDict = [String: String]()

        return retDict
    }

    // TODO: stub
    static func extractChapterParams(mediaContext: MediaContext) -> [String: Any] {
        var retDict = [String: Any]()

        return retDict
    }

    // TODO: stub
    static func extractChapterMetadata(mediaContext: MediaContext) -> [String: String] {
        var retDict = [String: String]()

        return retDict
    }
}
