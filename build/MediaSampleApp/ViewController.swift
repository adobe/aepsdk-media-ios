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

import UIKit
import AEPAssurance

class ViewController: UIViewController {
    var adLabel: UILabel!
    var videoAnalyticsProvider: VideoAnalyticsProvider?
    var videoPlayer: VideoPlayer!

    override func viewWillAppear(_ animated: Bool) {
        let videoUrl = "http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8"

        var videoInfo: [String: Any] = [:]
        videoInfo["name"] = "Bip bop video"
        videoInfo["id"] = "bipbop"
        videoInfo["length"] = 1800

        if videoPlayer == nil {
            videoPlayer = VideoPlayer()
            videoPlayer.loadContentURL(url: URL(string: videoUrl)!)
            createAdLabel()
            renderVideoPlayer()
        }

        if videoAnalyticsProvider == nil {
            videoAnalyticsProvider = VideoAnalyticsProvider()
            videoAnalyticsProvider!.initWithPlayer(player: videoPlayer!)
        }
    }

    func createAdLabel() {
        let rect = CGRect(
            origin: CGPoint(x: 40, y: 20),
            size: CGSize.init(width: 200.0, height: 200.0)
        )
        adLabel = UILabel.init(frame: rect)
        adLabel.text = "AD"
        adLabel.isHidden = true
        adLabel.textColor = UIColor.white
    }

    func renderVideoPlayer() {
        if videoPlayer != nil {
            let playerViewController = videoPlayer.getPlayerViewController()
            // Modally present the player and call the player's play() method when complete.
            self.present(playerViewController, animated: true) {
                self.videoPlayer.play()
                playerViewController.view.addSubview(self.adLabel)
                playerViewController.view.bringSubviewToFront(self.adLabel)
            }
            addNotificationHandlers()
        }
    }

    func addNotificationHandlers() {
        NotificationCenter.default.addObserver(self, selector: #selector(VideoAnalyticsProvider.onAdStart), name: NSNotification.Name(rawValue: PLAYER_EVENT_AD_START), object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(VideoAnalyticsProvider.onAdComplete), name: NSNotification.Name(rawValue: PLAYER_EVENT_AD_COMPLETE), object: nil)
    }

    @objc func onAdStart(notification: NSNotification) {
        adLabel.isHidden = false
    }

    @objc func onAdComplete(notification: NSNotification) {
        adLabel.isHidden = true
    }

    @IBAction func OpenVideoView(_ sender: Any) {
        renderVideoPlayer()
    }

    func reset() {
        videoPlayer = nil
        videoAnalyticsProvider = nil
    }

    deinit {
        reset()
    }

    @IBOutlet weak var assuranceUrl: UITextField!

    @IBAction func startAssurnaceSession (_ sender: Any) {
        if let url = URL(string: assuranceUrl.text ?? "") {
            AEPAssurance.startSession(url)
        }
    }
}
