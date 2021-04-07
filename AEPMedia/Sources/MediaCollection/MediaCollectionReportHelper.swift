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
import AEPServices
import AEPCore

class MediaCollectionReportHelper {
    
    private static let LOG_TAG = "MediaCollectionReportHelper"

    private init() {}

    ///Returns the `URL` for session start. The response contains the `sessionId`
    ///- Parameter host: The tracking server url host component
    ///- Returns: Session start request URL
    static func getTrackingURL(host: String) -> String {
        guard !host.isEmpty else {
            Log.warning(label: LOG_TAG, "\(#function) Unable to create tracking url. Arguement url is empty.")
            return ""
        }
        
        var urlcomponents = URLComponents()
        urlcomponents.scheme = "https"
        urlcomponents.host = host
        urlcomponents.path = "/api/v1/sessions"
        return urlcomponents.string ?? ""
    }

    ///Returns the URL for sending `MediaHits`
    ///- Parameters:
    /// - host: Host component of the URL
    /// - sessionId: the session id of the Media session
    /// - Returns: URL for sending media hits
    static func getTrackingURLForEvents(host: String, sessionId: String?) -> String {
        guard !host.isEmpty, let sessionId = sessionId, !sessionId.isEmpty else {
            Log.warning(label: LOG_TAG, "\(#function) Unable to create tracking url for events. Arguement url or sessionId is empty.")
            return ""
        }
        
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = host
        urlComponents.path = "/api/v1/sessions/\(sessionId)/events"
        return urlComponents.string ?? ""
    }

    ///Generates the payload for `MediaHit` in `MediaRealTimeSession`
    ///- Parameters:
    ///   - state: Current Media state
    ///   - hit: Media hit to be send
    ///- Returns: The payload for Media hit
    static func generateHitReport(state: MediaState, hit: MediaHit) -> String? {
        let updatedHit = updateMediaHit(state: state, mediaHit: hit)
        if let data = try? JSONEncoder().encode(updatedHit) {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }

    ///Extracts the `session id` from the response of session start request
    ///- Parameter sessionResponseFragment: The response of session start request
    ///- Returns: Session id for the session
    static func extractSessionID(sessionResponseFragment: String) -> String? {
        
        guard !sessionResponseFragment.isEmpty else {
            return nil
        }
        
        let sessionIdPattern = "^/api/(.*)/sessions/(.*)"
        guard let regex = try? NSRegularExpression(pattern: sessionIdPattern, options: []) else {
            return nil
        }
        
        guard let result = regex.firstMatch(in: sessionResponseFragment, options: [], range: NSRange.init(location: 0, length: sessionResponseFragment.count)), result.numberOfRanges > 1 else {
            return nil
        }
        
        let innerSessionIdRange = result.range(at: 2)
        let startIndex = sessionResponseFragment.index(sessionResponseFragment.startIndex, offsetBy: innerSessionIdRange.lowerBound)
        let endIndex = sessionResponseFragment.index(sessionResponseFragment.startIndex, offsetBy: innerSessionIdRange.upperBound)
        return String(sessionResponseFragment[startIndex..<endIndex])
    }
    
    /// Validates that if all the required parameters for tracking MediaHits are present
    /// - Parameter state: Current `MediaState`
    /// - Returns: `true` if all the required tracking parameters are present else returns `false`
    static func hasAllTrackingParams(state: MediaState) -> Bool {
        if (state.getMediaCollectionServer().isEmpty) {
            Log.debug(label: LOG_TAG, "\(#function) - MediaCollectionServer is missing")
            return false
        } else if ((state.analyticsTrackingServer ?? "").isEmpty) {
            Log.debug(label: LOG_TAG, "\(#function) - analyticsTrackingServer is missing")
            return false
        } else if ((state.analyticsRsid ?? "").isEmpty) {
            Log.debug(label: LOG_TAG, "\(#function) - analyticsRsid is missing")
            return false
        } else if ((state.mcOrgId ?? "").isEmpty) {
            Log.debug(label: LOG_TAG, "\(#function) - mcOrgId is missing")
            return false
        } else if ((state.ecid ?? "").isEmpty) {
            Log.debug(label: LOG_TAG, "\(#function) - ecid is missing")
            return false
        }
        
        return true
    }
    
    ///Adds the additional parameters in the `MediaHit` params.
    ///- Parameters:
    ///   - state: Current `MediaState`
    ///   - mediaHit: The MediaHit object to be updated
    ///- Returns: Updated MediaHit object
    static func updateMediaHit(state: MediaState, mediaHit: MediaHit) -> MediaHit {
        
        if mediaHit.eventType == MediaConstants.MediaCollection.EventType.SESSION_START {
            var params = mediaHit.params ?? [String:Any]()
            if let analyticsTrackingServer = state.analyticsTrackingServer {
                params[MediaConstants.MediaCollection.Session.ANALYTICS_TRACKING_SERVER] = analyticsTrackingServer
            }
            params[MediaConstants.MediaCollection.Session.ANALYTICS_SSL] = true
            if let rsid = state.analyticsRsid {
                params[MediaConstants.MediaCollection.Session.ANALYTICS_RSID] = rsid
            }
            
            if let vid = state.vid {
                params[MediaConstants.MediaCollection.Session.ANALYTICS_VISITOR_ID] = vid
            }
            
            if let aid = state.aid {
                params[MediaConstants.MediaCollection.Session.ANALYTICS_AID] = aid
            }
            
            if let orgId = state.mcOrgId {
                params[MediaConstants.MediaCollection.Session.VISITOR_MCORG_ID] = orgId
            }
            
            if let mcId = state.ecid {
                params[MediaConstants.MediaCollection.Session.VISITOR_MCUSER_ID] = mcId
            }
            
            if let locHintValue = state.locHint{
                params[MediaConstants.MediaCollection.Session.VISITOR_AAM_LOC_HINT] = locHintValue
            }
            
            if let customerIDs = state.visitorCustomerIDs, customerIDs.count > 0 {
                params[MediaConstants.MediaCollection.Session.VISITOR_CUSTOMER_IDS] = serializeCustomerId(customerIds: customerIDs)
            }
            
            if !params.keys.contains(MediaConstants.MediaCollection.Session.MEDIA_CHANNEL), let mediaChannel = state.mediaChannel {
                params[MediaConstants.MediaCollection.Session.MEDIA_CHANNEL] = mediaChannel
            }
            
            if let mediaPlayerName = state.mediaPlayerName {
                params[MediaConstants.MediaCollection.Session.MEDIA_PLAYER_NAME] = mediaPlayerName
            }
            
            if let appVersion = state.mediaAppVersion, !appVersion.isEmpty {
                params[MediaConstants.MediaCollection.Session.SDK_VERSION] = appVersion
            }
            
            params[MediaConstants.MediaCollection.Session.MEDIA_VERSION] = MediaConstants.EXTENSION_VERSION
                
            return MediaHit(eventType: mediaHit.eventType, playhead: mediaHit.playhead, ts: mediaHit.timestamp, params: params, customMetadata: mediaHit.metadata, qoeData: mediaHit.qoeData)
            
        }
        
        if mediaHit.eventType == MediaConstants.MediaCollection.EventType.AD_START {
            var params = mediaHit.params ?? [String:Any]()
            if let mediaPlayerName = state.mediaPlayerName {
                params[MediaConstants.MediaCollection.Ad.PLAYER_NAME] = mediaPlayerName
            }
            return MediaHit(eventType: mediaHit.eventType, playhead: mediaHit.playhead, ts: mediaHit.timestamp, params: params, customMetadata: mediaHit.metadata, qoeData: mediaHit.qoeData)
        }
        
        return mediaHit
    }
    
    ///Serializes the VisitorId's to required format
    private static func serializeCustomerId(customerIds: [[String:Any]]) -> [String: [String: Any]] {
        var serializedCustomerIds: [String: [String: Any]] = [:]
        for customerId in customerIds {
            if let idType = customerId[MediaConstants.MediaCollection.Session.VISITOR_ID_TYPE] as? String, let idValue = customerId[MediaConstants.MediaCollection.Session.VISITOR_ID] as? String, let authState = customerId[MediaConstants.MediaCollection.Session.VISITOR_ID_AUTHENTICATION_STATE] as? Int {
                serializedCustomerIds[idType] = ["id": idValue, "authState":authState]
            }
        }
        
        return serializedCustomerIds
    }
        
    ///Generates the payload for MediaOffline session tracking
    ///- Parameters:
    ///   - state: Current `MediaState` object
    ///   - hits: Array of `MediaHit` in offline session
    ///- Returns: Payload for offline tracking request
    static func generateDownloadReport(state: MediaState, hits: [MediaHit]) -> String? {
        guard hits.count > 0 else {
            Log.debug(label: LOG_TAG, "\(#function) - Media Hits array passed is empty. Returning nil.")
            return nil
        }
        
        var hasSessionStarted = false
        var hasSessionEnded = false
        var lastPlayhead: Double = 0
        var lastTimestamp: TimeInterval = 0
        var updatedMediaHits: [MediaHit] = []
        
        for hit in hits {
            if !hasSessionStarted {
                hasSessionStarted = hit.eventType == MediaConstants.MediaCollection.EventType.SESSION_START
                if !hasSessionStarted {
                    continue
                }
            }
            
            if hasSessionEnded {
                break
            } else {
                hasSessionEnded = (hit.eventType == MediaConstants.MediaCollection.EventType.SESSION_END) || (hit.eventType == MediaConstants.MediaCollection.EventType.SESSION_COMPLETE)
            }
            
            updatedMediaHits.append(updateMediaHit(state: state, mediaHit: hit))
            lastPlayhead = hit.playhead
            lastTimestamp = hit.timestamp
        }
        
        if !hasSessionStarted {
            return nil
        }
        
        if hasSessionStarted && !hasSessionEnded {
            let hit = MediaHit(eventType: MediaConstants.MediaCollection.EventType.SESSION_END, playhead: lastPlayhead, ts: lastTimestamp, params: nil, customMetadata: nil, qoeData: nil)
            
            updatedMediaHits.append(updateMediaHit(state: state, mediaHit: hit))
        }
        
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(updatedMediaHits) {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
}
