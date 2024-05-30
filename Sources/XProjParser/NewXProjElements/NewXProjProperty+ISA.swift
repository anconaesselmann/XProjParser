//  Created by Axel Ancona Esselmann on 5/29/24.
//

import Foundation

public extension NewXProjProperty {
    static func isa(_ value: XProjIsa) -> Self {
        NewXProjProperty(key: "isa", value: value)
    }
}
