//
//  UserTalkThreadWebListViewController.swift
//  lite
//
//  Created by Toni Sevener on 4/9/19.
//  Copyright © 2019 Wikimedia Foundation. All rights reserved.
//

import UIKit

class UserTalkThreadWebListViewController: UIViewController {
    
    var discussion: Discussion! {
        didSet {
            textItems = discussion.textItems
        }
    }
    var textItems: [String] = [] {
        didSet {
            tableView?.reloadData()
        }
    }
    var cssStrings: [String] = []

    @IBOutlet var tableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

}

extension UserTalkThreadWebListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return textItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.row < textItems.count,
            let cell = tableView.dequeueReusableCell(withIdentifier: "ThreadWebListTableViewCell", for: indexPath) as? ThreadWebListTableViewCell else {
                return UITableViewCell()
        }
        
        cell.discussionItem = textItems[indexPath.row]
        cell.cssStrings = cssStrings
        
        return cell
    }
}

extension UserTalkThreadWebListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 200
    }
}
