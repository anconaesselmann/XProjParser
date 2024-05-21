//  Created by Axel Ancona Esselmann on 5/20/24.
//

import Foundation

public struct XProjSectionComment: Ranged {
    public let isStart: Bool
    public let isa: XProjIsa
    public let range: Range<String.Index>
}

extension XProjSectionComment {
    init?(beginning: Substring?, ending: Substring?, range: Range<String.Index>) {
        guard let name = beginning ?? ending else {
            return nil
        }
        isa = XProjIsa(name)
        isStart = beginning != nil
        self.range = range
    }
}
