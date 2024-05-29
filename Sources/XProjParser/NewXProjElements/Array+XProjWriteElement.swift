//  Created by Axel Ancona Esselmann on 5/29/24.
//

import Foundation

extension Array where Element == XProjWriteElement {
    func wrappedInSectionHeaders(_ isa: XProjIsa) -> Self {
        guard let index = first?.index else {
            return self
        }
        let indicies = map { $0.index }
        guard reduce(into: true, { $0 = $0 && $1.index == index }) else {
            return self
        }
        return [
            XProjWriteElement.linebreak(index: index),
            XProjWriteElement.sectionStart(
                index: index,
                isa: isa
            )
        ] + self + [
            XProjWriteElement.sectionEnd(
                index: index,
                isa: isa
            )
        ]
    }
}
