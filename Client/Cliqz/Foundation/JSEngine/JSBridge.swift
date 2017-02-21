//
//  JSBridge.swift
//  Client
//
//  Created by Sam Macbeth on 21/02/2017.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import Foundation
import React

@objc(JSBridge)
public class JSBridge : RCTEventEmitter {

    var registeredActions: Set<String> = []
    var actionCounter: Int = 0
    var replyCache = [Int: NSDictionary]()
    let lockSemaphore: dispatch_semaphore_t = dispatch_semaphore_create(0)
    
    public override init() {
        super.init()
    }
    
    public override static func moduleName() -> String! {
        return "JSBridge"
    }
    
    override public func supportedEvents() -> [String]! {
        return ["callAction"]
    }
    
    
    public func callAction(functionName: String, args: AnyObject) -> NSDictionary {
        // check listener is registered on other end
        guard self.registeredActions.contains(functionName) else {
            return ["error": "function not registered"]
        }
        
        actionCounter += 1
        let actionId = actionCounter
        
        // dispatch event
        self.sendEventWithName("callAction", body: ["id": actionId, "action": functionName, "args": args])
        
        // wait for response
        while self.replyCache[actionId] == nil {
            dispatch_semaphore_wait(self.lockSemaphore, DISPATCH_TIME_FOREVER)
        }
        
        let reply = self.replyCache[actionId]
        self.replyCache[actionId] = nil
        return reply!
    }
    
    @objc(replyToAction:response:)
    func replyToAction(actionId: Int, response: NSDictionary) {
        self.replyCache[actionId] = response
        dispatch_semaphore_signal(self.lockSemaphore)
    }
    
    @objc(registerAction:)
    func registerAction(actionName: String) {
        self.registeredActions.insert(actionName)
    }
    
}
