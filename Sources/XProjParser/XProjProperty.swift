//  Created by Axel Ancona Esselmann on 5/20/24.
//

import Foundation

public struct XProjProperty {
    public let indentation: String
    public let key: String
    public let value: Any

    public init(indentation: String, key: String, value: Any) {
        self.indentation = indentation
        self.key = key
        self.value = value
    }
}
