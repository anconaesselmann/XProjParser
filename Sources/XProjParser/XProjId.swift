//  Created by Axel Ancona Esselmann on 5/14/24.
//

import Foundation

public struct XProjId: Hashable {
    public var stringValue: String
    public var comment: String?

    public var id: String {
        stringValue
    }

    public init(stringValue: any StringProtocol, comment: (any StringProtocol)? = nil) {
        self.stringValue = String(stringValue)
        if let comment = comment {
            self.comment = String(comment)
        }
    }

    public init?(_ body: String) {
        let idRegex = #/(?<id>[0-9A-F]{24})\s*(\/\*\s*(?<comment>[^\*]+)\s*\*\/)?/#
        guard let result = try? idRegex.firstMatch(in: body) else {
            return nil
        }
        stringValue = String(result.id)
        if let comment = result.comment {
            self.comment = String(comment)
        }
    }

    public init() {
        var uuidString = UUID().uuidString
        uuidString.removeAll { $0 == "-" }
        let range = uuidString.startIndex..<uuidString.index(uuidString.startIndex, offsetBy: 24)
        stringValue = String(uuidString[range])
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(stringValue)
    }
}
