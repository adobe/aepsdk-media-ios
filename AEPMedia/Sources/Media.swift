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
        var sessionIdToTrackerIdMapping: [String: String] = [:]
        var mediaState: MediaState
        var trackerCalled = false
    #else
        private var sessionIdToTrackerIdMapping: [String: String] = [:]
        private var mediaState: MediaState
        private var trackerCalled = false
    #endif
    // private var mediaService: MediaService?

    // MARK: Extension
    /// Initializes the Media extension and it's dependencies
    public required init(runtime: ExtensionRuntime) {
        self.runtime = runtime
        self.mediaState = MediaState()
        // self.mediaService = MediaService(mediaState: mediaState)
    }

    /// Invoked when the Media extension has been registered by the `EventHub`
    public func onRegistered() {
        registerListener(type: EventType.configuration, source: EventSource.responseContent, listener: handleConfigurationResponseEvent)
        registerListener(type: MediaConstants.Media.EVENT_TYPE, source: MediaConstants.Media.EVENT_SOURCE_TRACKER_REQUEST, listener: handleMediaTrackerRequest)
        registerListener(type: MediaConstants.Media.EVENT_TYPE, source: MediaConstants.Media.EVENT_SOURCE_TRACK_MEDIA, listener: handleMediaTrack)
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

    /// Tries to retrieve the shared data for all the dependencies of the given event. When all the dependencies are resolved, it will update the `MediaState` with the shared states.
    /// Parameters:
    ///  - event: The `Event` for which shared state is to be retrieved.
    ///  - dependencies: An array of names of event's dependencies.
    private func updateMediaState(forEvent event: Event, dependencies: [String]) {
        var sharedStates = [String: [String: Any]?]()
        for extensionName in dependencies {
            sharedStates[extensionName] = runtime.getSharedState(extensionName: extensionName, event: event, barrier: true)?.value
        }
        mediaState.update(dataMap: sharedStates)
    }

    /// Processes Configuration Response content events to retrieve the configuration data and privacy status settings.
    /// - Parameter:
    ///   - event: The configuration response event
    private func handleConfigurationResponseEvent(_ event: Event) {
        updateMediaState(forEvent: event, dependencies: dependencies)
        if mediaState.getPrivacyStatus() == .optedOut {
            handleOptOut(event: event)
        }
    }

    /// Handler for media tracker creation events
    /// - Parameter event: an event containing  data for creating tracker
    private func handleMediaTrackerRequest(event: Event) {
        // TODO: revisit when media service implemented

        updateMediaState(forEvent: event, dependencies: dependencies)
        guard let trackerRequestData = event.data else {
            Log.error(label: LOG_TAG, "\(#function) - Failed to extract tracker request data (event data was nil).")
            return
        }

        guard let trackerId = trackerRequestData[MediaConstants.Tracker.ID] as? String, trackerId.count > 0 else {
            Log.debug(label: LOG_TAG, "\(#function) - Tracker ID is nil, unable to create tracker.")
            return
        }

        let trackerConfig = trackerRequestData[MediaConstants.Tracker.EVENT_PARAM] as? [String: Any] ?? [:]

        mediaState.setTrackerConfig(with: trackerConfig)
        // save returned session id in a dictionary using the tracker id as a key
        // sessionIdToTrackerIdMapping[trackerId] = mediaService?.createSession(state: mediaState) ?? ""

        // TODO: placeholder until MediaService available
        sessionIdToTrackerIdMapping[trackerId] = UUID().uuidString
    }

    /// Handler for media track events
    /// - Parameter event: an event containing  media event data for processing
    private func handleMediaTrack(event: Event) {
        updateMediaState(forEvent: event, dependencies: dependencies)

        guard let mediaTrackData = event.data else {
            Log.error(label: LOG_TAG, "\(#function) - Failed to extract media track data (event data was nil).")
            return
        }

        guard let trackerId = mediaTrackData[MediaConstants.Tracker.ID] as? String, trackerId.count > 0 else {
            Log.error(label: LOG_TAG, "\(#function) - Unable to retrieve valid tracker id.")
            return
        }

        guard let sessionId = sessionIdToTrackerIdMapping[trackerId] else {
            Log.error(label: LOG_TAG, "\(#function) - Unable to retrieve matching session id for the given tracking id.")
            return
        }

        Log.debug(label: LOG_TAG, "\(#function) - tracking media for sessionId: \(sessionId).")
        trackerCalled = trackMedia(sessionId: sessionId, eventData: mediaTrackData)
    }

    /// Clears persisted media sessions.
    private func handleOptOut(event: Event) {
        // TODO: revisit when media service implemented

        Log.debug(label: LOG_TAG, "\(#function) - Privacy status is opted-out. Clearing persisted media sessions.")
        // clear tracked sessions and abort all running sessions within the media service
        sessionIdToTrackerIdMapping.removeAll()
        // mediaService.abortAllSession()
    }

    private func trackMedia(sessionId: String, eventData: [String: Any]) -> Bool {
        // TODO: revisit when media service implemented

        /*
         let trackingSession = mediaService.mediaSessions[sessionId]
         guard let tracker = MediaCollectionEventTracking(session: trackingSession, state: mediaState) else {
             Log.error(label: LOG_TAG, "\(#function) - Unable to create tracker for session id: \(sessionId).")
             return false
         }

         tracker.track(eventData: eventData)
         return true
         */

        // TODO: placeholder for testing until MediaService available
        if sessionId.count > 0 {
            return true
        }
        return false
    }

}
