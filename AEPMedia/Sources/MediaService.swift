//
//  MediaRealTimeService.swift
//  AEPMedia
//
//  Created by shtomar on 2/18/21.
//

import Foundation
import AEPCore
import AEPServices

class MediaService {
    
    private let LOG_TAG = "MediaRealTimeService"
    private let TIMER_REPEAT_INTERVAL = 0.25
    
    private var mediaState: MediaState
    private var timer: Timer?
    private var mediaSessions: [String: MediaRealTimeSession] = [:]
    
    
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
        mediaSessions[sessionId] = MediaRealTimeSession()
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
    
    
    func processHit(sessionId: String?, hit : MediaHit) {
        
        guard let sessionId = sessionId, !sessionId.isEmpty else {
            Log.debug(label: LOG_TAG, "\(#function) Null or empty session id passed.")
            return
        }
        
        guard mediaSessions.keys.contains(sessionId) else {
            Log.debug(label: LOG_TAG, "\(#function) Could not end media session. Invalid session id \(sessionId).")
            return
        }
        
        Log.trace(label: LOG_TAG, "\(#function) - Session (\(sessionId) Queueing hit %s.")
        let session = mediaSessions[sessionId]
        session?.queue(hit: hit)
        
        
    }
    
    func endSession(sessionId : String?) {
        
        guard let sessionId = sessionId, !sessionId.isEmpty else {
            Log.debug(label: LOG_TAG, "Null or empty session id passed.")
            return
        }
        
        let session = mediaSessions[sessionId]
        session?.end()
        Log.trace(label: LOG_TAG, "endSession - Session \(sessionId) ended.")

    }
    
    func startTick() {
        timer = Timer(label: "MediaRealTimeService", event: processMediaSession)
        timer?.startTimer(repeating: TIMER_REPEAT_INTERVAL)
    }
    
    func processMediaSession() {
        
        guard !mediaSessions.isEmpty else {
            Log.trace(label: LOG_TAG, "\(#function) - No Media sessions to process.")
            return
        }
        
        mediaSessions.forEach { sessionId, mediaSession in
            mediaSession.process()
            mediaSessions.removeValue(forKey: sessionId)
        }
        Log.trace(label: LOG_TAG, "Completed processing all media sessions.")
    }
    
    func stopTimer() {
        timer?.cancelTimer()
        timer = nil
    }
    
    func abortAllSession() {
        for (_, session) in mediaSessions {
            session.abort()
        }
    }
}
