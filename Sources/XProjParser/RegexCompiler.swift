//  Created by Axel Ancona Esselmann on 5/20/24.
//

import Foundation

final internal class RegexCompiler {
    typealias R = Regex<(Substring, Optional<Substring>, Optional<Substring>, objectWhiteSpace: Optional<Substring>, key: Optional<Substring>, Optional<Substring>, propertyComment: Optional<Substring>, Optional<Substring>, objectStart: Optional<Substring>, arrayStart: Optional<Substring>, Optional<Substring>, whiteSpace: Optional<Substring>, propertyKey: Optional<Substring>, value: Optional<Substring>, Optional<Substring>, rootObjectStart: Optional<Substring>, comment: Optional<Substring>, Optional<Substring>, id: Optional<Substring>, Optional<Substring>, idComment: Optional<Substring>, Optional<Substring>, beginningSectionName: Optional<Substring>, Optional<Substring>, endingSectionName: Optional<Substring>)>

    typealias ArrayR = Regex<(Substring, Optional<Substring>, quoted: Optional<Substring>, Optional<Substring>, Optional<Substring>, notQuoted: Optional<Substring>, Optional<Substring>, id: Optional<Substring>, Optional<Substring>, comment: Optional<Substring>)>

    private var _regex: R?
    private var _arrayRegex: ArrayR?

    static let shared = RegexCompiler()

    private init() { }

    func regex() throws -> R {
        if let regex = _regex {
            return regex
        }
        let singleLineCommentRegexString = "\\s*\\/\\/\\s*(?<comment>.+)"

        let nestStartRegexString =
            "(?<objectWhiteSpace>[ \\t]*)" +
            "(?<key>[^=\\s\\/]+)\\s*" +
            "(\\/\\*\\s*(?<propertyComment>[^\\*]+)\\s*\\*\\/\\s*)?=\\s+" +
            "((?<objectStart>\\{)|(?<arrayStart>\\())"

        let rootObjectStart = "[ \t]*(?<rootObjectStart>\\{)"

        let propertyString =
            "(?<whiteSpace>[\\t ]*)" +
            "(?<propertyKey>[^ \\{\\}; \t\n]+)" +
            "\\s=\\s" +
            "(?<value>[^;\\{]+)" +
            ";"

        let idString = "(?<id>[0-9A-F]{24})\\s+(\\/\\*\\s*(?<idComment>[^\\*]+)\\s*\\*\\/)?"

        let sectionStartString = "\\/\\*\\s+Begin\\s+(?<beginningSectionName>[^\\s]+)\\s+section\\s+\\*\\/"
        let sectionEndString = "\\/\\*\\s+End\\s+(?<endingSectionName>[^\\s]+)\\s+section\\s+\\*\\/"

        let regexString = "((\(nestStartRegexString))|(\(propertyString))|(\(rootObjectStart))|\(singleLineCommentRegexString))|(\(idString))|(\(sectionStartString))|(\(sectionEndString))"
        let regex: R = try Regex(regexString)
        _regex = regex
        return regex
    }

    func arrayRegex() throws -> ArrayR {
        if let regex = _arrayRegex {
            return regex
        }
        let quotedString = "\\s*(?<quoted>\"([^\"]|\\\\\")+\")\\s*,"
        let noQuoteString = "\\s*(?<notQuoted>[^,\\s]+)\\s*,"
        let id = "\\s*(?<id>[0-9A-F]{24})\\s+(\\/\\*\\s*(?<comment>[^\\*]+)\\s*\\*\\/)?\\s*,"
        let regexString = "(\(quotedString))|(\(noQuoteString))|(\(id))"
        let regex: ArrayR = try Regex(regexString)
        _arrayRegex = regex
        return regex
    }
}
