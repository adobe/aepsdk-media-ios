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

struct MediaDBService {

    func persistHit(hit: MediaHit, sessionId: String) {
        //TODO implement this function.
    }

    func deleteHits(sessionId id: String) {
        //TODO implement this function.
    }

    func getHits(sessionId id: String) -> [MediaHit] {
        //TODO implement this function.
        return [MediaHit]()
    }
    
    func getCachedSessionIds() -> [String] {
        //TODO implement this function.
        return [String]()
    }

}
