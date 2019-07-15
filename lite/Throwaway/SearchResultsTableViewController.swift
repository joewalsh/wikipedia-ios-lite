import UIKit

protocol SearchResultsTableViewControllerDelegate: AnyObject {
    func didSelect(searchResult page: Page)
}

class SearchResultsTableViewController: UITableViewController {
    weak var delegate: SearchResultsTableViewControllerDelegate?

    private let reuseIdentifier = "cell"

    var theme = Theme.standard

    var pages: [Page] = [] {
        didSet {
            tableView.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.separatorColor = tableView.backgroundColor
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: reuseIdentifier)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return pages.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
        let page = pages[indexPath.row]
        cell.textLabel?.text = page.title
        cell.textLabel?.textColor = theme.colors.link
        let selectedBackgroundView = UIView()
        selectedBackgroundView.backgroundColor = theme.colors.baseBackground
        cell.selectedBackgroundView = selectedBackgroundView
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        defer {
            tableView.deselectRow(at: indexPath, animated: true)
        }
        delegate?.didSelect(searchResult: pages[indexPath.row])
    }

}
