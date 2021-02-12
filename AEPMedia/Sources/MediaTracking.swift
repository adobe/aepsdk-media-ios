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

protocol MediaTracking {
    
    //TODO Implement this init after MediaHitProcessor implementation.
//    init(const std::shared_ptr<MediaHitProcessor>& hit_processor,
//                 const std::map<std::string, std::shared_ptr<Variant>>& config);
    
    func track(eventData: [String:Any])
    
}
