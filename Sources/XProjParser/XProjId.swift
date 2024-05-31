//  Created by Axel Ancona Esselmann on 5/14/24.
//

import Foundation

public struct XProjId: Hashable, Equatable {
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

    public init?(_ body: Substring) {
        self.init(String(body))
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

    public func commented(_ comment: String?) -> Self {
        var copy = self
        copy.comment = comment
        return copy
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.stringValue == rhs.stringValue
    }

    public init(buildFileIdFrom uuid: UUID) {
        var uuidString = UUID().uuidString
        uuidString.removeAll { $0 == "-" }
        let targetSectionRange = uuidString.startIndex..<uuidString.index(uuidString.startIndex, offsetBy: 8)
        let dependencySectionRange = uuidString.index(uuidString.startIndex, offsetBy: 8)..<uuidString.index(uuidString.startIndex, offsetBy: 24)
        stringValue = String(uuidString[targetSectionRange]) + String(uuidString[dependencySectionRange])
    }

    public init(packageIdFrom uuid: UUID) {
        var uuidString = UUID().uuidString
        uuidString.removeAll { $0 == "-" }
        let targetSectionRange = uuidString.startIndex..<uuidString.index(uuidString.startIndex, offsetBy: 8)
        let dependencySectionRange = uuidString.index(uuidString.startIndex, offsetBy: 16)..<uuidString.index(uuidString.startIndex, offsetBy: 32)
        stringValue = String(uuidString[targetSectionRange]) + String(uuidString[dependencySectionRange])
    }

    public init(remoteIdFrom uuid: UUID) {
        var uuidString = UUID().uuidString
        uuidString.removeAll { $0 == "-" }
        let range = uuidString.index(uuidString.startIndex, offsetBy: 8)..<uuidString.index(uuidString.startIndex, offsetBy: 32)
        stringValue = String(uuidString[range])
    }

    public init(localIdFrom uuid: UUID) {
        stringValue = String(XProjId(remoteIdFrom: uuid).stringValue.reversed())
    }
}
