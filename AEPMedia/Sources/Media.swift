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

    /// Initializes the Media extension and it's dependencies
    public required init(runtime: ExtensionRuntime) {
        self.runtime = runtime
    }

    /// Invoked when the Media extension has been registered by the `EventHub`
    public func onRegistered() {
        //TODO
    }

    /// Invoked when the Media extension has been unregistered by the `EventHub`, currently a no-op.
    public func onUnregistered() {
        //TODO
    }

    // Media extension is ready for an `Event` once configuration shared state is available
    /// - Parameter event: an `Event`
    public func readyForEvent(_ event: Event) -> Bool {
        //TODO
        return false
    }

    // MARK: Event Listeners

    /// Handler for media  tracker creation events
    /// - Parameter event: an event containing  data for creating tracker
    private func handleMediaTrackerRequest(event: Event) {
        //TOO
    }

    /// Handler for media track events
    /// - Parameter event: an event containing  media event data for processing
    private func handleMediaTrack(event: Event) {
        //TOO
    }

}
