//  Created by Axel Ancona Esselmann on 5/29/24.
//

import Foundation

public struct XProjDependency {
    public let name: String
    internal let url: String?
    internal let version: String?
    internal let localPath: String?

    public init(name: String, url: String, version: String) {
        self.name = name
        self.url = url
        self.version = version
        self.localPath = nil
    }

    public init(name: String, url: String, version: String, localPath: String) {
        self.name = name
        self.url = url
        self.version = version
        self.localPath = localPath
    }

    public init(name: String, localPath: String) {
        self.name = name
        self.url = nil
        self.version = nil
        self.localPath = localPath
    }
}
