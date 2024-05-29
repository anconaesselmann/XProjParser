//  Created by Axel Ancona Esselmann on 5/29/24.
//

import Foundation

public struct NewXProjObject: XProjWriteable {
    public let key: String
    public let elements: [NewXProjProperty]
    public let isArray: Bool
    public let isCompact: Bool
    public let comment: String?

    public init(key: String, elements: [NewXProjProperty], isArray: Bool = false, isCompact: Bool = false, comment: String? = nil) {
        self.key = key
        self.elements = elements
        self.isArray = isArray
        self.isCompact = isCompact
        self.comment = comment
    }

    func asString(_ indentCount: Int) throws -> String {
        isCompact ? try asCompactString() : try asExpandedString(indentCount)
    }

    private func asExpandedString(_ indentCount: Int) throws -> String {
        var indentCount = indentCount
        var result = "{"
        for element in elements {
            result.nl()
            result += try element.asString(indentCount + 1)
        }
        result.nl()
        result.indent(indentCount)
        result += "}"
        return result
    }

    private func asCompactString() throws -> String {
        var result = "{"
        result += try elements
            .map { try $0.asString(0) }
            .joined(separator: " ")
        result += " }"
        return result
    }
}
