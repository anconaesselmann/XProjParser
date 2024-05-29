//  Created by Axel Ancona Esselmann on 5/29/24.
//

import Foundation

public struct NewLineBreak: XProjWriteable {
    public let count: Int

    func asString(_ indentCount: Int) throws -> String {
        Array(repeating: "\n", count: count).joined()
    }

    static var one: Self {
        .init(count: 0)
    }
}
