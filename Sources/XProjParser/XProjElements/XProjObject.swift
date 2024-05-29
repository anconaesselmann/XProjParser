//  Created by Axel Ancona Esselmann on 5/20/24.
//

import Foundation

public struct XProjObject: Ranged {
    public let key: Substring
    public let elements: [Ranged]
    public let isArray: Bool
    public let comment: Substring?
    public var range: Range<String.Index>
    public var elementsRange: Range<String.Index>
}

public extension XProjObject {

    enum Error: Swift.Error {
        case missingProperty(String)
        case propertyNotOfType(String, String)
    }

    var properties: [XProjProperty] {
        elements.lazy
            .compactMap( { $0 as? XProjProperty })
    }

    var isa: XProjIsa? {
        value(for: "isa")
    }

    func stringValue(for key: String) throws -> any StringProtocol {
        guard let property = properties
            .first(where: {  $0.key == key } )
        else {
            throw Error.missingProperty(key)
        }
        guard let stringValue = property.value as? any StringProtocol else {
            throw Error.propertyNotOfType(key, "any StringProtocol")
        }
        return stringValue
    }

    func string(for key: String) throws -> String {
        try stringValue(for: key).stringValue
    }

    func value<T>(for key: String) -> T? {
        properties.first { $0.key == key }?.value as? T
    }

    func value<T>(for key: String, type: T.Type) -> T? {
        properties.first { $0.key == key }?.value as? T
    }

    func object(for key: String) -> XProjObject? {
        properties.first { $0.key == key }?.value as? XProjObject
    }

    func id(for key: String) throws -> XProjId {
        guard let id = properties.first { $0.key == key }?.value as? XProjId else {
            throw Error.propertyNotOfType(key, "XProjId")
        }
        return id
    }

    func array(for key: String) throws -> [XProjArrayElement] {
        guard let elements = (properties.first { $0.key == key }?.value as? XProjObject)?.elements as? [XProjArrayElement] else {
            throw Error.missingProperty(key)
        }
        return elements
    }

    func objectPropertyRanges(for key: String) throws -> (outer: Range<String.Index>, inner: Range<String.Index>) {
        guard let property = properties.first { $0.key == key }?.value as? XProjObject else {
            throw Error.missingProperty(key)
        }
        guard let first = property.elements.first, let last = property.elements.last else {
            throw Error.missingProperty(key)
//            return (outer: property.range, inner: )
        }
        return (
            outer: property.range,
            inner: first.range.lowerBound..<last.range.upperBound
        )
    }
}

public extension Array where Element == XProjArrayElement {

    enum Error: Swift.Error {
        case missingId
        case notAnId
    }
    var values: [Any] {
        map { $0.value }
    }    

    var ids: [XProjId] {
        compactMap { $0.value as? XProjId }
    }

    func element(where id: XProjId) throws -> Element {
        guard let element = first(where: { $0.id?.stringValue == id.stringValue } )
        else {
            throw Error.missingId
        }
        return element
    }

    func first(where predicate: (XProjId) throws -> Bool) throws -> XProjId {
        guard
            let element = try first(where: {
                guard let id = $0.id else {
                    throw Error.notAnId
                }
                return try predicate(id)
            })
        else {
            throw Error.missingId
        }
        guard let id = element.id else {
            throw Error.notAnId
        }
        return id
    }

    func filter(where predicate: (XProjId) throws -> Bool) throws -> [XProjId] {
        let elements = try filter( {
            guard let id = $0.id else {
                throw Error.notAnId
            }
            return try predicate(id)
        })
        let ids = elements.compactMap { $0.id }
        return ids
    }
}

public extension XProjArrayElement {
    var id: XProjId? {
        value as? XProjId
    }
}

extension StringProtocol {
    var stringValue: String {
        String(self)
    }
}

enum RangedError: Swift.Error {
    case noRootObject
}

public extension Array where Element == any Ranged {

    func root() throws -> XProjRoot {
        guard let root = first(where: { type(of: $0) == XProjRoot.self}) as? XProjRoot
        else {
            throw RangedError.noRootObject
        }
        return root
    }
}
