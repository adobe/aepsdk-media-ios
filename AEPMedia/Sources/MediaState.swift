/*
 Copyright 2021 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0
 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES  REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

import Foundation
import AEPCore
import AEPServices


class MediaState {
    //TODO: implementation of this class.
    private let LOG_TAG = "MediaState"
    
    private(set) var privacyStatus: PrivacyStatus = .unknown

    // Media Config
    private(set) var mediaTrackingServer: String?
    private(set) var mediaCollectionServer: String?
    private(set) var mediaChannel: String?
    private(set) var mediaOvp: String?
    private(set) var mediaPlayerName: String?
    private(set) var mediaAppVersion: String?
    private(set) var mediaDebugLogging: Bool?

    // Analytics Config
    private(set) var analyticsRsid: String?
    private(set) var analyticsTrackingServer: String?

    // Identity Config
    private(set) var mcOrgId: String?

    // Analytics State
    private(set) var aid: String?
    private(set) var vid: String?

    // Identity State
    private(set) var ecid: String?
    private(set) var locHint: Int?
    private(set) var blob: String?
    private(set) var visitorCustomerIDs: [[String: Any]]?

    /// Takes the shared states map and updates the data within the Media State.
    /// - Parameter dataMap: The map contains the shared state data required by the Analytics SDK.
    func update(dataMap: [String: [String: Any]?]) {
        for key in dataMap.keys {
            guard let sharedState = dataMap[key] else {
                continue
            }
            switch key {
            case MediaConstants.Configuration.SHARED_STATE_NAME:
                extractConfigurationInfo(from: sharedState)
            case MediaConstants.Identity.SHARED_STATE_NAME:
                extractIdentityInfo(from: sharedState)
            case MediaConstants.Analytics.SHARED_STATE_NAME:
                extractAnalyticsInfo(from: sharedState)
            default:
                break
            }
        }
    }

    /// Extracts the configuration data from the provided shared state data.
    /// - Parameter configurationData the data map from `Configuration` shared state.
    func extractConfigurationInfo(from configurationData: [String: Any]?) {
        guard let configurationData = configurationData else {
            Log.trace(label: LOG_TAG, "\(#function) - Failed to extract configuration data (event data was nil).")
            return
        }
        self.privacyStatus = PrivacyStatus.init(rawValue: configurationData[MediaConstants.Configuration.GLOBAL_CONFIG_PRIVACY] as? PrivacyStatus.RawValue ?? PrivacyStatus.unknown.rawValue) ?? .unknown

        self.mcOrgId = configurationData[MediaConstants.Configuration.EXPERIENCE_CLOUD_ORGID] as? String
        self.analyticsTrackingServer = configurationData[MediaConstants.Configuration.ANALYTICS_TRACKING_SERVER] as? String
        self.analyticsRsid = configurationData[MediaConstants.Configuration.ANALYTICS_RSID] as? String
        self.mediaTrackingServer = configurationData[MediaConstants.Configuration.MEDIA_TRACKING_SERVER] as? String
        self.mediaCollectionServer = configurationData[MediaConstants.Configuration.MEDIA_COLLECTION_SERVER] as? String
        self.mediaChannel = configurationData[MediaConstants.Configuration.MEDIA_CHANNEL] as? String
        self.mediaOvp = configurationData[MediaConstants.Configuration.MEDIA_OVP] as? String
        self.mediaPlayerName = configurationData[MediaConstants.Configuration.MEDIA_PLAYER_NAME] as? String
        self.mediaAppVersion = configurationData[MediaConstants.Configuration.MEDIA_APP_VERSION] as? String
        self.mediaDebugLogging = configurationData[MediaConstants.Configuration.MEDIA_DEBUG_LOGGING] as? Bool ?? false
    }

    /// Extracts the identity data from the provided shared state data.
    /// - Parameter identityData the data map from `Identity` shared state.
    func extractIdentityInfo(from identityData: [String: Any]?) {
        guard let identityData = identityData else {
            Log.trace(label: LOG_TAG, "\(#function) - Failed to extract identity data (event data was nil).")
            return
        }
        self.ecid = identityData[MediaConstants.Identity.MARKETING_VISITOR_ID] as? String
        self.locHint = identityData[MediaConstants.Identity.LOC_HINT] as? Int
        self.blob = identityData[MediaConstants.Identity.BLOB] as? String
        self.visitorCustomerIDs = identityData[MediaConstants.Identity.VISITOR_IDS_LIST] as? [[String:Any]]
    }

    /// Extracts the analytics data from the provided shared state data.
    /// - Parameter analyticsData the data map from `Analytics` shared state.
    func extractAnalyticsInfo(from analyticsData: [String: Any]?) {
        guard let analyticsData = analyticsData else {
            Log.trace(label: LOG_TAG, "\(#function) - Failed to extract analytics data (event data was nil).")
            return
        }
        self.aid = analyticsData[MediaConstants.Analytics.ANALYTICS_VISITOR_ID] as? String
        self.vid = analyticsData[MediaConstants.Analytics.VISITOR_ID] as? String
    }

    func getPrivacyStatus() -> PrivacyStatus {
        return privacyStatus
    }

    func getMediaCollectionServer() -> String {
        return mediaCollectionServer ?? ""
    }
}
