//  Created by Axel Ancona Esselmann on 5/20/24.
//

import Foundation

extension Substring {

    enum Error: Swift.Error {
        case invalidIndex
        case notFond
    }

    func advance(until character: Character, index: inout String.Index) throws {
        guard index < endIndex else {
            throw Error.invalidIndex
        }
        guard let foundIndex = self[index..<endIndex].firstIndex(of: character) else {
            throw Error.notFond
        }
        let newIndex = self.index(after: foundIndex)
        index = newIndex
    }

    func containsWhitespace(in range: Range<String.Index>) -> Bool {
        if
            self[range]
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .isEmpty
        {
            return true
        } else {
            return false
        }
    }
}
