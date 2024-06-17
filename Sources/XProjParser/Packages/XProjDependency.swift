//  Created by Axel Ancona Esselmann on 5/29/24.
//

import Foundation

public struct XProjDependency {
    internal let id: UUID
    public let name: String
    public var url: String?
    public var version: String?
    public var localPath: String?

    public var hasLocalPath: Bool {
        localPath != nil && !(localPath?.isEmpty ?? true)
    }

    public init(
        id: UUID = UUID(),
        name: String,
        url: String? = nil,
        version: String? = nil,
        localPath: String? = nil
    ) {
        self.id = id
        self.name = name
        self.url = url
        self.version = version
        self.localPath = localPath
    }

    public func withLocalRoot(_ localRoot: String) -> Self {
        var copy = self
        copy.localPath = localRoot.appendedIfNecessary("/") + name
        return copy
    }
}
