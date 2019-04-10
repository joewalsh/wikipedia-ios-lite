
import UIKit

class UserTalkDiscussionViewController: UIViewController {

    var name: String!
    var type: UserTalkType!
    private var fetcher: UserTalkFetcher!
    private var discussions: [Discussion] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    
    @IBOutlet private var tableView: UITableView!
    private var cssStrings: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        title = name
        setupFetcher()
        
        fetchData()
    }
    
    private func setupFetcher() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let session = appDelegate.session
        let configuration = appDelegate.configuration
        fetcher = UserTalkFetcher(session: session, configuration: configuration)
    }
    
    func fetchData() {
        fetcher.fetchTalkPage(name: name) { [weak self] (error, data) in
            DispatchQueue.main.async {
                self?.discussions = data ?? []
            }
        }
        
        fetcher.fetchCSS(name: name) { [weak self](error, cssData) in
            
            if let cssData = cssData {
                for data in cssData {
                    if let string = String(data: data, encoding: String.Encoding.utf8) {
                        self?.cssStrings.append(string)
                    }
                }
            }
        }
    }
    
    @IBAction func tappedClose(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}

extension UserTalkDiscussionViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return discussions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard discussions.count > indexPath.row,
         let cell = tableView.dequeueReusableCell(withIdentifier: "DiscussionTableViewCell", for: indexPath) as? DiscussionTableViewCell else {
                return UITableViewCell()
        }
        
        let discussion = discussions[indexPath.row]
        
        cell.setTitle(htmlString: discussion.title)
        return cell
    }
}

extension UserTalkDiscussionViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard discussions.count > indexPath.row else {
            return
        }
        
        let discussion = discussions[indexPath.row]
        
        switch type! {
        case .webView:
            if let vc = UIStoryboard(name: "UserTalk", bundle: nil).instantiateViewController(withIdentifier: "UserTalkWebViewViewController") as? UserTalkThreadWebViewController {
                vc.discussion = discussion
                vc.cssStrings = cssStrings
                navigationController?.pushViewController(vc, animated: true)
            }
        case .webViewList:
            if let vc = UIStoryboard(name: "UserTalk", bundle: nil).instantiateViewController(withIdentifier: "UserTalkWebViewListViewController") as? UserTalkThreadWebListViewController {
                vc.discussion = discussion
                vc.cssStrings = cssStrings
                navigationController?.pushViewController(vc, animated: true)
            }
        case .list:
            if let vc = UIStoryboard(name: "UserTalk", bundle: nil).instantiateViewController(withIdentifier: "UserTalkListViewController") as? UserTalkThreadListViewController {
                vc.discussion = discussion
                navigationController?.pushViewController(vc, animated: true)
            }
            
        default: return
        }
    }
}
