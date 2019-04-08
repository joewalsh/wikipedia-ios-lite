//
//  UserTalkWebViewViewController.swift
//  lite
//
//  Created by Toni Sevener on 4/8/19.
//  Copyright © 2019 Wikimedia Foundation. All rights reserved.
//

import UIKit
import WebKit

class UserTalkWebViewViewController: UIViewController {
    
    var discussion: Discussion!
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
        html += "</head>"
        html += "<body>\(discussion.text)</body>"
        html += "</html>"
        
        //let url = URL(string: "http://localhost:6927") //this worked for images but not links
        
        //let url = URL(string: "https:") //this worked for images but not links
        //upload.wikimedia.org/wikipedia/commons/thumb/f/fd/Original_Barnstar_Hires.png/100px-Original_Barnstar_Hires.png)
        //https://upload.wikimedia.org/wikipedia/commons/thumb/f/fd/Original_Barnstar_Hires.png/100px-Original_Barnstar_Hires.png"
        
        //link embed example: source says /wiki/File:Original_Barnstar_Hires.png...needs to point to https://en.m.wikipedia.org/wiki/File:Original_Barnstar_Hires.png
        
        let baseUrl = URL(string: "https://en.m.wikipedia.org") //this works for both images and links
        webView.loadHTMLString(html, baseURL: baseUrl)
    }

}
