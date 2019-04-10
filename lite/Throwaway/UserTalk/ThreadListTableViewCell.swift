//
//  ThreadListTableViewCell.swift
//  lite
//
//  Created by Toni Sevener on 4/9/19.
//  Copyright © 2019 Wikimedia Foundation. All rights reserved.
//

import UIKit

class ThreadListTableViewCell: UITableViewCell {
    @IBOutlet var titleTextView: UITextView!
    
    var discussionItem: String = "" {
        didSet {
            let options = [NSAttributedString.DocumentReadingOptionKey.documentType:
                NSAttributedString.DocumentType.html]
            
            if let htmlData = NSString(string: discussionItem).data(using: String.Encoding.unicode.rawValue),
                
                
                let attributedString = try? NSMutableAttributedString(data: htmlData,
                                                                      options: options,
                                                                      documentAttributes: nil) {
                titleTextView.attributedText = attributedString
            }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
