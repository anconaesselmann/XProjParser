//  Created by Axel Ancona Esselmann on 5/29/24.
//

import Foundation

public struct NewXProjSectionComment: XProjWriteable {
    public let isStart: Bool
    public let isa: XProjIsa

    func asString(_ indentCount: Int) throws -> String {
        var indentCount = indentCount
        let sectionCommentType = isStart ? "Begin" : "End"
        var result = ""
        result.indent(indentCount)
        result += "/* \(sectionCommentType) \(isa.rawValue) section */"
        return result
    }
}
