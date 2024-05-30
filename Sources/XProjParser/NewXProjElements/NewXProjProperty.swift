//  Created by Axel Ancona Esselmann on 5/29/24.
//

import Foundation

public struct NewXProjProperty: XProjWriteable {
    enum Error: Swift.Error {
        case invalidValue
    }

    public let key: String
    public let value: Any

    public init(key: String, value: Any) {
        self.key = key
        self.value = value
    }

    func asString(_ indentCount: Int) throws -> String {
        var indentCount = indentCount
        var result = ""
        result.indent(indentCount)
        result += key
        if !(value is NewXProjObject) {
            result += " = "
        }
        switch value {
        case let string as String:
            result += string
        case let id as XProjId:
            result += id.stringValue
            if let comment = id.comment {
                result += " /* \(comment) */"
            }
        case let isa as XProjIsa:
            result += isa.rawValue
        case let object as NewXProjObject:
            if object.isArray {
                fatalError()
            } else {
                if let comment = object.comment {
                    result += " /* \(comment) */"
                }
                result += " = "
                result += try object.asString(indentCount)
            }
        case let ids as [XProjId]:
            result += "("
            let idStrings = ids.map { id in
                var result = id.stringValue
                if let comment = id.comment {
                    result += " /* \(comment) */"
                }
                return result
            }
            for idString in idStrings {
                result.nl()
                result.indent(indentCount + 1)
                result += idString + ","
            }
            result.nl()
            result.indent(indentCount)
            result += ")"
        default:
            throw Error.invalidValue
        }
        result += ";"
        return result
    }
}
