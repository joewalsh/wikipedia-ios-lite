//
//  ThreadWebListTableViewCell.swift
//  lite
//
//  Created by Toni Sevener on 4/9/19.
//  Copyright © 2019 Wikimedia Foundation. All rights reserved.
//

import UIKit
import WebKit

class ThreadWebListTableViewCell: UITableViewCell {
    
    var discussionItem: String = "" {
        didSet {
            var html = "<html><head>"
            for string in cssStrings {
                html += "<style>\(string)</style>"
            }
            html += "<meta name=\"viewport\" content=\"initial-scale=1.0, user-scalable=yes, minimum-scale=0.25, maximum-scale=5.0, width=device-width\"/>"
            html += "</head>"
            html += "<body>\(discussionItem)</body>"
            html += "</html>"
            
            let baseUrl = URL(string: "\(Configuration.Scheme.https)://\(Configuration.Domain.englishWikipedia)")
            webView.loadHTMLString(html, baseURL: baseUrl)
        }
    }
    var cssStrings: [String] = []
    
    lazy var webView: WKWebView = {
        let webView = WKWebView(frame: .zero)
        return webView
    }()

    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.addConstrainedSubview(webView)

    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
