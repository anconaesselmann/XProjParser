//  Created by Axel Ancona Esselmann on 5/20/24.
//

import Foundation

extension Substring {

    enum Error: Swift.Error {
        case invalidIndex
        case notFond
        case containsNoneWhitespace
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

    func skipWhitespace(until character: Character, index currentIndex: inout String.Index) throws {
        var newIndex = currentIndex
        try advance(until: character, index: &newIndex)
        let indexBeforeFound = self.index(before: newIndex)
        guard newIndex < indexBeforeFound else {
            currentIndex = newIndex
            return
        }
        guard self.containsWhitespace(in: currentIndex..<indexBeforeFound) else {
            throw Error.containsNoneWhitespace
        }
        currentIndex = newIndex
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
