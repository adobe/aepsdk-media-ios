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

@objc(MediaConstants)
public class AEPMediaConstants: NSObject {

    // MARK: - Standard Stream Type Constants
    public static let AEPMediaStreamTypeVod = "vod"
    public static let AEPMediaStreamTypeLive = "live"
    public static let AEPMediaStreamTypeLinear = "linear"
    public static let AEPMediaStreamTypePodcast = "podcast"
    public static let AEPMediaStreamTypeAudiobook = "audiobook"
    public static let AEPMediaStreamTypeAod = "aod"

    // MARK: Standard Video Metadata Public Constants
    public static let AEPVideoMetadataKeyShow = MediaConstants.StandardMediaMetadata.SHOW
    public static let AEPVideoMetadataKeySeason = MediaConstants.StandardMediaMetadata.SEASON
    public static let AEPVideoMetadataKeyEpisode = MediaConstants.StandardMediaMetadata.EPISODE
    public static let AEPVideoMetadataKeyAssetId = MediaConstants.StandardMediaMetadata.ASSET_ID
    public static let AEPVideoMetadataKeyGenre = MediaConstants.StandardMediaMetadata.GENRE
    public static let AEPVideoMetadataKeyFirstAirDate = MediaConstants.StandardMediaMetadata.FIRST_AIR_DATE
    public static let AEPVideoMetadataKeyFirstDigitalDate = MediaConstants.StandardMediaMetadata.FIRST_DIGITAL_DATE
    public static let AEPVideoMetadataKeyRating = MediaConstants.StandardMediaMetadata.RATING
    public static let AEPVideoMetadataKeyOriginator = MediaConstants.StandardMediaMetadata.ORIGINATOR
    public static let AEPVideoMetadataKeyNetwork = MediaConstants.StandardMediaMetadata.NETWORK
    public static let AEPVideoMetadataKeyShowType = MediaConstants.StandardMediaMetadata.SHOW_TYPE
    public static let AEPVideoMetadataKeyAdLoad = MediaConstants.StandardMediaMetadata.AD_LOAD
    public static let AEPVideoMetadataKeyMvpd = MediaConstants.StandardMediaMetadata.MVPD
    public static let AEPVideoMetadataKeyAuthorized = MediaConstants.StandardMediaMetadata.AUTH
    public static let AEPVideoMetadataKeyDayPart = MediaConstants.StandardMediaMetadata.DAY_PART
    public static let AEPVideoMetadataKeyFeed = MediaConstants.StandardMediaMetadata.FEED
    public static let AEPVideoMetadataKeyStreamFormat = MediaConstants.StandardMediaMetadata.STREAM_FORMAT

    // MARK: Standard Audio Metadata Public Constants
    public static let AEPAudioMetadataKeyArtist = MediaConstants.StandardMediaMetadata.ARTIST
    public static let AEPAudioMetadataKeyAlbum = MediaConstants.StandardMediaMetadata.ALBUM
    public static let AEPAudioMetadataKeyLabel = MediaConstants.StandardMediaMetadata.LABEL
    public static let AEPAudioMetadataKeyAuthor = MediaConstants.StandardMediaMetadata.AUTHOR
    public static let AEPAudioMetadataKeyStation = MediaConstants.StandardMediaMetadata.STATION
    public static let AEPAudioMetadataKeyPublisher = MediaConstants.StandardMediaMetadata.PUBLISHER

    // MARK: Standard Ad Metadata Public Constants
    public static let AEPAdMetadataKeyAdvertiser = MediaConstants.StandardAdMetadata.ADVERTISER
    public static let AEPAdMetadataKeyCampaignId = MediaConstants.StandardAdMetadata.CAMPAIGN_ID
    public static let AdMetadataKeyCreativeId = MediaConstants.StandardAdMetadata.CREATIVE_ID
    public static let AEPAdMetadataKeyPlacementId = MediaConstants.StandardAdMetadata.PLACEMENT_ID
    public static let AEPAdMetadataKeySiteId = MediaConstants.StandardAdMetadata.SITE_ID
    public static let AEPAdMetadataKeyCreativeUrl = MediaConstants.StandardAdMetadata.CREATIVE_URL

    // MARK: Media Public Constants
    public static let AEPMediaKeyMediaResumed = MediaConstants.MediaInfo.RESUMED
    public static let AEPMediaKeyPrerollTrackingWaitingTime = MediaConstants.MediaInfo.PREROLL_TRACKING_WAITING_TIME
    public static let AEPMediaKeyGranularAdTracking = MediaConstants.MediaInfo.GRANULAR_AD_TRACKING

    // MARK: Config Public Constants
    public static let AEPMediaKeyConfigChannel = MediaConstants.TrackerConfig.CHANNEL
    public static let AEPMediaKeyConfigDownloadedContent = MediaConstants.TrackerConfig.DOWNLOADED_CONTENT

    // MARK: Player State Constants
    public static let AEPMediaPlayerStateFullScreen = "fullscreen"
    public static let AEPMediaPlayerStatePictureInPicture = "pictureInPicture"
    public static let AEPMediaPlayerStateClosedCaption = "closedCaptioning"
    public static let AEPMediaPlayerStateInFocus = "inFocus"
    public static let AEPMediaPlayerStateMute = "mute"
}


