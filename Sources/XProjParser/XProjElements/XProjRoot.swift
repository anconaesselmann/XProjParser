//  Created by Axel Ancona Esselmann on 5/20/24.
//

import Foundation

public struct XProjRoot: Ranged {
    public let elements: [Ranged]
    public var range: Range<String.Index>
}

public extension XProjRoot {

    enum Error: Swift.Error {
        case missingProperty
    }

    var objects: [XProjObject] {
        (elements.lazy
            .compactMap { $0 as? XProjProperty }
            .first { $0.key == "objects"}?.value as? XProjObject)?
            .elements
            .lazy
            .compactMap { $0 as? XProjProperty }
            .compactMap { $0.value as? XProjObject } ?? []
    }

    func element(withId id: XProjId) throws -> XProjObject {
        guard let element = objects
            .first(where: { $0.key == id.stringValue} )
        else {
            throw Error.missingProperty
        }
        return element
    }

    func elements(withIsa isa: XProjIsa) -> [XProjObject] {
        objects.filter { $0.isa == isa }
    }

    func sectionComments(withIsa isa: XProjIsa) -> [XProjSectionComment] {
        (elements
            .compactMap { $0 as? XProjProperty }
            .first { $0.key == "objects"}?.value as? XProjObject)?
            .elements
            .compactMap { $0 as? XProjSectionComment }
            .filter { $0.isa.rawValue == isa.rawValue } ?? []
    }

    func sectionRanges(for isa: XProjIsa) throws -> (outer: Range<String.Index>, inner: Range<String.Index>) {
        let sectionComments = self.sectionComments(withIsa: isa)
        guard sectionComments.count == 2 else {
            throw XProjRootError.invalidSectionComments
        }
        let beginRange = sectionComments[0].range
        let endRange = sectionComments[1].range
        return (
            outer: beginRange.lowerBound..<endRange.upperBound,
            inner: beginRange.upperBound..<endRange.lowerBound
        )
    }

    func firstElement(withIsa isa: XProjIsa) -> XProjObject? {
        objects.first { $0.isa == isa }
    }

    func firstElement(withIsa isa: XProjIsa, where predicate: (XProjProperty) -> Bool) -> XProjObject? {
        objects.lazy
            .filter { $0.isa == isa }
            .first { $0.properties.contains(where: predicate) }
    }

    func firstElement(
        withIsa isa: XProjIsa,
        key: String,
        value: String
    ) -> XProjObject? {
        objects.lazy
            .filter { $0.isa == isa }
            .first {
                if let anyString = $0.value(for: key, type: (any StringProtocol).self) {
                    String(anyString) == value
                } else {
                    false
                }
            }
    }

    func firstElement(
        withIsa isa: XProjIsa,
        key: String,
        value: XProjId
    ) -> XProjObject? {
        objects.lazy
            .filter { $0.isa == isa }
            .first {
                $0.value(for: key, type: XProjId.self)?.stringValue == value.stringValue
            }
    }
}

enum XProjRootError: Error {
    case missingTargetWithName(String)
    case missingBuildFile
    case missingProperty
    case invalidSectionComments
}

public extension String {
    mutating func removeSubranges(_ ranges: [Range<String.Index>]) {
        for range in ranges {
            print(self[range])
            removeSubrange(range)
        }
    }

    func removedSubranges(_ ranges: [Range<String.Index>]) -> Self {
        var copy = self
        for range in ranges {
            print(copy[range])
            copy.removeSubrange(range)
        }
        return copy
    }
}

public extension Array where Element == any Ranged {
    var ranges: [Range<String.Index>] {
        map { $0.range }
    }
}
