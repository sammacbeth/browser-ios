//
//  ConversationalHistory.swift
//  Client
//
//  Created by Sahakyan on 12/8/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import Foundation
import SnapKit
import Alamofire

class ConversationalHistory: UIViewController, UITableViewDataSource, UITableViewDelegate {
	
	var historyTableView: UITableView!
	let historyCellID = "HistoryCell"

	var domainsHistory: NSDictionary!
	var sortedKeys: [String] = [String]()

//	var backButton: UIButton! {
//		didSet {
//			backButton.addTarget(self, action: #selector(goBack), forControlEvents: .TouchUpInside)
//		}
//	}
	
	weak var delegate: BrowserNavigationDelegate?

	override func viewDidLoad() {
		super.viewDidLoad()
		self.historyTableView = UITableView(frame: CGRectZero, style: .Plain)
		self.view.addSubview(self.historyTableView)
		self.historyTableView.snp_makeConstraints { (make) in
			make.top.left.right.bottom.equalTo(self.view)
		}
		self.historyTableView.delegate = self
		self.historyTableView.dataSource = self
		self.historyTableView.registerClass(HistoryCell.self, forCellReuseIdentifier: historyCellID)
		self.historyTableView.tableFooterView = UIView()
		self.historyTableView.separatorStyle = .SingleLine
		self.historyTableView.separatorColor = UIColor.lightGrayColor()
//		self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "cliqzBack"), style: .Plain, target: self, action: #selector(goBack))
//		self.backButton.hidden = true
	}

//	@objc func goBack(sender: UIButton) {
//		self.navigationController?.popViewControllerAnimated(false)
//	}

	override func viewWillDisappear(animated: Bool) {
		self.navigationController?.navigationBarHidden = true
		super.viewWillDisappear(animated)
	}

	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		
		self.navigationController?.navigationBarHidden = true
//		self.backButton.hidden = true
		self.loadData()
	}

	func loadData() {
		ConversationalHistoryAPI.getHistory { (data) in
			self.domainsHistory = data.valueForKey("domains") as? NSDictionary
			self.sortedKeys = self.domainsHistory.keysSortedByValueUsingComparator({ (a, b) -> NSComparisonResult in
				if let x = a as? [String: AnyObject],
					y = b as? [String: AnyObject] {
					if (x["lastVisitedAt"] as! NSNumber).doubleValue > (y["lastVisitedAt"] as! NSNumber).doubleValue {
						return NSComparisonResult.OrderedAscending
					} else {
						return NSComparisonResult.OrderedDescending
					}
				}
				return NSComparisonResult.OrderedSame
			}) as! [String]
            self.historyTableView.reloadData()
		}
	}

	func loadDummyData() {
		if let path = NSBundle.mainBundle().pathForResource("getHistory", ofType: "js") {
			do {
				let data = try NSData(contentsOfURL: NSURL(fileURLWithPath: path), options: NSDataReadingOptions.DataReadingMappedIfSafe)
				let jsonObj = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers) as! NSDictionary
				self.domainsHistory = jsonObj.valueForKey("domains") as? NSDictionary
			} catch let error as NSError {
				print(error.localizedDescription)
			}
			
		}
	}

	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if let data = self.domainsHistory {
			return data.allKeys.count
		}
		return 0
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
			let cell =  self.historyTableView.dequeueReusableCellWithIdentifier(self.historyCellID) as! HistoryCell
		let key = self.sortedKeys[indexPath.row]
		let value = self.domainsHistory.valueForKey(key) as! NSDictionary
		cell.URLLabel.text = key
		if let timeinterval = value.valueForKey("lastVisitedAt") as? NSNumber {
			let x = NSDate(timeIntervalSince1970: timeinterval.doubleValue)
			cell.titleLabel.text = x.toRelativeTimeString()
		}
		cell.tag = indexPath.row
//		cell.logoImageView.image = UIImage(named: "coolLogo")
		LogoLoader.loadLogoImageOrFakeLogo(key, completed: { (image, fakeLogo, error) in
			if cell.tag == indexPath.row {
				if image != nil {
					cell.logoImageView.image = image
				} else {
					cell.logoImageView.image = UIImage(named: "coolLogo")
				}
			}
		})

//		cell.logoImageView.loadLogo(forDomain: key) { (view) in
//			if view != nil {
//				cell.logoImageView.image = UIImage(named: "coolLogo")
//			}
//		}
		cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
		cell.accessoryType = .DisclosureIndicator
		cell.selectionStyle = .None
		return cell
	}
	
	func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
		return 70
	}

	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		let key = self.sortedKeys[indexPath.row]
		let value = self.domainsHistory.valueForKey(key) as! NSDictionary
		let details = value
		let vc = ConversationalHistoryDetails()
		vc.detaildHistory = details
		vc.delegate = self.delegate
		self.navigationController?.pushViewController(vc, animated: false)
//		self.backButton.hidden = false
	}
	
	@objc private func goBack() {
		self.navigationController?.popViewControllerAnimated(false)
	}

}

class HistoryCell: UITableViewCell {
	let titleLabel = UILabel()
	let URLLabel = UILabel()
	let logoImageView = UIImageView()

	override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		self.contentView.addSubview(titleLabel)
		titleLabel.font = UIFont.systemFontOfSize(14, weight: UIFontWeightMedium)
		titleLabel.textColor = UIColor.lightGrayColor()
		titleLabel.backgroundColor = UIColor.clearColor()
		titleLabel.textAlignment = .Left
		self.contentView.addSubview(URLLabel)
		URLLabel.font = UIFont.systemFontOfSize(18, weight: UIFontWeightMedium)
		URLLabel.textColor = UIColor.blackColor() //UIColor(rgb: 0x77ABE6)
		URLLabel.backgroundColor = UIColor.clearColor()
		URLLabel.textAlignment = .Left
		self.contentView.addSubview(logoImageView)
		logoImageView.layer.cornerRadius = 20
		logoImageView.clipsToBounds = true
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func layoutSubviews() {
		super.layoutSubviews()
		self.logoImageView.snp_remakeConstraints { (make) in
			make.left.equalTo(self.contentView).offset(10)
			make.centerY.equalTo(self.contentView)
			make.width.equalTo(40)
			make.height.equalTo(40)
		}
		self.URLLabel.snp_remakeConstraints { (make) in
			make.top.equalTo(self.contentView).offset(15)
			make.left.equalTo(self.logoImageView.snp_right).offset(15)
			make.height.equalTo(20)
			make.right.equalTo(self.contentView).offset(40)
		}
		self.titleLabel.snp_remakeConstraints { (make) in
			make.top.equalTo(self.URLLabel.snp_bottom).offset(5)
			make.left.equalTo(self.URLLabel.snp_left)
			make.height.equalTo(20)
			make.right.equalTo(self.contentView).offset(40)
		}
	}
	
}
