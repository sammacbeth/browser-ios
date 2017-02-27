//
//  ConversationalHistoryAPI.swift
//  Client
//
//  Created by Sahakyan on 12/8/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import Foundation
//import UIKit
import Storage
import Shared
import Alamofire


func md5_(string: String) -> String {
	var digest = [UInt8](count: Int(CC_MD5_DIGEST_LENGTH), repeatedValue: 0)
	if let data = string.dataUsingEncoding(NSUTF8StringEncoding) {
		CC_MD5(data.bytes, CC_LONG(data.length), &digest)
	}
	
	var digestHex = ""
	for index in 0..<Int(CC_MD5_DIGEST_LENGTH) {
		digestHex += String(format: "%02x", digest[index])
	}
	
	return digestHex
}

class ConversationalHistoryAPI {
	
	static let host = "https://hs.cliqz.com/"
	static let uniqueID: String = {
		if let ID = UIDevice().identifierForVendor {
			return md5_(ID.UUIDString)
		}
		return "000"
	}()

	class func pushHistoryItem(visit: SiteVisit) {
        Engine.sharedInstance.getBridge().publishEvent("history:add", args: [self.generateParamsForHistoryItem(visit.site.url, title: visit.site.title, visitedDate: visit.date)])
	}
	
	class func getHistory(callback: (NSDictionary) -> Void) {
        // this API should return something easy to use - e.g. list of DomainHistory entries
        Engine.sharedInstance.getHistory().getHistory()
        
		Alamofire.request(.GET, "\(self.host)/getHistory?uid=\(self.uniqueID)", parameters: nil, encoding: .URL, headers: nil).responseJSON { (response) in
			if response.result.isSuccess {
				if let result = response.result.value as? NSDictionary,
					domains = result.valueForKey("domains") as? NSDictionary {
					callback(domains)
				}
			} else {
				callback(NSDictionary())
				print("Get History is failed :((( --- \(response)")
			}
		}
	}

	class func pushAllHistory(history: Cursor<Site>?, completionHandler:(NSError?) -> Void) {
		if let sites = history {
			var historyResults = [[String: AnyObject]]()
			for site in sites {
				historyResults.append(self.generateParamsForHistoryItem((site?.url)!, title: (site?.title)!, visitedDate: (site?.latestVisit!.date)!))
			}
            Engine.sharedInstance.getBridge().publishEvent("history:add", args: [historyResults])
		}
	}

	class func pushURLAndQuery(url: String, query: String) {
        Engine.sharedInstance.getBridge().publishEvent("query:click", args: ["query": query, "url": url])
	}

	class func pushMetadata(metadata: [String: AnyObject], url: String) {
        Engine.sharedInstance.getBridge().publishEvent("core:url-meta", args: [])
	}

	private class func generateParamsForHistoryItem(url: String, title: String, visitedDate: MicrosecondTimestamp) -> [String: AnyObject] {
		return ["url": url,
		        "title": title,
			    "lastVisitDate": NSNumber(unsignedLongLong:visitedDate)]
	}

}
