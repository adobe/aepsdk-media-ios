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

// MARK: TODO remove this once Assurance has tvOS support.
#if os(iOS)
    import AEPAssurance
#endif

class ViewController: UIViewController {
    var adLabel: UILabel?
    var videoAnalyticsProvider: VideoAnalyticsProvider?
    var videoPlayer: VideoPlayer?

    override func viewWillAppear(_ animated: Bool) {

        guard let video = Bundle.main.path(forResource: "video", ofType: "mp4") else {
            return
        }

        let videoUrl = URL(fileURLWithPath: video)

        // For live stream, include the url in below URL
        /*guard let videoUrl: URL = URL(string: "") else {
             return
         }*/

        if videoPlayer == nil {
            videoPlayer = VideoPlayer()
            videoPlayer?.loadContentURL(url: videoUrl)
            createAdLabel()
            renderVideoPlayer()
        }

        if videoAnalyticsProvider == nil {
            videoAnalyticsProvider = VideoAnalyticsProvider()
            videoAnalyticsProvider?.initWithPlayer(player: videoPlayer!)
        }
    }

    func createAdLabel() {
        let rect = CGRect(
            origin: CGPoint(x: 40, y: 20),
            size: CGSize.init(width: 200.0, height: 200.0)
        )
        adLabel = UILabel.init(frame: rect)
        adLabel?.text = "AD"
        adLabel?.isHidden = true
        adLabel?.textColor = UIColor.white
    }

    func renderVideoPlayer() {
        if videoPlayer != nil {
            guard let playerViewController = videoPlayer?.getPlayerViewController() else {
                return }
            // Modally present the player and call the player's play() method when complete.
            self.present(playerViewController, animated: true) {
                self.videoPlayer?.play()
                guard let adLabel = self.adLabel else {
                    return
                }
                playerViewController.view.addSubview(adLabel)
                playerViewController.view.bringSubviewToFront(adLabel)
            }
            addNotificationHandlers()
        }
    }

    func addNotificationHandlers() {
        NotificationCenter.default.addObserver(self, selector: #selector(VideoAnalyticsProvider.onAdStart), name: NSNotification.Name(rawValue: PlayerEvent.PLAYER_EVENT_AD_START), object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(VideoAnalyticsProvider.onAdComplete), name: NSNotification.Name(rawValue: PlayerEvent.PLAYER_EVENT_AD_COMPLETE), object: nil)
    }

    @objc func onAdStart(notification: NSNotification) {
        adLabel?.isHidden = false
    }

    @objc func onAdComplete(notification: NSNotification) {
        adLabel?.isHidden = true
    }

    @IBAction func OpenVideoView(_ sender: Any) {
        renderVideoPlayer()
    }

    @IBOutlet weak var assuranceUrl: UITextField!

    @IBAction func startAssuranceSession (_ sender: Any) {
        // MARK: TODO remove this once Assurance has tvOS support.
        #if os(iOS)
            if let url = URL(string: assuranceUrl.text ?? "") {
                Assurance.startSession(url: url)
            }
        #endif
    }

    func reset() {
        videoPlayer = nil
        videoAnalyticsProvider = nil
    }

    deinit {
        reset()
    }
}
