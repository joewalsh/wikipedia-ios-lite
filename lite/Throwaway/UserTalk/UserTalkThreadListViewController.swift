//
//  UserTalkThreadListViewController.swift
//  lite
//
//  Created by Toni Sevener on 4/9/19.
//  Copyright © 2019 Wikimedia Foundation. All rights reserved.
//

import UIKit

class UserTalkThreadListViewController: UIViewController {

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
    
    @IBOutlet var tableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension UserTalkThreadListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return textItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.row < textItems.count,
            let cell = tableView.dequeueReusableCell(withIdentifier: "ThreadListTableViewCell", for: indexPath) as? ThreadListTableViewCell else {
                return UITableViewCell()
        }
        
        cell.discussionItem = textItems[indexPath.row]
        
        return cell
    }
}
