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
import AVKit
import AVFoundation

class PlayerEvent {
    static let PLAYER_EVENT_VIDEO_LOAD = "player_video_load"
    static let PLAYER_EVENT_VIDEO_UNLOAD = "player_video_unload"
    static let PLAYER_EVENT_PLAY = "player_play"
    static let PLAYER_EVENT_PAUSE = "player_pause"
    static let PLAYER_EVENT_COMPLETE = "player_complete"
    static let PLAYER_EVENT_SEEK_START = "player_seek_start"
    static let PLAYER_EVENT_SEEK_COMPLETE = "player_seek_complete"
    static let PLAYER_EVENT_AD_START = "player_ad_start"
    static let PLAYER_EVENT_AD_COMPLETE = "player_ad_complete"
    static let PLAYER_EVENT_CHAPTER_START = "player_chapter_start"
    static let PLAYER_EVENT_CHAPTER_COMPLETE = "player_chapter_complete"
    static let PLAYER_EVENT_PLAYHEAD_UPDATE = "player_playhead_updates"
    static let PLAYER_EVENT_QOE_UPDATE = "player_qoe_update"
    static let PLAYER_EVENT_CC_CHANGE = "player_cc_change"
    static let PLAYER_EVENT_MUTE_CHANGE = "player_mute_change"
}

class VideoPlayer: AVPlayer {
    var _videoLoaded: Bool = false
    var _seeking: Bool = false
    var _paused: Bool = false

    var _isMuted: Bool = false
    var _isCCActive: Bool = false

    var _isInChapter: Bool = false
    var _isInAd: Bool = false
    var _chapterPosition: Int?

    let AD_START_POS: Double = 15
    let AD_END_POS: Double = 30
    let AD_LENGTH: Double = 15

    let CHAPTER1_START_POS: Double = 0
    let CHAPTER1_END_POS: Double = 15
    let CHAPTER1_LENGTH: Double = 15

    let CHAPTER2_START_POS: Double = 30
    let CHAPTER2_LENGTH: Double = 30

    let QOEINFO_BITRATRE: Double = 50000
    let QOEINFO_STARTUPTIME: Double = 1800
    let QOEINFO_FPS: Double = 24
    let QOEINFO_DROPPEDFRAMES: Double = 10
    let VIDEO_LENGTH: Double = 1800
    let VIDEO_NAME: String = "Bip bop video"
    let VIDEO_ID: String = "bipbop"

    let MONITOR_TIMER_INTERVAL = 0.5 // 500 milliseconds

    let kStatusKey                = "status"
    let kRateKey                  = "rate"
    let kMuteKey                  = "muted"
    let kDurationKey              = "duration"
    let kPlaybackBufferEmpty      = "playbackBufferEmpty"
    let kPlaybackBufferFull       = "playbackBufferFull"
    let kPlaybackLikelyToKeepUp   = "playbackLikelyToKeepUp"

    var player: AVPlayer = AVPlayer()
    var playerViewController: AVPlayerViewController = AVPlayerViewController()
    private var MediaPlayerKVOContext = 0

    var timer: Timer?

    func loadContentURL(url: URL) {

        _videoLoaded = false
        _seeking = false
        _paused = true
        _isInAd = false
        _isInChapter = false
        _isMuted = false
        _isCCActive = false

        player = AVPlayer(url: url)
        playerViewController.player = player

        playerViewController.player?.addObserver(self, forKeyPath: kRateKey, options: [], context: &MediaPlayerKVOContext)
        playerViewController.player?.addObserver(self, forKeyPath: kStatusKey, options: [], context: &MediaPlayerKVOContext)
        playerViewController.player?.addObserver(self, forKeyPath: kMuteKey, options: [], context: &MediaPlayerKVOContext)

        NotificationCenter.default.addObserver(self, selector: #selector(onMediaFinishedPlaying), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
    }

    func playVideo() {
        player.play()
    }

    func getPlayerViewController() -> AVPlayerViewController {
        return playerViewController
    }

    func getCurrentPlaybackTime() -> TimeInterval {
        guard let player = playerViewController.player else {
            return 0
        }

        let time = player.currentTime().seconds

        return time
    }

    func duration() -> Double {
        guard let currentItem = playerViewController.player?.currentItem else {
            return 0
        }

        return currentItem.duration.seconds
    }

    deinit {
        if let timer = timer {
            timer.invalidate()
        }
        NotificationCenter.default.removeObserver(self)
    }

    @objc func onMediaFinishedPlaying(notification: NSNotification) {
        NSLog("MediaFinishedPlaying")
        completeVideo()
    }

    // getting events from player
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {

        if context != &MediaPlayerKVOContext {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }

        guard let avplayer = self.playerViewController.player else { return }

        if keyPath == kStatusKey {
            if avplayer.status == AVPlayer.Status.failed {
                pausePlayback()
            }
        } else if keyPath == kRateKey {
            if avplayer.rate == 0.0 {
                pausePlayback()
            } else {
                if _seeking {
                    NSLog("Stop seeking.")
                    _seeking = false
                    doPostSeekComputations()

                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: PlayerEvent.PLAYER_EVENT_SEEK_COMPLETE), object: self)
                } else {
                    NSLog("Resume playback.")
                    openVideoIfNecessary()
                    _paused = false

                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: PlayerEvent.PLAYER_EVENT_PLAY), object: self)
                }
            }
        } else if keyPath == kMuteKey {
            if _isMuted != self.playerViewController.player!.isMuted {
                _isMuted = self.playerViewController.player!.isMuted
                var info: [String: Any] = [:]
                info["muted"] = _isMuted
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: PlayerEvent.PLAYER_EVENT_MUTE_CHANGE), object: self, userInfo: info)
            }
        }

    }

    func detectCCChange() {
        guard let currentItem = self.playerViewController.player?.currentItem else { return }
        let asset = currentItem.asset
        guard let group = asset.mediaSelectionGroup(forMediaCharacteristic: AVMediaCharacteristic.legible) else { return }
        let option = currentItem.currentMediaSelection.selectedMediaOption(in: group)
        let ccActive = (option != nil)
        if _isCCActive != ccActive {
            _isCCActive = ccActive
            var info: [String: Any] = [:]
            info["ccActive"] = _isCCActive
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: PlayerEvent.PLAYER_EVENT_CC_CHANGE), object: self, userInfo: info)
        }
    }

    // player helper methods
    func openVideoIfNecessary() {

        if !(_videoLoaded ) {
            resetInternalState()
            startVideo()

            // Start the monitor timer.
            timer = Timer.scheduledTimer(timeInterval: MONITOR_TIMER_INTERVAL, target: self, selector: #selector(VideoPlayer.onTimerTick), userInfo: nil, repeats: true)

        }
    }

    func pauseIfSeekHasNotStarted() {
        if !(_seeking) {
            pausePlayback()
        } else {
            NSLog("This pause is caused by a seek operation. Skipping.")
        }
    }

    // Call APIs
    func pausePlayback() {
        NSLog("Video paused")
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: PlayerEvent.PLAYER_EVENT_PAUSE), object: self)
    }

    func startVideo() {
        // Prepare the video info.
        let videoInfo = ["id": VIDEO_ID,
                         "length": VIDEO_LENGTH,
                         "name": VIDEO_NAME] as [String: Any]

        _videoLoaded = true
        NSLog("Video started")
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: PlayerEvent.PLAYER_EVENT_VIDEO_LOAD), object: self, userInfo: videoInfo)
    }

    func completeVideo() {
        // Complete the second chapter.
        completeChapter()
        NSLog("Video complete")
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: PlayerEvent.PLAYER_EVENT_COMPLETE), object: self)

        unloadVideo()
    }

    func unloadVideo() {
        NSLog("Video end")
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: PlayerEvent.PLAYER_EVENT_VIDEO_UNLOAD), object: self)

        if timer != nil {
            timer?.invalidate()
        }
        resetInternalState()
    }

    func resetInternalState() {
        NSLog("reset")
        _videoLoaded = false
        _seeking = false
        _paused = true
        timer = nil
    }

    func startChapter1() {
        NSLog("start chapter 1")
        _isInChapter = true
        _chapterPosition = 1

        let chapterInfo = ["name": "First Chapter",
                           "length": CHAPTER1_LENGTH,
                           "position": _chapterPosition as Any,
                           "time": CHAPTER1_START_POS] as [String: Any]

        NotificationCenter.default.post(name: NSNotification.Name(rawValue: PlayerEvent.PLAYER_EVENT_CHAPTER_START), object: self, userInfo: chapterInfo)

        //qoe update
        qoeUpdate()
    }

    func startChapter2() {
        NSLog("start chapter 2")
        _isInChapter = true
        _chapterPosition = 2

        let chapterInfo = ["name": "Second Chapter",
                           "length": CHAPTER2_LENGTH,
                           "position": _chapterPosition as Any,
                           "time": CHAPTER2_START_POS] as [String: Any]

        NotificationCenter.default.post(name: NSNotification.Name(rawValue: PlayerEvent.PLAYER_EVENT_CHAPTER_START), object: self, userInfo: chapterInfo)
    }

    func completeChapter() {
        NSLog("complete chapter")
        _isInChapter = false

        NotificationCenter.default.post(name: NSNotification.Name(rawValue: PlayerEvent.PLAYER_EVENT_CHAPTER_COMPLETE), object: self)
    }

    func startAd() {
        NSLog("start Ad")
        _isInAd = true

        let adBreakInfo = ["name": "First AD-Break",
                           "time": AD_START_POS,
                           "position": 1 as Int] as [String: Any]

        let adInfo = ["name": "Sample AD",
                      "id": "001",
                      "position": 1 as Int,
                      "length": AD_LENGTH] as [String: Any]

        let userInfo = [ "adbreak": adBreakInfo,
                         "ad": adInfo]

        // Start the ad.
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: PlayerEvent.PLAYER_EVENT_AD_START), object: self, userInfo: userInfo)
    }

    func completeAd() {
        NSLog("complete Ad")
        // Complete the ad.
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: PlayerEvent.PLAYER_EVENT_AD_COMPLETE), object: self)

        // Clear the ad and ad-break info.
        _isInAd = false
    }

    func qoeUpdate() {
        NSLog("update QoE")
        // Update QoE
        let qoeInfo = ["bitrate": QOEINFO_BITRATRE,
                       "startupTime": QOEINFO_STARTUPTIME,
                       "fps": QOEINFO_FPS,
                       "droppedFrames": QOEINFO_DROPPEDFRAMES] as [String: Any]

        NotificationCenter.default.post(name: NSNotification.Name(rawValue: PlayerEvent.PLAYER_EVENT_QOE_UPDATE), object: self, userInfo: qoeInfo)
    }

    // Timeline helper methods
    func doPostSeekComputations() {
        let vTime = getCurrentPlaybackTime()

        // Seek inside the first chapter.
        if vTime < CHAPTER1_END_POS {
            // If we were not inside the first chapter before, trigger a chapter start
            if !(_isInChapter) || _chapterPosition != 1 {
                startChapter1()

                // If we were in the ad, clear the ad and ad-break info, but don't send the AD_COMPLETE event.
                if _isInAd {
                    _isInAd = false
                }
            }
        }

        // Seek inside ad.
        else if vTime >= AD_START_POS && vTime < AD_END_POS {
            // If we were not inside the ad before, trigger an ad-start.
            if !(_isInAd) {
                startAd()

                // Also, clear the chapter info, without sending the CHAPTER_COMPLETE event.
                _isInChapter = false
            }
        } else // Seek inside the second chapter.
        {
            // If we were not inside the 2nd chapter before, trigger a chapter start
            if !(_isInChapter) || _chapterPosition != 2 {
                startChapter2()

                // If we were in the ad, clear the ad and ad-break info, but don't send the AD_COMPLETE event.
                if _isInAd {
                    _isInAd = false
                }
            }
        }
    }

    @objc func onTimerTick() {
        // NSLog("Timer Ticked")

        if _seeking || (_paused) {
            return
        }

        let vTime = getCurrentPlaybackTime()
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: PlayerEvent.PLAYER_EVENT_PLAYHEAD_UPDATE), object: self)

        // If we are inside the ad content:
        if vTime >= AD_START_POS && vTime < AD_END_POS {
            if _isInChapter {
                // If for some reason we were inside a chapter, close it.
                completeChapter()
            }

            if !(_isInAd) {
                // Start the ad (if not already started).
                startAd()
            }
        }

        // Otherwise, we are outside the ad content:
        else {
            if _isInAd {
                // Complete the ad (if needed).
                completeAd()
            }

            if vTime < CHAPTER1_END_POS {
                if _isInChapter && _chapterPosition != 1 {
                    // If we were inside another chapter, complete it.
                    completeChapter()
                }

                if !(_isInChapter) {
                    // Start the first chapter.
                    startChapter1()
                }
            } else {
                if _isInChapter && _chapterPosition != 2 {
                    // If we were inside another chapter, complete it.
                    completeChapter()
                }

                if !(_isInChapter) {
                    // Start the second chapter.
                    startChapter2()
                }
            }
        }

        self.detectCCChange()
    }
}
