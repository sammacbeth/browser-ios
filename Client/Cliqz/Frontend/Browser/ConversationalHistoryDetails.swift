//
//  ConversationalHistoryDetails.swift
//  Client
//
//  Created by Sahakyan on 12/8/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

class ConversationalHistoryDetails: UIViewController, UITableViewDataSource, UITableViewDelegate {
	
	var historyTableView: UITableView!
	let historyCellID = "HistoryCell"
	var sortedURLs = [String]()

	weak var delegate: BrowserNavigationDelegate?

	var detaildHistory: NSDictionary! {
		didSet {
			if let d = detaildHistory.valueForKey("visits") as? NSDictionary {
				 self.sortedURLs = d.keysSortedByValueUsingComparator({ (a, b) -> NSComparisonResult in
					if let x = a as? [String: AnyObject],
							y = b as? [String: AnyObject] {
						if let sort1 = x["lastVisitedAt"] as? NSNumber,
							sort2 = y["lastVisitedAt"] as? NSNumber {
							if sort1.doubleValue > sort2.doubleValue {
								return NSComparisonResult.OrderedAscending
							}
							return NSComparisonResult.OrderedDescending
						}
					}
					return NSComparisonResult.OrderedSame
				}) as! [String]
			}
			self.urls = detaildHistory.valueForKey("visits") as? NSArray
		}
	}
	
	private var urls: NSArray!

	override func viewDidLoad() {
		super.viewDidLoad()
		self.historyTableView = UITableView(frame: CGRectZero, style: .Plain)
		self.view.addSubview(self.historyTableView)
		self.historyTableView.snp_makeConstraints { (make) in
			make.top.left.right.bottom.equalTo(self.view)
		}
		self.historyTableView.delegate = self
		self.historyTableView.dataSource = self
		self.historyTableView.registerClass(HistoryDetailCell.self, forCellReuseIdentifier: historyCellID)
		self.historyTableView.separatorStyle = .None

//		self.historyTableView.tableFooterView = UIView()


	}

	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		self.navigationController?.navigationBarHidden = true
	}

	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if let data = self.urls {
			return data.count
		}
		return 0
	}

	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell =  self.historyTableView.dequeueReusableCellWithIdentifier(self.historyCellID) as! HistoryDetailCell
//		let key = self.sortedURLs[indexPath.row]
		let value = self.urls[indexPath.row] as! NSDictionary
		cell.URLLabel.text = value.valueForKey("url") as? String
		if let timeinterval = value.valueForKey("lastVisitedAt") as? NSNumber {
			let x = NSDate(timeIntervalSince1970: timeinterval.doubleValue / 1000)
			cell.timeLabel.text = x.toRelativeTimeString()
		}
		if let title = value.valueForKey("title") as? String {
			cell.titleLabel.text = title
		}
		cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
		cell.selectionStyle = .None

		return cell
	}
	
	func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
		return 120
	}
	
	func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		return 65
	}
	
	func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		let header = UIView()
		header.backgroundColor = UIColor.whiteColor()
		let backBtn = UIButton(type: .Custom)
		backBtn.tintColor = UIColor.blueColor()
		backBtn.setImage(UIImage(named:"cliqzBack"), forState: .Normal)
		header.addSubview(backBtn)
		backBtn.addTarget(self, action: #selector(goBack), forControlEvents: .TouchUpInside)
		backBtn.snp_makeConstraints { (make) in
			make.top.equalTo(header)
			make.left.equalTo(header).offset(5)
		}
		let title = UILabel()
		title.textAlignment = .Center
		title.numberOfLines = 0
		title.font = UIFont.boldSystemFontOfSize(10)
		header.addSubview(title)
		let logo = UIButton(type: .Custom)
		logo.layer.cornerRadius = 15
		logo.clipsToBounds = true
		header.addSubview(logo)
		logo.snp_remakeConstraints { (make) in
			make.centerX.equalTo(header)
			make.top.equalTo(header).offset(6)
			make.width.equalTo(30)
			make.height.equalTo(30)
		}
		logo.addTarget(self, action: #selector(logoPressed), forControlEvents: .TouchUpInside)
//		logo.image = UIImage(named: "coolLogo")
		if let url = self.detaildHistory.objectForKey("baseUrl") as? String {
			LogoLoader.loadLogoImageOrFakeLogo(url, completed: { (image, fakeLogo, error) in
				if image != nil {
					logo.setImage(image, forState: .Normal)
				} else {
					logo.setImage(UIImage(named: "coolLogo"), forState: .Normal)
				}
			})
		} else {
			logo.setImage(UIImage(named: "coolLogo"), forState: .Normal)
		}

		title.snp_remakeConstraints { (make) in
			make.top.equalTo(logo.snp_bottom)
			make.left.right.equalTo(header)
			make.height.equalTo(20)
		}
		if let baseURL = self.detaildHistory.valueForKey("baseUrl") as? String { //,titleTxt = snippet.valueForKey("title") as? String {
			title.text = baseURL
		}
		let sep = UIView()
		sep.backgroundColor = UIColor.lightGrayColor()
		header.addSubview(sep)
		sep.snp_remakeConstraints { (make) in
			make.bottom.equalTo(header).offset(-5)
			make.left.right.equalTo(header)
			make.height.equalTo(1)
		}

		return header
	}

	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		let key = self.urls[indexPath.row]
		if let urlString = key.objectForKey("url") as? String, let url = NSURL(string: urlString) {
			self.navigationController?.popViewControllerAnimated(false)
			self.delegate?.navigateToURL(url)
		}
	}
	
	@objc private func goBack() {
		self.navigationController?.popViewControllerAnimated(false)
	}
	
	@objc private func logoPressed() {
		if let baseURL = self.detaildHistory.valueForKey("baseUrl") as? String, let url = NSURL(string: baseURL)  {			self.navigationController?.popViewControllerAnimated(false)
			self.delegate?.navigateToURL(url)
		}

	}
}

class HistoryDetailCell: UITableViewCell {
	let titleLabel = UILabel()
	let descriptionLabel = UILabel()
	let URLLabel = UILabel()
	let timeLabel = UILabel()
	let borderView = UIView()

	override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
	
		self.contentView.addSubview(self.borderView)
		self.borderView.backgroundColor = UIColor.clearColor()
		self.borderView.layer.borderColor = UIColor(colorLiteralRed: 0.9, green: 0.9, blue: 0.9, alpha: 1).CGColor
		self.borderView.layer.cornerRadius = 2
		self.borderView.layer.borderWidth = 1

		self.contentView.addSubview(titleLabel)
		titleLabel.numberOfLines = 2
		titleLabel.font = UIFont.systemFontOfSize(14, weight: UIFontWeightMedium)
		titleLabel.textColor = UIColor.blackColor()
		titleLabel.backgroundColor = UIColor.clearColor()
		self.contentView.addSubview(URLLabel)
		descriptionLabel.font = UIFont.systemFontOfSize(14)
		descriptionLabel.numberOfLines = 0
		descriptionLabel.backgroundColor = UIColor.clearColor()
		self.contentView.addSubview(descriptionLabel)

		URLLabel.font = UIFont.systemFontOfSize(12, weight: UIFontWeightMedium)
		URLLabel.textColor = UIColor.lightGrayColor() //UIColor(rgb: 0x77ABE6)
		URLLabel.numberOfLines = 2
		URLLabel.backgroundColor = UIColor.clearColor()
		URLLabel.textAlignment = .Left
		timeLabel.font = UIFont.systemFontOfSize(12)
		timeLabel.textAlignment = .Right
		timeLabel.textColor = UIConstants.CliqzThemeColor
		self.contentView.addSubview(timeLabel)
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func layoutSubviews() {
		self.borderView.snp_makeConstraints { (make) in
			make.top.equalTo(self.contentView).offset(4)
			make.bottom.equalTo(self.contentView).offset(-4)
			make.left.equalTo(self.contentView).offset(8)
			make.right.equalTo(self.contentView).offset(-8)
		}
		self.titleLabel.snp_remakeConstraints { (make) in
			make.top.equalTo(self.contentView).offset(10)
			make.left.equalTo(self.contentView).offset(14)
			make.height.equalTo(35)
			make.right.equalTo(self.contentView).offset(-14)
		}
		self.descriptionLabel.snp_makeConstraints { (make) in
			make.right.equalTo(self.contentView).offset(-14)
			make.left.equalTo(self.contentView).offset(14)
			make.top.equalTo(self.titleLabel.snp_bottom)
			make.height.equalTo(50)
		}
		self.URLLabel.snp_remakeConstraints { (make) in
			make.top.equalTo(self.titleLabel.snp_bottom).offset(10)
			make.left.equalTo(self.contentView).offset(14)
			make.height.equalTo(25)
			make.right.equalTo(self.contentView).offset(-14)
		}
		self.timeLabel.snp_makeConstraints { (make) in
			make.right.equalTo(self.contentView).offset(-15)
			make.bottom.equalTo(self.contentView).offset(-10)
			make.height.equalTo(12)
			make.left.equalTo(self.contentView)
		}

	}
	
}
