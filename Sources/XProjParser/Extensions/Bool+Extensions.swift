//  Created by Axel Ancona Esselmann on 5/20/24.
//

import Foundation

extension Bool {
    init?(verbose stringValue: any StringProtocol) {
        switch String(stringValue) {
        case "YES": self = true
        case "NO":  self = false
        default: return nil
        }
    }
}
