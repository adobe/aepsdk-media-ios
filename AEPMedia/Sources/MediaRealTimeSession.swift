//
//  MediaSession.swift
//  AEPMedia
//
//  Created by shtomar on 2/22/21.
//

import Foundation
import AEPCore
import AEPServices

class MediaRealTimeSession {
    
    private let LOG_TAG = "MediaRealTimeSession"
    private static let RETRY_COUNT = 2
    private static let MAX_ALLOWED_DURATION_BETWEEN_HITS: TimeInterval = 60
    
    private var hits: [MediaHit] = []
    private var state: MediaState
    private var sessionId: String?
    private var isSessionActive: Bool?
    private var isSendingHit: Bool?
    private var sessionStartRetryCount: Int?
    private var lastRefTS: UInt8?
    
    init(state: MediaState) {
        self.state = state
    }
    
    func queue(hit: MediaHit?) {
        guard let hit = hit else {
            Log.debug(label: LOG_TAG, "\(#function) - Returning early. MediaHit passed is nil.")
            return
        }
        hits.append(hit)
    }
    
    func process() {
        trySendHit()
    }
    
    func end() {
        if !(isSessionActive ?? false){
            Log.trace(label: LOG_TAG, "\(#function) - Session is already ended.")
            return
        }
        
        isSessionActive = false
    }
    
    func abort() {
        if !(isSessionActive ?? false){
            Log.trace(label: LOG_TAG, "\(#function) - Session is already ended.")
            return
        }
        
        isSessionActive = false
        hits.removeAll()
    }

    func finishedProcessing() -> Bool {
        return !(isSessionActive ?? false) && !(isSendingHit ?? false) && hits.isEmpty
    }
    
    func trySendHit() {
        guard !hits.isEmpty else {
            Log.trace(label: LOG_TAG, "\(#function) - MediaHit collection is empty.")
            return
        }
        
        guard !(isSendingHit ?? false) else {
            Log.trace(label: LOG_TAG, "\(#function) - Returning early. Already sending a Media hit.")
            return
        }
    }
}
