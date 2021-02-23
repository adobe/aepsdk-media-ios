//
//  MediaOfflineService.swift
//  AEPMedia
//
//  Created by shtomar on 2/18/21.
//

import Foundation

class MediaOfflineService {
    
    func startSession() -> String {
        return UUID.init().uuidString;
    }
    
    func processHit(sessionId: String, hit : MediaHit) {
        
    }
    
    func stopSession(sessionId : String) -> Bool{
        return false;
    }
}
