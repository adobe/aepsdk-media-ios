//
//  MediaRealTimeService.swift
//  AEPMedia
//
//  Created by shtomar on 2/18/21.
//

import Foundation
import AEPCore
import AEPServices

class MediaRealTimeService {
    
    private let LOG_TAG = "MediaRealTimeService"
    private let TIMER_REPEAT_INTERVAL = 0.25
    
    private var mediaState: MediaState
    private var timer: Timer?
    private var mediaSessions: [String: MediaSession] = [:]
    
    
    init(mediaState: MediaState) {
        self.mediaState = mediaState
        startTick();
    }
    
    func startSession() -> String? {
        guard mediaState.privacyStatus != .optedOut else {
            Log.debug(label: LOG_TAG, "Could not start new media session. Privacy is opted out.")
            return nil
        }
        
        let sessionId = UUID().uuidString
        mediaSessions[sessionId] = MediaSession()
        Log.trace(label: LOG_TAG, "Started new media session  \(sessionId).")
        return sessionId
    }
    
    func endSession(sessionId: String) {
        guard mediaSessions.keys.contains(sessionId) else {
            Log.debug(label: LOG_TAG, "Could not end media session. Invalid session id \(sessionId).")
            return
        }
        
        mediaSessions[sessionId]?.end()
        mediaSessions.removeValue(forKey: sessionId)
        Log.trace(label: LOG_TAG, "Successfully ends the session \(sessionId)")
    }
    
    
    func processHit(sessionId: SessionId, hit : MediaHit) {
        
        
    }
    
    func stopSession(sessionId : SessionId) -> Bool{
        timer?.cancelTimer()
        return false;
    }
    
    func startTick() {
        timer = Timer(label: "MediaRealTimeService", event: processMediaSession)
        timer?.startTimer(repeating: TIMER_REPEAT_INTERVAL)
    }
    
    func processMediaSession() {
        
    }
    
    func stopTimer() {
        timer?.cancelTimer()
        timer = nil
    }
}
