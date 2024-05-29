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
        guard upperBound <= content.endIndex else {
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
    func merged() -> [Range<String.Index>] {
        Set(self).sorted { $0.lowerBound > $1.lowerBound }
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
}

extension Range where Bound == String.Index {
    func enlarged(to larger: Self, if smaller: Self) -> Self {
        self == smaller ? larger : self
    }
}
