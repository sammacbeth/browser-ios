//
//  QuerySuggestionView.swift
//  Client
//
//  Created by Mahmoud Adam on 1/2/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import UIKit
protocol QuerySuggestionDelegate : class {
    func autoComplete(suggestion: String)
}

class QuerySuggestionView: UIView {
    //MARK:- Constants
    private let kViewHeight: CGFloat = 44
    private let scrollView = UIScrollView()
    private let boldFontAttributes = [NSFontAttributeName: UIFont.boldSystemFontOfSize(17), NSForegroundColorAttributeName: UIColor.whiteColor()]
    private let normalFontAttributes = [NSFontAttributeName: UIFont.systemFontOfSize(16), NSForegroundColorAttributeName: UIColor.whiteColor()]
    private let bgColor = UIColor(rgb: 0xADB5BD)
    private let separatorBgColor = UIColor(rgb: 0xC7CBD3)
    private let margin: CGFloat = 10
    
    //MARK:- instance variables
    weak var delegate : QuerySuggestionDelegate? = nil
    private var currentText: String?
    
    
    init() {
        let applicationFrame = UIScreen.mainScreen().applicationFrame
        let frame = CGRectMake(0.0, 0.0, CGRectGetWidth(applicationFrame), kViewHeight);
        
        super.init(frame: frame)
        self.autoresizingMask = .FlexibleWidth
        self.backgroundColor = bgColor
        
        scrollView.frame = frame
        self.addSubview(self.scrollView)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector:  #selector(QuerySuggestionView.viewRotated), name: UIDeviceOrientationDidChangeNotification, object: nil)
        
        if !QuerySuggestions.isEnabled() {
            self.hidden = true
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func didEnterText(text: String) {
        guard QuerySuggestions.isEnabled() else {
            self.hidden = true
            return
        }
        currentText = text
        guard !text.isEmpty else {
            clearSuggestions()
            return
        }

        QuerySuggestions.getSuggestions(text) { [weak self] responseData in
            self?.processSuggestionsResponse(text, responseData: responseData)
        }
        
    }
    
    //MARK:- Helper methods
    
    private func processSuggestionsResponse(query: String, responseData: AnyObject) {
        let suggestionsResponse = responseData as! [String: AnyObject]
        let suggestions = suggestionsResponse["suggestions"] as! [String]
        dispatch_async(dispatch_get_main_queue(), {[weak self] in
            if query == self?.currentText {
                self?.clearSuggestions()
                self?.showSuggestions(suggestions)
            }
        })
    }
    
    
    private func clearSuggestions() {
        let subViews = scrollView.subviews
        for subView in subViews {
            subView.removeFromSuperview()
        }
    }
    
    private func showSuggestions(suggestions: [String]) {
        
        var index = 0
        var x: CGFloat = margin
        var difference:CGFloat = 0
        var offset:CGFloat = 0
        var displayedSuggestions = [(String, CGFloat)]()
        
        // Calcuate extra space after the last suggesion
        for suggestion in suggestions {
            let suggestionWidth = getWidth(suggestion)
            // show Max 3 suggestions which does not exceed screen width
            if x + suggestionWidth > self.frame.width || index > 2 {
                break;
            }
            // increment step
            x = x + suggestionWidth + 2*margin + 1
            index = index + 1
            displayedSuggestions.append((suggestion, suggestionWidth))
        }
        
        // distribute the extra space evenly on all suggestions
        difference = self.frame.width - x
        offset = round(difference/CGFloat(index))
        
        // draw the suggestions inside the view
        x = margin
        index = 0
        for (suggestion, width) in displayedSuggestions {
            let suggestionWidth = width + offset
            // Adding vertical separator between suggestions
            if index > 0 {
                let verticalSeparator = createVerticalSeparator(x)
                scrollView.addSubview(verticalSeparator)
            }
            // Adding the suggestion button
            let suggestionButton = createSuggestionButton(x, suggestion: suggestion, suggestionWidth: suggestionWidth)
            scrollView.addSubview(suggestionButton)
            
            // increment step
            x = x + suggestionWidth + 2*margin + 1
            index = index + 1
        }
    }
    
    private func getWidth(suggestion: String) -> CGFloat {
        let sizeOfString = (suggestion as NSString).sizeWithAttributes(boldFontAttributes)
        return sizeOfString.width
    }

    private func createVerticalSeparator(x: CGFloat) -> UIView {
        let verticalSeparator = UIView()
        verticalSeparator.frame = CGRectMake(x-11, 0, 1, kViewHeight)
        verticalSeparator.backgroundColor = separatorBgColor
        return verticalSeparator;
    }
    
    private func createSuggestionButton(x: CGFloat, suggestion: String, suggestionWidth: CGFloat) -> UIButton {
        let button = UIButton(type: .Custom)
        let suggestionTitle = getTitle(suggestion)
        button.setAttributedTitle(suggestionTitle, forState: .Normal)
        button.frame = CGRectMake(x, 0, suggestionWidth, kViewHeight)
        button.addTarget(self, action: #selector(selectSuggestion(_:)), forControlEvents: .TouchUpInside)
        return button
    }
    
    private func getTitle(suggestion: String) -> NSAttributedString {
        guard let prefix = currentText else {
            return NSMutableAttributedString()
        }
        var title: NSMutableAttributedString!
        
        if let range = suggestion.rangeOfString(prefix) where range.startIndex == suggestion.startIndex {
            title = NSMutableAttributedString(string:prefix, attributes:normalFontAttributes)
            var suffix = suggestion
            suffix.replaceRange(range, with: "")
            title.appendAttributedString(NSAttributedString(string: suffix, attributes:boldFontAttributes))
            
        } else {
            title = NSMutableAttributedString(string:suggestion, attributes:boldFontAttributes)
        }
        return title
    }
    
    @objc private func selectSuggestion(button: UIButton) {
        
        guard let suggestion = button.titleLabel?.text else {
            return
        }
        delegate?.autoComplete(suggestion + " ")
    }
    
    @objc private func viewRotated() {
        guard QuerySuggestions.isEnabled() else {
            self.hidden = true
            return
        }
        
        if UIDeviceOrientationIsLandscape(UIDevice.currentDevice().orientation) {
            self.hidden = true
        } else if UIDeviceOrientationIsPortrait(UIDevice.currentDevice().orientation) {
            self.hidden = false
        }
        
    }
}