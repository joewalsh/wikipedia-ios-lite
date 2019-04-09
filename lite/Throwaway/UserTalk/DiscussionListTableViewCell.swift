//
//  DiscussionListTableViewCell.swift
//  lite
//
//  Created by Toni Sevener on 4/9/19.
//  Copyright © 2019 Wikimedia Foundation. All rights reserved.
//

import UIKit

class DiscussionListTableViewCell: UITableViewCell {

    @IBOutlet private var titleTextView: UITextView!
    
    func setTitle(htmlString: String) {
        
        //todo: can't seem to pass in a baseUrl for links (it's a mac-only method). so links are trying to display locally.
        //either have API send us absolute links or we parse html for links and make them absolute here?
        //let htmlString = "<a href=\"https://en.wikipedia.org/wiki/Izzy_the_Frenchie\" title=\"Izzy the Frenchie\">Izzy the Frenchie</a>"
        //vs htmlString = "<a href=\"/wiki/Izzy_the_Frenchie\" title=\"Izzy the Frenchie\">Izzy the Frenchie</a>"
        
        let options = [NSAttributedString.DocumentReadingOptionKey.documentType:
            NSAttributedString.DocumentType.html]
        
        if let htmlData = NSString(string: htmlString).data(using: String.Encoding.unicode.rawValue),

        
        let attributedString = try? NSMutableAttributedString(data: htmlData,
                                                              options: options,
                                                              documentAttributes: nil) {
            titleTextView.attributedText = attributedString
            
        }
        
    }

}
