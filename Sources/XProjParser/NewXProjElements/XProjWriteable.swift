//  Created by Axel Ancona Esselmann on 5/29/24.
//

import Foundation

protocol XProjWriteable {
    func asString(_ indentCount: Int) throws -> String
}
