//
//  UserTalkThreadWebViewController.swift
//  lite
//
//  Created by Toni Sevener on 4/8/19.
//  Copyright © 2019 Wikimedia Foundation. All rights reserved.
//

import UIKit
import WebKit

class UserTalkThreadWebViewController: UIViewController {
    
    var discussion: Discussion! {
        didSet {
            let textItems = discussion.textItems
            print(textItems)
        }
    }
    var cssStrings: [String] = []
    
    lazy var webView: WKWebView = {
        let webView = WKWebView(frame: .zero)
        return webView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addConstrainedSubview(webView)
        var html = "<html><head>"
        for string in cssStrings {
            html += "<style>\(string)</style>"
         }
        html += "<meta name=\"viewport\" content=\"initial-scale=1.0, user-scalable=yes, minimum-scale=0.25, maximum-scale=5.0, width=device-width\"/>"
        html += "</head>"
        html += "<body>\(discussion.text)</body>"
        html += "</html>"
        
        let baseUrl = URL(string: "\(Configuration.Scheme.https)://\(Configuration.Domain.englishWikipedia)")
        webView.loadHTMLString(html, baseURL: baseUrl)
    }
}
