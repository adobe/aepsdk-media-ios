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
import AEPCore
import AEPServices

@objc(AEPMobileMedia)
public class Media: NSObject, Extension {
    private let LOG_TAG = "Media"

    // MARK: Extension
    public var runtime: ExtensionRuntime
    public var name = MediaConstants.EXTENSION_NAME
    public var friendlyName = MediaConstants.FRIENDLY_NAME
    public static var extensionVersion = MediaConstants.EXTENSION_VERSION
    public var metadata: [String: String]?
    let dependencies: [String] = [MediaConstants.Configuration.SHARED_STATE_NAME, MediaConstants.Identity.SHARED_STATE_NAME, MediaConstants.Analytics.SHARED_STATE_NAME]
    #if DEBUG
        var trackers: [String: MediaEventTracker] = [:]
        var mediaState: MediaState
        var mediaService: MediaService?
    #else
        private var trackers: [String: MediaCoreTracker] = [:]
        private var mediaState: MediaState
        private var mediaService: MediaService?
    #endif

    // MARK: Extension
    /// Initializes the Media extension and it's dependencies
    public required init(runtime: ExtensionRuntime) {
        self.runtime = runtime
        self.mediaState = MediaState()
        self.mediaService = MediaService(mediaState: mediaState)
    }

    /// Invoked when the Media extension has been registered by the `EventHub`
    public func onRegistered() {
        registerListener(type: EventType.configuration, source: EventSource.responseContent, listener: handleConfigurationResponseEvent)
        registerListener(type: MediaConstants.Media.EVENT_TYPE, source: MediaConstants.Media.EVENT_SOURCE_TRACKER_REQUEST, listener: handleMediaTrackerRequest)
        registerListener(type: MediaConstants.Media.EVENT_TYPE, source: MediaConstants.Media.EVENT_SOURCE_TRACK_MEDIA, listener: handleMediaTrack)
        registerListener(type: EventType.hub, source: EventSource.sharedState, listener: handleSharedStateUpdate)
    }

    /// Invoked when the Media extension has been unregistered by the `EventHub`, currently a no-op.
    public func onUnregistered() { }

    // Media extension is ready for an `Event` once configuration and identity shared state is available
    /// - Parameter event: an `Event`
    public func readyForEvent(_ event: Event) -> Bool {
        let configurationStatus = getSharedState(extensionName: MediaConstants.Configuration.SHARED_STATE_NAME, event: event)?.status ?? .none
        let identityStatus = getSharedState(extensionName: MediaConstants.Identity.SHARED_STATE_NAME, event: event)?.status ?? .none
        return configurationStatus == .set && identityStatus == .set
    }

    /// Passes Shared State Update events to the MediaService to update the MediaState.
    /// - Parameter:
    ///   - event: The configuration response event
    private func handleSharedStateUpdate(_ event: Event) {
        mediaService?.updateMediaState(event: event)
    }

    /// Processes Configuration Response content events to retrieve the configuration data and privacy status settings.
    /// - Parameter:
    ///   - event: The configuration response event
    private func handleConfigurationResponseEvent(_ event: Event) {
        var sharedStates = [String: [String: Any]?]()
        for extensionName in dependencies {
            sharedStates[extensionName] = runtime.getSharedState(extensionName: extensionName, event: event, barrier: true)?.value
        }
        mediaState.update(dataMap: sharedStates)

        if mediaState.getPrivacyStatus() == .optedOut {
            handleOptOut(event: event)
        }
    }

    /// Handler for media tracker creation events
    /// - Parameter event: an event containing  data for creating tracker
    private func handleMediaTrackerRequest(event: Event) {
        // TODO: revisit when media service implemented
        guard let eventData = event.data else {
            Log.error(label: LOG_TAG, "\(#function) - Failed to extract tracker request data (event data was nil).")
            return
        }

        guard let trackerId = eventData[MediaConstants.Tracker.ID] as? String, trackerId.count > 0 else {
            Log.debug(label: LOG_TAG, "\(#function) - Tracker ID is nil, unable to create tracker.")
            return
        }

        let trackerConfig = eventData[MediaConstants.Tracker.EVENT_PARAM] as? [String: Any] ?? [:]

        trackers[trackerId] = MediaEventTracker(hitProcessor: mediaService!, config: trackerConfig)
    }

    /// Handler for media track events
    /// - Parameter event: an event containing  media event data for processing
    private func handleMediaTrack(event: Event) {
        guard let eventData = event.data else {
            Log.error(label: LOG_TAG, "\(#function) - Failed to extract media track data (event data was nil).")
            return
        }

        guard let trackerId = eventData[MediaConstants.Tracker.ID] as? String, trackerId.count > 0 else {
            Log.error(label: LOG_TAG, "\(#function) - Unable to retrieve valid tracker id.")
            return
        }

        Log.debug(label: LOG_TAG, "\(#function) - tracking media for tracker id: \(trackerId).")
        _ = trackMedia(trackerId: trackerId, eventData: eventData)
    }

    private func trackMedia(trackerId: String, eventData: [String: Any]) -> Bool {
        if let tracker = trackers[trackerId] {
            return tracker.track(eventData: eventData)
        }
        Log.error(label: LOG_TAG, "\(#function) - Unable to find tracker for the given tracker id: \(trackerId).")
        return false
    }

    /// Clears persisted media sessions.
    private func handleOptOut(event: Event) {
        // TODO: revisit when media service implemented
        Log.debug(label: LOG_TAG, "\(#function) - Privacy status is opted-out. Clearing persisted media sessions.")
        // clear tracked sessions and end all running sessions within the media service
        trackers.removeAll()
        mediaService?.abortAllSessions()
    }

}
