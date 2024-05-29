//  Created by Axel Ancona Esselmann on 5/29/24.
//

import Foundation

extension String {
    mutating func nl() {
        self += "\n"
    }
    mutating func indent(_ count: Int) {
        self += Array(repeating: "\t", count: count).joined()
    }
}
