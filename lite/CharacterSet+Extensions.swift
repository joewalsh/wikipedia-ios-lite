import Foundation

extension CharacterSet {
    static let urlQueryAllowedWithoutPlus: CharacterSet = {
        var queryAllowedMinusPlus = CharacterSet.urlQueryAllowed
        queryAllowedMinusPlus.remove(charactersIn: "+")
        return queryAllowedMinusPlus
    }()
    
    static let urlPathComponentAllowed: CharacterSet = {
        var pathComponentAllowed = CharacterSet.urlPathAllowed
        pathComponentAllowed.remove(charactersIn: "/.")
        return pathComponentAllowed
    }()
    
    
}
