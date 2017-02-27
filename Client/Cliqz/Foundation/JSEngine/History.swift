//
//  History.swift
//  Client
//
//  Created by Sam Macbeth on 27/02/2017.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import Foundation
import React


@objc(HistoryBridge)
public class HistoryBridge : NSObject {
    
    @objc(syncHistory:resolve:reject:)
    func syncHistory(fromIndex : NSInteger, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        
    }
    
    @objc(pushHistory:)
    func pushHistory(historyItems : NSDictionary) {
        
    }
    
    public func getHistory() {
        let response = Engine.sharedInstance.getBridge().callAction("getHistory", args: [])
        if let result = response["result"] as? NSDictionary {
            print(result)
        }
    }
    
}
