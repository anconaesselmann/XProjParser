//  Created by Axel Ancona Esselmann on 5/29/24.
//

import Foundation

public struct XProjDependency {
    internal let id: UUID
    public let name: String
    internal let url: String?
    internal let version: String?
    internal var localPath: String?

    public var hasLocalPath: Bool {
        localPath != nil && !(localPath?.isEmpty ?? true)
    }

    public init(id: UUID = UUID(), name: String, url: String, version: String) {
        self.id = id
        self.name = name
        self.url = url
        self.version = version
        self.localPath = nil
    }

    public init(id: UUID = UUID(), name: String, url: String, version: String, localPath: String) {
        self.id = id
        self.name = name
        self.url = url
        self.version = version
        self.localPath = localPath
    }

    public init(id: UUID = UUID(), name: String, localPath: String) {
        self.id = id
        self.name = name
        self.url = nil
        self.version = nil
        self.localPath = localPath
    }

    public init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
        self.url = nil
        self.version = nil
        self.localPath = nil
    }

    public func withLocalRoot(_ localRoot: String) -> Self {
        var copy = self
        copy.localPath = localRoot + name
        return copy
    }
}
