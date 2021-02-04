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

import XCTest
@testable import AEPMedia

class MediaTests: XCTestCase {
    let RULE_NOT_FOUND_MSG = "Matching rule not found"
    var action1CalledCount = 0
    var action2CalledCount = 0
    
    override func setUp() {
    }

    override func tearDown() {
        reset()
    }
    
    func reset() {
        action1CalledCount = 0
        action2CalledCount = 0
    }
    
    func actionHelper1(rule: MediaRule, context: [String:Any]) {
        action1CalledCount += 1
    }
    
    func actionHelper2(rule: MediaRule, context: [String:Any]) {
        action2CalledCount += 1
    }
    
    //MARK: MediaRuleEngine Unit Tests
    
    // ==========================================================================
    // addRule
    // ==========================================================================
    func testAddRule_Happy() {
        //setup
        let ruleEngine = MediaRuleEngine()
        let testRule = MediaRule(name: 1, description: "rule1")
        
        //test and verify
        XCTAssertTrue(ruleEngine.addRule(rule: testRule))
    }
    
    func testAddDuplicateRule_Fail() {
        //setup
        let ruleEngine = MediaRuleEngine()
        let testRule = MediaRule(name: 1, description: "rule1")
        
        //test and verify
        XCTAssertTrue(ruleEngine.addRule(rule: testRule))
        //Should fail when trying to add same rule
        XCTAssertFalse(ruleEngine.addRule(rule: testRule))
    }
    
    // ==========================================================================
    // processRule
    // ==========================================================================
    func testProcessRule_NoRuleFound_Fail() {
        //setup
        let ruleEngine = MediaRuleEngine()
        
        //test
        let res = ruleEngine.processRule(ruleName: 1, context: [:])
        
        //verify
        XCTAssertFalse(res.0)
        XCTAssertEqual(RULE_NOT_FOUND_MSG, res.1)
    }
    
    func testProcessRule_NoPredicates() {
        //setup
        let ruleEngine = MediaRuleEngine()
        let testRule = MediaRule(name: 1, description: "rule1")
        testRule.addAction { (rule, context) -> Bool in
            self.actionHelper1(rule: rule, context: context)
            return true
        }
        
        //test
        XCTAssertTrue(ruleEngine.addRule(rule: testRule))
        let res = ruleEngine.processRule(ruleName: 1, context: [:])
        
        //verify
        XCTAssertEqual(1, action1CalledCount)
        XCTAssertTrue(res.0)
    }
    
    func testProcessRule_NoAction() {
        //setup
        let ruleEngine = MediaRuleEngine()
        let testRule = MediaRule(name: 1, description: "rule1")
        testRule.addPredicate(predicateFn: { (rule, context) -> Bool in
            return true
        }, expectedValue: true, errorMsg: "test error")
        
        //test
        XCTAssertTrue(ruleEngine.addRule(rule: testRule))
        let res = ruleEngine.processRule(ruleName: 1, context: [:])
        
        //verify
        XCTAssertTrue(res.0)
    }
    
    func testProcessRule_PredicateFailure() {
        //setup
        let ruleEngine = MediaRuleEngine()
        let testRule = MediaRule(name: 1, description: "rule1")
        
        //test
        let test1 = "Test error 1"
        testRule.addPredicate(predicateFn: { (rule, context) -> Bool in
            return true
        }, expectedValue: true, errorMsg: test1)
        
        let test2 = "Test error 2"
        testRule.addPredicate(predicateFn: { (rule, context) -> Bool in
            return true
        }, expectedValue: false, errorMsg: test2)
        
        ruleEngine.addRule(rule: testRule)
        let res = ruleEngine.processRule(ruleName: 1, context: [:])
        
        //verify
        XCTAssertFalse(res.0)
        XCTAssertEqual(test2, res.1)
    }
    
    func testProcessRule_ExecuteAction() {
        //setup
        let ruleEngine = MediaRuleEngine()
        let testRule = MediaRule(name: 1, description: "rule1")
        
        //test
        let test1 = "Test error 1"
        testRule.addPredicate(predicateFn: { (rule, context) -> Bool in
            return true
        }, expectedValue: true, errorMsg: test1)
        
        testRule.addAction { (rule, context) -> Bool in
            self.actionHelper1(rule: rule, context: context)
            return true
        }
        
        testRule.addAction { (rule, context) -> Bool in
            self.actionHelper1(rule: rule, context: context)
            return true
        }
        
        ruleEngine.addRule(rule: testRule)
        let res = ruleEngine.processRule(ruleName: 1, context: [:])
        
        //verify
        XCTAssertEqual(2, action1CalledCount)
        XCTAssertTrue(res.0)
    }
    
    func testProcessRule_StopAfterFailingAction() {
        //setup
        let ruleEngine = MediaRuleEngine()
        let testRule = MediaRule(name: 1, description: "rule1")
        
        //test
        let test1 = "Test error 1"
        testRule.addPredicate(predicateFn: { (rule, context) -> Bool in
            return true
        }, expectedValue: true, errorMsg: test1)
        
        testRule.addAction { (rule, context) -> Bool in
            self.actionHelper1(rule: rule, context: context)
            return false
        }
        
        testRule.addAction { (rule, context) -> Bool in
            self.actionHelper2(rule: rule, context: context)
            return true
        }
        
        ruleEngine.addRule(rule: testRule)
        
        //test
        let res = ruleEngine.processRule(ruleName: 1, context: [:])
        
        //verify
        XCTAssertEqual(1, action1CalledCount)
        XCTAssertEqual(0, action2CalledCount)
        XCTAssertTrue(res.0)
    }
    
    func testProcessRule_EnterExitAction() {
        //setup
        let ruleEngine = MediaRuleEngine()
        let testRule = MediaRule(name: 1, description: "rule1")
        
        //test
        testRule.addPredicate(predicateFn: { (rule, context) -> Bool in
            return true
        }, expectedValue: true, errorMsg: "test1")
        
        testRule.addAction { (rule, context) -> Bool in
            return true
        }
        
        ruleEngine.addRule(rule: testRule)
        
        ruleEngine.onEnterRule { (rule, context) -> Bool in
            self.actionHelper1(rule: rule, context: context)
            return true
        }
        
        ruleEngine.onExitRule { (rule, context) -> Bool in
            self.actionHelper2(rule: rule, context: context)
            return true
        }
        
        
        //test
        let res = ruleEngine.processRule(ruleName: 1, context: [:])
        
        //verify
        XCTAssertEqual(1, action1CalledCount)
        XCTAssertEqual(1, action2CalledCount)
        XCTAssertTrue(res.0)
    }
    
    func testProcessRule_StopAfterFailingEnterAction() {
        //setup
        let ruleEngine = MediaRuleEngine()
        let testRule = MediaRule(name: 1, description: "rule1")
        
        //test
        testRule.addPredicate(predicateFn: { (rule, context) -> Bool in
            return true
        }, expectedValue: true, errorMsg: "test1")
        
        testRule.addAction { (rule, context) -> Bool in
            //should not be called
            self.actionHelper2(rule: rule, context: context)
            return true
        }
        
        ruleEngine.addRule(rule: testRule)
        
        ruleEngine.onEnterRule { (rule, context) -> Bool in
            //should be called
            self.actionHelper1(rule: rule, context: context)
            return false
        }
        
        ruleEngine.onExitRule { (rule, context) -> Bool in
            //should not be called
            self.actionHelper2(rule: rule, context: context)
            return true
        }
        
        
        //test
        let res = ruleEngine.processRule(ruleName: 1, context: [:])
        
        //verify
        XCTAssertEqual(1, action1CalledCount)
        XCTAssertEqual(0, action2CalledCount)
        XCTAssertTrue(res.0)
    }
    
    func testProcessRule_PassContextData() {
        //setup
        let ruleEngine = MediaRuleEngine()
        let testRule = MediaRule(name: 1, description: "rule1")
        var contextData: [String:Any] = ["k1":"v1"]
        
        //test
        let test1 = "Test error 1"
        testRule.addPredicate(predicateFn: { (rule, context) -> Bool in
            XCTAssertNotNil(context["k1"])
            XCTAssertEqual("v1", context["k1"] as? String ?? "")
            return true
        }, expectedValue: true, errorMsg: test1)
        
        testRule.addAction { (rule, context) -> Bool in
            XCTAssertNotNil(context["k1"])
            XCTAssertEqual("v1", context["k1"] as? String ?? "")
            self.actionHelper1(rule: rule, context: context)
            return true
        }
        
        ruleEngine.addRule(rule: testRule)
        let res = ruleEngine.processRule(ruleName: 1, context: contextData)
        
        //verify
        XCTAssertEqual(1, action1CalledCount)
        XCTAssertTrue(res.0)
    }
}
