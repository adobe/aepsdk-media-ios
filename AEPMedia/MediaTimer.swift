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

struct MediaTimer {
    
    private var timer: DispatchSourceTimer?
    
    init(label: String, event: (() -> Void)?) {
        let queue = DispatchQueue(label: label)
        timer = DispatchSource.makeTimerSource(queue: queue)
        timer?.setEventHandler(handler: event)
    }
    
    func startTimer(repeating interval: Double) {
        timer?.schedule(deadline: .now(), repeating: interval)
        timer?.activate()
    }
    
    func cancelTimer() {
        timer?.cancel()
    }
    
    func isTimerRunning() -> Bool {
        return (timer?.isCancelled ?? true) != true
    }
}
