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
import AVFoundation
import AEPMedia

class VideoAnalyticsProvider: NSObject {
    let VIDEO_ID    = "bipbop"
    let VIDEO_NAME  = "Bip bop video"
    let VIDEO_LENGTH = 1800

    let logTag = "#VideoAnalyticsProvider"
    var _player: VideoPlayer!
    var _tracker: MediaTracker!
    var _pendingSessionStart: Bool!
    var _pendingPlay: Bool!

    @objc func initWithPlayer(player: VideoPlayer) {
        _player = player

        var config: [String: Any] = [:]
        // TO DO: Use Public Constants
        config["config.channel"] = "custom-swift-channel" // Override channel
        config["config.downloadedcontent"] = false    // Creates downloaded content tracker configured from launch

        _tracker = Media.createTrackerWith(config: config)
        setupPlayerNotifications()
    }

    deinit {
        destroy()
    }

    @objc func getQoSObject() -> NSDictionary {
        return Media.createQoEObjectWith(bitrate: 500000, startupTime: 2, fps: 24, droppedFrames: 10)! as NSDictionary
    }

    @objc func updateCurrentPlaybackTime(notification: NSNotification) {
        let playhead = _player.getCurrentPlaybackTime()
        NSLog("\(logTag) updatePlayhead() - updated playhead value to %f", playhead)
        _tracker.updateCurrentPlayhead(time: playhead)
    }

    func destroy() {
        NotificationCenter.default.removeObserver(self)

        _tracker = nil
    }

    @objc func onMainVideoLoaded(notification: NSNotification) {
        NSLog("\(logTag) onMainVideoLoaded()")
        // TO DO: Use Public Constants
        let mediaObject = Media.createMediaObjectWith(name: VIDEO_NAME, id: VIDEO_ID, length: Double(VIDEO_LENGTH), streamType: "vod", mediaType: MediaType.Audio)
        var videoMetadata: [String: String] = [:]
        // standardVideoMetadata
        videoMetadata["a.media.show"] = "Sample show"
        videoMetadata["a.media.season"] = "Sample season"

        // customMetadata
        videoMetadata["isUserLoggedIn"] = "false"
        videoMetadata["tvStation"] = "Sample TV station"

        _tracker.trackSessionStart(info: mediaObject!, metadata: videoMetadata)
    }

    @objc func onMainVideoUnloaded(notification: NSNotification) {
        NSLog("\(logTag) onMainVideoUnloaded()")
        _tracker.trackSessionEnd()
    }

    @objc func onPlay(notification: NSNotification) {
        NSLog("\(logTag) onPlay()")
        _tracker.trackPlay()
    }

    @objc func onStop(notification: NSNotification) {
        NSLog("\(logTag) onStop()")
        _tracker.trackPause()
    }

    @objc func onComplete(notification: NSNotification) {
        NSLog("\(logTag) onComplete()")
        _tracker.trackComplete()
    }

    @objc func onSeekStart(notification: NSNotification) {
        NSLog("\(logTag) onSeekStart()")
        _tracker.trackEvent(event: MediaEvent.SeekStart, info: nil, metadata: nil)
    }

    @objc func onSeekComplete(notification: NSNotification) {
        NSLog("\(logTag) onSeekComplete()")
        _tracker.trackEvent(event: MediaEvent.SeekComplete, info: nil, metadata: nil)
    }

    @objc func onChapterStart(notification: NSNotification) {
        NSLog("\(logTag) onChapterStart()")

        let chapterDictionary = ["segmentType": "Sample segment type"]

        let chapterData = notification.userInfo

        let chapterObject = Media.createChapterObjectWith(name: chapterData!["name"] as! String, position: chapterData!["position"] as! Int, length: chapterData!["length"] as! Double, startTime: chapterData!["time"] as! Double)

        _tracker.trackEvent(event: MediaEvent.ChapterStart, info: chapterObject, metadata: chapterDictionary)
    }

    @objc func onChapterComplete(notification: NSNotification) {
        NSLog("\(logTag) onChapterComplete()")
        _tracker.trackEvent(event: MediaEvent.ChapterComplete, info: nil, metadata: nil)
    }

    @objc func onAdStart(notification: NSNotification) {
        NSLog("\(logTag) onAdStart()")

        let adBreakData = notification.userInfo!["adbreak"] as! [String: Any]
        let adData = notification.userInfo!["ad"] as! [String: Any]

        let adBreakObject = Media.createAdBreakObjectWith(name: adBreakData["name"] as! String, position: adBreakData["position"] as! Int, startTime: adBreakData["time"] as! Double)

        let adObject = Media.createAdObjectWith(name: adData["name"] as! String, adId: adData["id"] as! String, position: adData["position"] as! Int, length: adData["length"] as! Double)

        var adMetadata: [String: String] = [:]
        // standardAdMetadata
        // TO DO: Use Public Constants
        adMetadata["a.media.ad.advertiser"] = "Sample Advertiser"
        adMetadata["a.media.ad.campaign"] = "Sample Campaign"

        // customAdMetadata
        adMetadata["affiliate"] = "Sample affiliate"

        // AdBreakStart
        _tracker.trackEvent(event: MediaEvent.AdBreakStart, info: adBreakObject, metadata: nil)

        // AdStart
        _tracker.trackEvent(event: MediaEvent.AdStart, info: adObject, metadata: adMetadata)
    }

    @objc func onAdComplete(notification: NSNotification) {
        NSLog("\(logTag) onAdComplete()")
        // AdComplete
        _tracker.trackEvent(event: MediaEvent.AdComplete, info: nil, metadata: nil)

        // AdBreakComplete
        _tracker.trackEvent(event: MediaEvent.AdBreakComplete, info: nil, metadata: nil)
    }

    @objc func onMuteUpdate(notification: NSNotification) {
        NSLog("\(logTag) onMuteUpdate()")
        let muted: Bool = (notification.userInfo!["muted"])! as! Bool
        NSLog("\(logTag) Player muted: ", muted)
        // TO DO: Use Public Constants for State Name
        let muteState = Media.createStateObjectWith(stateName: "mute")
        let event = muted ? MediaEvent.StateStart : MediaEvent.StateEnd

        _tracker.trackEvent(event: event, info: muteState, metadata: nil)
    }

    @objc func onCCUpdate(notification: NSNotification) {
        NSLog("\(logTag) onCCUpdate()")
        let ccActive: Bool = (notification.userInfo!["ccActive"])! as! Bool
        NSLog("\(logTag) Closed caption active: ", ccActive)
        // TO DO: Use Public Constants for State Name
        let ccState = Media.createStateObjectWith(stateName: "closedCaptioning")
        let event = ccActive ? MediaEvent.StateStart : MediaEvent.StateEnd

        _tracker.trackEvent(event: event, info: ccState, metadata: nil)
    }

    func setupPlayerNotifications() {

        NotificationCenter.default.addObserver(self, selector: #selector(VideoAnalyticsProvider.onMainVideoLoaded), name: NSNotification.Name(rawValue: PLAYER_EVENT_VIDEO_LOAD), object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(VideoAnalyticsProvider.onMainVideoUnloaded), name: NSNotification.Name(rawValue: PLAYER_EVENT_VIDEO_UNLOAD), object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(VideoAnalyticsProvider.onPlay), name: NSNotification.Name(rawValue: PLAYER_EVENT_PLAY), object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(VideoAnalyticsProvider.onStop), name: NSNotification.Name(rawValue: PLAYER_EVENT_PAUSE), object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(VideoAnalyticsProvider.onSeekStart), name: NSNotification.Name(rawValue: PLAYER_EVENT_SEEK_START), object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(VideoAnalyticsProvider.onSeekComplete), name: NSNotification.Name(rawValue: PLAYER_EVENT_SEEK_COMPLETE), object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(VideoAnalyticsProvider.onComplete), name: NSNotification.Name(rawValue: PLAYER_EVENT_COMPLETE), object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(VideoAnalyticsProvider.onChapterStart), name: NSNotification.Name(rawValue: PLAYER_EVENT_CHAPTER_START), object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(VideoAnalyticsProvider.onChapterComplete), name: NSNotification.Name(rawValue: PLAYER_EVENT_CHAPTER_COMPLETE), object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(VideoAnalyticsProvider.onAdStart), name: NSNotification.Name(rawValue: PLAYER_EVENT_AD_START), object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(VideoAnalyticsProvider.onAdComplete), name: NSNotification.Name(rawValue: PLAYER_EVENT_AD_COMPLETE), object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(VideoAnalyticsProvider.updateCurrentPlaybackTime), name: NSNotification.Name(rawValue: PLAYER_EVENT_PLAYHEAD_UPDATE), object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(VideoAnalyticsProvider.onCCUpdate), name: NSNotification.Name(rawValue: PLAYER_EVENT_CC_CHANGE), object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(VideoAnalyticsProvider.onMuteUpdate), name: NSNotification.Name(rawValue: PLAYER_EVENT_MUTE_CHANGE), object: nil)

    }

}

