//  Created by Axel Ancona Esselmann on 5/20/24.
//

import Foundation

public struct XProjProperty: Ranged {
    public let indentation: Substring
    public let key: Substring
    public let value: Any
    public var range: Range<String.Index>

    public init(
        indentation: Substring,
        key: Substring,
        value: Any,
        range: Range<String.Index>
    ) {
        self.indentation = indentation
        self.key = key
        self.value = value
        self.range = range
    }
}

extension XProjProperty {
    init?(
        key: Substring?,
        stringValue: Substring?,
        whiteSpace: Substring?,
        range: Range<String.Index>
    ) {
        guard let key = key, let stringValue = stringValue, let whiteSpace = whiteSpace else {
            return nil
        }
        let value: Any
        if key == "isa" {
            value = XProjIsa(stringValue)
        } else if let id = XProjId(stringValue) {
            value = id
        } else if let boolValue = Bool(verbose: stringValue) {
            value = boolValue
        } else if let intValue = Int(stringValue) {
            value = intValue
        } else {
            value = stringValue
        }
        self = XProjProperty(
            indentation: whiteSpace,
            key: key,
            value: value,
            range: range
        )
    }
}

extension String {
    init?(_ substring: Substring?) {
        guard let substring = substring else {
            return nil
        }
        self = String(substring)
    }
}
