//  Created by Axel Ancona Esselmann on 5/29/24.
//

import Foundation

public struct NewXProjArrayElement: XProjWriteable {
    enum Error: Swift.Error {
        case invalidValue
    }

    let value: Any
    func asString(_ indentCount: Int) throws -> String {
        switch value {
        case let id as XProjId:
            var result = ""
            result.indent(indentCount)
            result += id.stringValue
            if let comment = id.comment {
                result += " /* \(comment) */"
            }
            result += ","
            return result
        default:
            throw Error.invalidValue
        }
    }
}
