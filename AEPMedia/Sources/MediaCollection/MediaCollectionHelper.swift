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
import AEPServices

class MediaCollectionHelper {
    static let LOG_TAG = "MediaCollectionHelper"

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

    static func generateMediaParams(mediaInfo: MediaInfo, metadata: [String: String]) -> [String: Any] {
        var retDict = [String: Any]()

        retDict[MediaConstants.MediaCollection.Media.ID] = mediaInfo.id
        retDict[MediaConstants.MediaCollection.Media.NAME] = mediaInfo.name
        retDict[MediaConstants.MediaCollection.Media.LENGTH] = mediaInfo.length
        retDict[MediaConstants.MediaCollection.Media.CONTENT_TYPE] = mediaInfo.streamType
        retDict[MediaConstants.MediaCollection.Media.STREAM_TYPE] = mediaInfo.mediaType.rawValue
        retDict[MediaConstants.MediaCollection.Media.RESUME] = mediaInfo.resumed

        // standard metadata keys are transformed and reported as part of media param
        for (key, value) in metadata {
            if let newKey = standardMediaMetadataMapping[key], !newKey.isEmpty {
                retDict[newKey] = value
            }
        }

        return retDict
    }

    static func generateMediaMetadata(metadata: [String: String]) -> [String: String] {
        var retDict = [String: String]()

        // standard metadata is removed and only custom metadata will be returned.
        for (key, value) in metadata {
            if standardMediaMetadataMapping[key] == nil {
                retDict[key] = value
            }
        }

        return retDict
    }

    static func generateAdBreakParams(adBreakInfo: AdBreakInfo?) -> [String: Any] {
        var retDict = [String: Any]()

        guard let adBreakInfo = adBreakInfo else {
            Log.trace(label: LOG_TAG, "\(#function) - found empty ad break info.")
            return retDict
        }

        retDict[MediaConstants.MediaCollection.AdBreak.POD_FRIENDLY_NAME] = adBreakInfo.name
        retDict[MediaConstants.MediaCollection.AdBreak.POD_INDEX] = adBreakInfo.position
        retDict[MediaConstants.MediaCollection.AdBreak.POD_SECOND] = adBreakInfo.startTime

        return retDict
    }

    static func generateAdParams(adInfo: AdInfo?, adMetadata: [String: String]) -> [String: Any] {
        var retDict = [String: Any]()

        guard let adInfo = adInfo else {
            Log.trace(label: LOG_TAG, "\(#function) - found empty ad info.")
            return retDict
        }

        retDict[MediaConstants.MediaCollection.Ad.ID] = adInfo.id
        retDict[MediaConstants.MediaCollection.Ad.LENGTH] = adInfo.length
        retDict[MediaConstants.MediaCollection.Ad.NAME] = adInfo.name
        retDict[MediaConstants.MediaCollection.Ad.POD_POSITION] = adInfo.position

        let adMetadata = adMetadata
        // standard ad metadata keys are transformed and reported as part of ad params
        for (key, value) in adMetadata {
            if let newKey = standardAdMetadataMapping[key] {
                retDict[newKey] = value
            }
        }

        return retDict
    }

    static func generateAdMetadata(adMetadata: [String: String]) -> [String: String] {
        var retDict = [String: String]()

        // standard ad metadata is removed and only custom ad metadata will be returned.
        for (key, value) in adMetadata {
            if standardAdMetadataMapping[key] == nil {
                retDict[key] = value
            }
        }

        return retDict
    }

    static func generateChapterParams(chapterInfo: ChapterInfo?) -> [String: Any] {
        var retDict = [String: Any]()

        guard let chapterInfo = chapterInfo else {
            Log.trace(label: LOG_TAG, "\(#function) - found empty chapter info.")
            return retDict
        }

        retDict[MediaConstants.MediaCollection.Chapter.FRIENDLY_NAME] = chapterInfo.name
        retDict[MediaConstants.MediaCollection.Chapter.INDEX] = chapterInfo.position
        retDict[MediaConstants.MediaCollection.Chapter.LENGTH] = chapterInfo.length
        retDict[MediaConstants.MediaCollection.Chapter.OFFSET] = chapterInfo.startTime

        return retDict
    }

    static func generateErrorParam(qoeInfo: QoEInfo?, errorId: String) -> [String: Any] {
        var errorParam = qoeInfo?.toMap() ?? [:]
        errorParam[MediaConstants.MediaCollection.QoE.ERROR_ID] = errorId
        errorParam[MediaConstants.MediaCollection.QoE.ERROR_SOURCE] = MediaConstants.MediaCollection.QoE.ERROR_SOURCE_PLAYER

        return errorParam
    }
}
