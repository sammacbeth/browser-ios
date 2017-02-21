//
//  WebRequest.swift
//  Client
//
//  Created by Sam Macbeth on 21/02/2017.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import Foundation
import React

@objc(WebRequest)
public class WebRequest : RCTEventEmitter {
    
    var tabs = NSMapTable.strongToWeakObjectsMapTable()
    var requestSerial = 0
    var blockingResponses = [Int: NSDictionary]()
    var lockSemaphore: dispatch_semaphore_t = dispatch_semaphore_create(0)
    var ready = false
    
    public override init() {
        super.init()
    }
    
    public override static func moduleName() -> String! {
        return "WebRequest"
    }
    
    override public func supportedEvents() -> [String]! {
        return ["webRequest"]
    }
    
    func shouldBlockRequest(request: NSURLRequest) -> Bool {
        
        let requestInfo = getRequestInfo(request)
        if let blockResponse = getBlockResponseForRequest(requestInfo) where blockResponse.count > 0 {
            return true
        }
        
        return false
    }
    
    func newTabCreated(tabId: Int, webView: UIView) {
        tabs.setObject(webView, forKey: NSNumber(integer: tabId))
    }
    
    @objc(isWindowActive:resolve:reject:)
    func isWindowActive(tabId: NSNumber, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) -> Void {
        let active = isTabActive(tabId.integerValue)
        resolve(active)
    }
    
    
    //MARK: - Private Methods
    private func isTabActive(tabId: Int) -> Bool {
        return tabs.objectForKey(tabId) != nil
    }
    
    public func getBlockResponseForRequest(requestInfo: [String: AnyObject]) -> NSDictionary? {
        let requestId = requestInfo["id"] as! Int
        let eventSubmitAt = NSDate()
        
        // event listener not yet ready
        if !self.ready {
            return NSDictionary()
        }
        
        self.sendEventWithName("webRequest", body: requestInfo)
        
        while self.blockingResponses[requestId] == nil {
            dispatch_semaphore_wait(lockSemaphore, dispatch_time(DISPATCH_TIME_NOW, 100 * 1000 * 1000))
        }
        
        let response = self.blockingResponses[requestId]
        self.blockingResponses[requestId] = nil;
        return response

        
    }
    
    @objc(blockingResponseReply:response:)
    func blockingResponseReply(requestId: NSNumber, response: NSDictionary) {
        self.blockingResponses[requestId as Int] = response
        dispatch_semaphore_signal(lockSemaphore)
    }
    
    @objc(onReady)
    func onReady() {
        self.ready = true
    }
    
    private func getRequestInfo(request: NSURLRequest) -> [String: AnyObject] {
        let requestId = requestSerial;
        requestSerial += 1;
        let url = request.URL?.absoluteString
        let userAgent = request.allHTTPHeaderFields?["User-Agent"]
        
        let isMainDocument = request.URL == request.mainDocumentURL
        let tabId = getTabId(userAgent)
        let isPrivate = false
        let originUrl = request.mainDocumentURL?.absoluteString
        
        var requestInfo = [String: AnyObject]()
        requestInfo["id"] = requestId
        requestInfo["url"] = url
        requestInfo["method"] = request.HTTPMethod
        requestInfo["tabId"] = tabId ?? -1
        requestInfo["parentFrameId"] = -1
        // TODO: frameId how to calculate
        requestInfo["frameId"] = tabId ?? -1
        requestInfo["isPrivate"] = isPrivate
        requestInfo["originUrl"] = originUrl
        let contentPolicyType = ContentPolicyDetector.sharedInstance.getContentPolicy(request, isMainDocument: isMainDocument)
        requestInfo["type"] = contentPolicyType;
        requestInfo["source"] = originUrl;
        
        requestInfo["requestHeaders"] = request.allHTTPHeaderFields
        return requestInfo
    }
    
    public class func generateUniqueUserAgent(baseUserAgent: String, tabId: Int) -> String {
        let uniqueUserAgent = baseUserAgent + String(format:" _id/%06d", tabId)
        return uniqueUserAgent
    }
    
    private func getTabId(userAgent: String?) -> Int? {
        guard let userAgent = userAgent else { return nil }
        guard let loc = userAgent.rangeOfString("_id/") else {
            // the first created webview doesn't have the id, because at this point there is no way to get the user agent automatically
            return 1
        }
        let tabIdString = userAgent.substringWithRange(loc.endIndex..<loc.endIndex.advancedBy(6))
        guard let tabId = Int(tabIdString) else { return nil }
        return tabId
    }
    
    private func toJSONString(anyObject: AnyObject) -> String? {
        do {
            if NSJSONSerialization.isValidJSONObject(anyObject) {
                let jsonData = try NSJSONSerialization.dataWithJSONObject(anyObject, options: NSJSONWritingOptions(rawValue: 0))
                let jsonString = String(data:jsonData, encoding: NSUTF8StringEncoding)!
                return jsonString
            } else {
                print("[toJSONString] the following object is not valid JSON: \(anyObject)")
            }
        } catch let error as NSError {
            print("[toJSONString] JSON conversion of: \(anyObject) \n failed with error: \(error)")
        }
        return nil
    }
    
}
