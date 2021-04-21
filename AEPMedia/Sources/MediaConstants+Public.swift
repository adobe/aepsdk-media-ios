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

public class MediaConstants {

    @objc(AEPMediaStreamType)
    @objcMembers
    public class StreamType: NSObject {
        public static let VOD = "vod"
        public static let LIVE = "live"
        public static let LINEAR = "linear"
        public static let PODCAST = "podcast"
        public static let AUDIOBOOK = "audiobook"
        public static let AOD = "aod"
    }

    @objc(AEPVideoMetadataKeys)
    @objcMembers
    public class VideoMetadataKeys: NSObject {
        public static let SHOW = "a.media.show"
        public static let SEASON = "a.media.season"
        public static let EPISODE = "a.media.episode"
        public static let ASSET_ID = "a.media.asset"
        public static let GENRE = "a.media.genre"
        public static let FIRST_AIR_DATE = "a.media.airDate"
        public static let FIRST_DIGITAL_DATE = "a.media.digitalDate"
        public static let RATING = "a.media.rating"
        public static let ORIGINATOR = "a.media.originator"
        public static let NETWORK = "a.media.network"
        public static let SHOW_TYPE = "a.media.type"
        public static let AD_LOAD = "a.media.adLoad"
        public static let MVPD = "a.media.pass.mvpd"
        public static let AUTHORIZED = "a.media.pass.auth"
        public static let DAY_PART = "a.media.dayPart"
        public static let FEED = "a.media.feed"
        public static let STREAM_FORMAT = "a.media.format"
    }

    @objc(AEPAudioMetadataKeys)
    @objcMembers
    public class AudioMetadataKeys: NSObject {
        public static let ARTIST = "a.media.artist"
        public static let ALBUM = "a.media.album"
        public static let LABEL = "a.media.label"
        public static let AUTHOR = "a.media.author"
        public static let STATION = "a.media.station"
        public static let PUBLISHER = "a.media.publisher"
    }

    @objc(AEPAdMetadataKeys)
    @objcMembers
    public class AdMetadataKeys: NSObject {
        public static let ADVERTISER = "a.media.ad.advertiser"
        public static let CAMPAIGN_ID = "a.media.ad.campaign"
        public static let CREATIVE_ID = "a.media.ad.creative"
        public static let PLACEMENT_ID = "a.media.ad.placement"
        public static let SITE_ID = "a.media.ad.site"
        public static let CREATIVE_URL = "a.media.ad.creativeURL"
    }

    @objc(AEPMediaPlayerState)
    @objcMembers
    public class PlayerState: NSObject {
        public static let FULLSCREEN = "fullscreen"
        public static let PICTURE_IN_PICTURE = "pictureInPicture"
        public static let CLOSED_CAPTION = "closedCaptioning"
        public static let IN_FOCUS = "inFocus"
        public static let MUTE = "mute"
    }

    @objc(AEPMediaObjectKey)
    @objcMembers
    public class MediaObjectKey: NSObject {
        public static let RESUMED = "media.resumed"
        public static let PREROLL_TRACKING_WAITING_TIME  = "media.prerollwaitingtime"
        public static let GRANULAR_AD_TRACKING  = "media.granularadtracking"
    }

    @objc(AEPMediaTrackerConfig)
    @objcMembers
    public class TrackerConfig: NSObject {
        public static let CHANNEL = "config.channel"
        public static let DOWNLOADED_CONTENT = "config.downloadedcontent"
    }
}
