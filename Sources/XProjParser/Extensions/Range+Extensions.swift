//  Created by Axel Ancona Esselmann on 5/20/24.
//

import Foundation

extension Range where Bound == String.Index {

    enum Error: Swift.Error {
        case invalidRange
    }

    func clipedBounds(for content: any StringProtocol) throws -> Self {
        guard lowerBound > content.startIndex else {
            throw Error.invalidRange
        }
        guard upperBound < content.endIndex else {
            throw Error.invalidRange
        }
        let start = content.index(after: lowerBound)
        let end = content.index(before: upperBound)
        guard start < end else {
            throw Error.invalidRange
        }
        return start..<end
    }
}

public extension Array where Element == Range<String.Index> {
    var merged: [Range<String.Index>] {
        self.sorted { $0.lowerBound > $1.lowerBound }
            .reduce(into: [Range<String.Index>]()) {
            guard var last = $0.last else {
                $0.append($1)
                return
            }
            if last.lowerBound == $1.upperBound {
                $0.popLast()
                $0.append($1.lowerBound..<last.upperBound)
            } else {
                $0.append($1)
            }
        }
    }

    func enlarged(to larger: Element, ifIncluded smaller: Element) -> Self {
        var copy = self
        for i in 0..<copy.count {
            var range = copy[i]
            if
                range.lowerBound == smaller.lowerBound,
                range.upperBound == smaller.upperBound
            {
                copy[i] = larger
                break
            }
        }
        return copy
    }
}
