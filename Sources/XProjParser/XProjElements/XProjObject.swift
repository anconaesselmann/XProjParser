//  Created by Axel Ancona Esselmann on 5/20/24.
//

import Foundation

public struct XProjObject: Ranged {
    public let key: Substring
    public let elements: [Any]
    public let isArray: Bool
    public let comment: Substring?
    public var range: Range<String.Index>
}
