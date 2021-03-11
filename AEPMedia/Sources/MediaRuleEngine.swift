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

class MediaRuleEngine {
    let LOG_TAG = "MediaRuleEngine"
    let RULE_NOT_FOUND = "Matching rule not found"
    var rules: [Int: MediaRule] = [:]
    var enterFn: ((MediaRule, [String: Any]) -> Bool)?
    var exitFn: ((MediaRule, [String: Any]) -> Bool)?

    @discardableResult
    func add(rule: MediaRule) -> Bool {
        if rules[rule.name] == nil {
            rules[rule.name] = rule
            return true
        }
        return false
    }

    func onEnterRule(enterFn: @escaping (MediaRule, [String: Any]) -> Bool) {
        self.enterFn = enterFn
    }

    func onExitRule(exitFn: @escaping (MediaRule, [String: Any]) -> Bool) {
        self.exitFn = exitFn
    }

    func processRule(name: Int, context: [String: Any]) -> (success: Bool, erorMsg: String) {
        guard let rule = rules[name] else {
            return (false, RULE_NOT_FOUND)
        }

        let predicateResult = rule.runPredicates(context: context)

        guard predicateResult.0 else {
            Log.debug(label: "\(LOG_TAG):\(#function)", "Predicates failed for Rule \(rule.description)")
            return predicateResult
        }

        // pass if no enterFn or if enterFn is a success
        if let enterFn=enterFn, !enterFn(rule, context) {
            Log.debug(label: "\(LOG_TAG):\(#function)", "Enter action prevents further processing for Rule \(rule.description)")
            return predicateResult
        }

        guard rule.runActions(context: context) else {
            Log.debug(label: "\(LOG_TAG):\(#function)", "Rule action prevents further processing for Rule \(rule.description)")
            return predicateResult
        }

        if let exitFn=exitFn, !exitFn(rule, context) {
            Log.trace(label: "\(LOG_TAG):\(#function)", "Exit action not found or resulted in a failure for Rule \(rule.description)")
        }

        return predicateResult
    }
}
