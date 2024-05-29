//  Created by Axel Ancona Esselmann on 5/29/24.
//

import Foundation

struct XProjWriteElement {
    let index: String.Index
    let indent: Int
    let object: XProjWriteable

    static func linebreak(index: String.Index) -> Self {
        .init(index: index, indent: 0, object: NewLineBreak.one)
    }

    static func sectionStart(index: String.Index, isa: XProjIsa) -> Self {
        XProjWriteElement(
            index: index,
            indent: 0,
            object: NewXProjSectionComment(
                isStart: true,
                isa: isa
            )
        )
    }

    static func sectionEnd(index: String.Index, isa: XProjIsa) -> Self {
        XProjWriteElement(
            index: index,
            indent: 0,
            object: NewXProjSectionComment(
                isStart: false,
                isa: isa
            )
        )
    }
}
