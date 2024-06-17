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

extension StringProtocol {
    func trimmingQuotes() -> String {
        if self.hasPrefix("\""), self.hasSuffix("\"") {
            return String(self.dropFirst(1).dropLast(1))
        } else {
            return String(self)
        }
    }
}
