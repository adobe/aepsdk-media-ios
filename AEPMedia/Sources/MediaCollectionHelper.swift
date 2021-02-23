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

    class func extractMediaParams(mediaContext: MediaContext) -> [String: Any] {
        var retDict = [String: Any]()

        let mediaInfo = mediaContext.getMediaInfo()

        if !mediaInfo.toMap().isEmpty {
            retDict[MediaConstants.MediaCollection.Media.ID] = mediaInfo.getId()
            retDict[MediaConstants.MediaCollection.Media.NAME] = mediaInfo.getName()
            retDict[MediaConstants.MediaCollection.Media.LENGTH] = mediaInfo.getLength()
            retDict[MediaConstants.MediaCollection.Media.CONTENT_TYPE] = mediaInfo.getStreamType()
            retDict[MediaConstants.MediaCollection.Media.STREAM_TYPE] = mediaInfo.getMediaType()
            retDict[MediaConstants.MediaCollection.Media.RESUME] = mediaInfo.isResumed()
        }

        let metadata = mediaContext.getMediaMetadata()

        for entry in metadata {
            if standardMediaMetadataMapping[entry.key] != nil {
                let newKey = getMediaCollectionKey(key: entry.key)
                retDict[newKey] = entry.value
            }
        }

        return retDict
    }

    class func getMediaCollectionKey(key: String) -> String {
        if standardMediaMetadataMapping[key] != nil {
            return standardMediaMetadataMapping[key] ?? key
        }

        return key
    }

    class func extractMediaMetadata(mediaContext: MediaContext) -> [String: String] {
        var retDict = [String: String]()

        let metadata = mediaContext.getMediaMetadata()

        for entry in metadata {
            if standardMediaMetadataMapping[entry.key] == nil {
                retDict[entry.key] = entry.value
            }
        }

        return retDict
    }

    // TODO: stub
    class func extractQoeData(mediaContext: MediaContext) -> [String: Any] {
        var retDict = [String: Any]()

        return retDict
    }

    class func extractAdBreakParams(mediaContext: MediaContext) -> [String: Any] {
        var retDict = [String: Any]()

        return retDict
    }

    // TODO: stub
    class func extractAdParams(mediaContext: MediaContext) -> [String: Any] {
        var retDict = [String: Any]()

        return retDict
    }

    // TODO: stub
    class func extractAdMetadata(mediaContext: MediaContext) -> [String: String] {
        var retDict = [String: String]()

        return retDict
    }

    // TODO: stub
    class func extractChapterParams(mediaContext: MediaContext) -> [String: Any] {
        var retDict = [String: Any]()

        return retDict
    }

    // TODO: stub
    class func extractChapterMetadata(mediaContext: MediaContext) -> [String: String] {
        var retDict = [String: String]()

        return retDict
    }
}
