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
    private static let LOG_TAG = MediaConstants.LOG_TAG
    private static let CLASS_NAME = "MediaState"
    private(set) var privacyStatus: PrivacyStatus = .unknown

    // Media Config
    private(set) var mediaCollectionServer: String?
    private(set) var mediaChannel: String?
    private(set) var mediaOvp: String?
    private(set) var mediaPlayerName: String?
    private(set) var mediaAppVersion: String?

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

    // Assurance State
    private(set) var assuranceIntegrationId: String?

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
            case MediaConstants.Assurance.SHARED_STATE_NAME:
                extractAssuranceInfo(from: sharedState)
            default:
                break
            }
        }
    }

    /// Extracts the configuration data from the provided shared state data.
    /// - Parameter configurationData the data map from `Configuration` shared state.
    func extractConfigurationInfo(from configurationData: [String: Any]?) {
        guard let configurationData = configurationData else {
            Log.trace(label: Self.LOG_TAG, "[\(Self.CLASS_NAME)<\(#function)>] - Failed to extract configuration data (event data was nil).")
            return
        }
        self.privacyStatus = PrivacyStatus.init(rawValue: configurationData[MediaConstants.Configuration.GLOBAL_CONFIG_PRIVACY] as? PrivacyStatus.RawValue ?? PrivacyStatus.unknown.rawValue) ?? .unknown

        self.mcOrgId = configurationData[MediaConstants.Configuration.EXPERIENCE_CLOUD_ORGID] as? String
        self.analyticsTrackingServer = configurationData[MediaConstants.Configuration.ANALYTICS_TRACKING_SERVER] as? String
        self.analyticsRsid = configurationData[MediaConstants.Configuration.ANALYTICS_RSID] as? String
        self.mediaCollectionServer = configurationData[MediaConstants.Configuration.MEDIA_COLLECTION_SERVER] as? String
        self.mediaChannel = configurationData[MediaConstants.Configuration.MEDIA_CHANNEL] as? String
        self.mediaPlayerName = configurationData[MediaConstants.Configuration.MEDIA_PLAYER_NAME] as? String
        self.mediaAppVersion = configurationData[MediaConstants.Configuration.MEDIA_APP_VERSION] as? String
    }

    /// Extracts the identity data from the provided shared state data.
    /// - Parameter identityData the data map from `Identity` shared state.
    func extractIdentityInfo(from identityData: [String: Any]?) {
        guard let identityData = identityData else {
            Log.trace(label: Self.LOG_TAG, "[\(Self.CLASS_NAME)<\(#function)>] - Failed to extract identity data (event data was nil).")
            return
        }
        self.ecid = identityData[MediaConstants.Identity.MARKETING_VISITOR_ID] as? String
        if let locHintString = identityData[MediaConstants.Identity.LOC_HINT] as? String {
            self.locHint = Int(locHintString)
        }
        self.blob = identityData[MediaConstants.Identity.BLOB] as? String
        self.visitorCustomerIDs = identityData[MediaConstants.Identity.VISITOR_IDS_LIST] as? [[String: Any]]
    }

    /// Extracts the analytics data from the provided shared state data.
    /// - Parameter analyticsData the data map from `Analytics` shared state.
    func extractAnalyticsInfo(from analyticsData: [String: Any]?) {
        guard let analyticsData = analyticsData else {
            Log.trace(label: Self.LOG_TAG, "[\(Self.CLASS_NAME)<\(#function)>] - Failed to extract analytics data (event data was nil).")
            return
        }
        self.aid = analyticsData[MediaConstants.Analytics.ANALYTICS_VISITOR_ID] as? String
        self.vid = analyticsData[MediaConstants.Analytics.VISITOR_ID] as? String
    }

    /// Extracts the assurance data from the provided shared state data.
    /// - Parameter assuranceData the data map from `Analytics` shared state.
    func extractAssuranceInfo(from assuranceData: [String: Any]?) {
        guard let assuranceData = assuranceData else {
            Log.trace(label: Self.LOG_TAG, "[\(Self.CLASS_NAME)<\(#function)>] - Failed to extract assurance data (event data was nil).")
            return
        }
        self.assuranceIntegrationId = assuranceData[MediaConstants.Assurance.INTEGRATION_ID] as? String
    }
}
