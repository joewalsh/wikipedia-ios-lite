
import UIKit

enum UserTalkType {
    case webView
    case webViewList
    case list
}

protocol UserTalkChoiceDelegate: class {
    func userTalkChoiceDidTapWebViewList(_ userTalkChoice: UserTalkChoiceView, name: String, type: UserTalkType)
}

class UserTalkChoiceView: UIView, Nibbed {

    @IBOutlet var textField: UITextField!
    @IBOutlet var buttons: [UIButton]!
    weak var delegate: UserTalkChoiceDelegate?
    
    @IBAction func textFieldChanged(_ sender: Any) {
        for button in buttons {
            button.isEnabled = (textField.text?.count ?? 0) > 0
        }
    }
    
    @IBAction func tappedWebView(_ sender: Any) {
        if let name = textField.text {
            delegate?.userTalkChoiceDidTapWebViewList(self, name: name, type: .webView)
        }
    }
}

extension UserTalkChoiceView: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        endEditing(true)
        return true
    }
}
