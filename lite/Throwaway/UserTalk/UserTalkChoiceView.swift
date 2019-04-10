
import UIKit

enum UserTalkType: Int {
    case webView
    case webViewList
    case list
}

protocol UserTalkChoiceDelegate: class {
    func userTalkChoiceDidTapButton(_ userTalkChoice: UserTalkChoiceView, name: String, type: UserTalkType)
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
    
    @IBAction func tappedButton(_ sender: UIButton) {
        if let name = textField.text,
            let type = UserTalkType(rawValue: sender.tag) {
            delegate?.userTalkChoiceDidTapButton(self, name: name, type: type)
        }
    }
}

extension UserTalkChoiceView: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        endEditing(true)
        return true
    }
}
