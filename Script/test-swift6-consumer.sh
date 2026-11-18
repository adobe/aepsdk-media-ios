#!/bin/bash

set -e # Any subsequent(*) commands which fail will cause the shell script to exit immediately

# Builds a minimal Swift 6 consumer of AEPMedia to make sure Swift 6 apps can use
# the public Media APIs from @MainActor code. The consumer creates a tracker and
# media objects and drives a full tracking session the same way a player
# integration in a SwiftUI or UIKit app would.

PROJECT_NAME=Swift6Consumer

# Clean up.
rm -rf $PROJECT_NAME

mkdir -p $PROJECT_NAME && cd $PROJECT_NAME

# Create the package.
swift package init

# Create the Package.swift. The consumer target is compiled in Swift 6 language
# mode; dependencies keep their own declared language modes.
echo "// swift-tools-version:6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription
let package = Package(
    name: \"Swift6Consumer\",
    defaultLocalization: \"en-US\",
    platforms: [
        .iOS(.v15), .tvOS(.v15)
    ],
    products: [
        .library(
            name: \"Swift6Consumer\",
            targets: [\"Swift6Consumer\"]
        )
    ],
    dependencies: [
        .package(name: \"AEPCore\", url: \"https://github.com/adobe/aepsdk-core-ios.git\", .branch(\"main\")),
        .package(name: \"AEPMedia\", path: \"../\")
    ],
    targets: [
        .target(
            name: \"Swift6Consumer\",
            dependencies: [
                .product(name: \"AEPCore\", package: \"AEPCore\"),
                .product(name: \"AEPMedia\", package: \"AEPMedia\"),
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ])
    ]
)
" >Package.swift

# Replace the generated source with a @MainActor consumer that exercises the
# public Media APIs.
rm -rf Sources/Swift6Consumer
mkdir -p Sources/Swift6Consumer
echo "import AEPCore
import AEPMedia
import Foundation

@MainActor
final class Swift6Consumer {
    private var tracker: MediaTracker?

    func registerAndConfigure() {
        MobileCore.registerExtensions([Media.self])
    }

    func exercise() {
        let tracker = Media.createTrackerWith(config: [MediaConstants.TrackerConfig.CHANNEL: \"swift6-consumer\"])
        self.tracker = tracker

        guard let mediaObject = Media.createMediaObjectWith(name: \"video\", id: \"videoId\", length: 60, streamType: MediaConstants.StreamType.VOD, mediaType: MediaType.Video),
              let adBreakObject = Media.createAdBreakObjectWith(name: \"adBreak\", position: 1, startTime: 0),
              let adObject = Media.createAdObjectWith(name: \"ad\", id: \"adId\", position: 1, length: 15),
              let chapterObject = Media.createChapterObjectWith(name: \"chapter\", position: 1, length: 30, startTime: 0),
              let qoeObject = Media.createQoEObjectWith(bitrate: 500000, startupTime: 2, fps: 24, droppedFrames: 10),
              let stateObject = Media.createStateObjectWith(stateName: MediaConstants.PlayerState.FULLSCREEN) else {
            return
        }

        tracker.trackSessionStart(info: mediaObject, metadata: [\"key\": \"value\"])
        tracker.trackPlay()
        tracker.trackEvent(event: MediaEvent.AdBreakStart, info: adBreakObject, metadata: nil)
        tracker.trackEvent(event: MediaEvent.AdStart, info: adObject, metadata: nil)
        tracker.trackEvent(event: MediaEvent.AdComplete, info: nil, metadata: nil)
        tracker.trackEvent(event: MediaEvent.AdBreakComplete, info: nil, metadata: nil)
        tracker.trackEvent(event: MediaEvent.ChapterStart, info: chapterObject, metadata: nil)
        tracker.trackEvent(event: MediaEvent.StateStart, info: stateObject, metadata: nil)
        tracker.updateCurrentPlayhead(time: 10)
        tracker.updateQoEObject(qoe: qoeObject)
        tracker.trackPause()
        tracker.trackError(errorId: \"error\")
        tracker.trackEvent(event: MediaEvent.ChapterComplete, info: nil, metadata: nil)
        tracker.trackComplete()
        tracker.trackSessionEnd()
    }
}
" >Sources/Swift6Consumer/Swift6Consumer.swift

swift package update
swift package resolve

# This is necessary to avoid internal PIF error
swift package dump-pif > /dev/null
(xcodebuild clean -scheme Swift6Consumer -destination 'generic/platform=iOS' > /dev/null) || :

# Build for generic iOS device in Swift 6 language mode
echo '############# Build Swift 6 consumer for generic iOS device ###############'
xcodebuild build -scheme Swift6Consumer -destination 'generic/platform=iOS'

# Build for generic tvOS device in Swift 6 language mode
echo '############# Build Swift 6 consumer for generic tvOS device ###############'
xcodebuild build -scheme Swift6Consumer -destination 'generic/platform=tvOS'

# Clean up.
cd ../
rm -rf $PROJECT_NAME
