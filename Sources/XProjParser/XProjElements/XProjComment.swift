//  Created by Axel Ancona Esselmann on 5/20/24.
//

import Foundation

public struct XProjComment: Ranged {

    public let stringValue: Substring
    public let range: Range<String.Index>

    public init?(_ comment: Substring?, range: Range<String.Index>) {
        guard let comment = comment else {
            return nil
        }
        self.stringValue = comment
        self.range = range
    }
}
