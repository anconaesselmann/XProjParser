//  Created by Axel Ancona Esselmann on 6/14/24.
//

import Foundation

public struct XProjGroup {
    public let id: XProjId
    public var parentId: XProjId?
    public let path: String?
    public let name: String?

    public var children: [XProjGroup] = []

    public init(
        id: XProjId,
        path: String? = nil,
        name: String? = nil,
        children: [XProjGroup] = []
    ) {
        self.id = id
        self.path = path
        self.name = name
        self.children = children
    }
}

public extension XProjGroup {
    func child(where predicate: (Self) -> Bool) -> Self? {
        var queue: [XProjGroup] = []
        queue = [self] + queue
        while !queue.isEmpty {
            guard let current = queue.popLast() else {
                return nil
            }
            if predicate(current) {
                return current
            }
            for element in current.children {
                queue = [element] + queue
            }
        }
        return nil
    }

    func ids() -> [XProjId] {
        [id] + children.flatMap { $0.ids() }
    }

    func equals(nameOrGroup name: String) -> Bool {
        let groupName = self.name?.trimmingQuotes()
        let groupPath = self.path?.trimmingQuotes()
        return
            groupName == name ||
            groupPath == name
    }
}
