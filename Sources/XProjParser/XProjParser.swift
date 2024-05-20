//  Created by Axel Ancona Esselmann on 5/20/24.
//

import Foundation
import ParenthesesParser

public struct XProjParser {
    public enum Error: Swift.Error {
        case unableToParse
    }

    public static func parse(content: Substring, range: Range<String.Index>) throws -> [Any] {
        let regex = try RegexCompiler.shared.regex()
        var currentIndex = range.lowerBound
        let endIndex = range.upperBound
        let currentContent = content[currentIndex..<endIndex]
        var results: [Any] = []
        while let result = try regex.firstMatch(in: currentContent[currentIndex..<endIndex]) {
            if 
                currentIndex != result.range.lowerBound,
                !currentContent.containsWhitespace(in: currentIndex..<result.range.lowerBound)
            {
                throw Error.unableToParse
            }
            if let idString = result.id {
                let comment = result.idComment
                let id = XProjId(stringValue: idString, comment: comment)
                results.append(id)
                currentIndex = result.range.upperBound
            } else if let commentString = result.comment {
                let comment = XProjComment(commentString)
                results.append(comment)
                currentIndex = result.range.upperBound
            } else if result.rootObjectStart != nil {
                guard let objectRange = (try? ParenthesesParser().nextFrame(
                    currentContent,
                    from: currentContent.index(before: result.range.upperBound),
                    types: [.braces]
                ))?.range else {
                    throw Error.unableToParse
                }
                let objectBodyRange = try objectRange.clipedBounds(for: currentContent)
                let elements = try parse(content: content[objectBodyRange], range: objectBodyRange)
                let root = XProjRoot(elements: elements)
                results.append(root)
                currentIndex = objectRange.upperBound
            } else if let objectStart = result.objectStart, let key = result.key {
                guard let objectRange = (try? ParenthesesParser().nextFrame(
                    currentContent,
                    from: currentContent.index(before: result.range.upperBound),
                    types: [.braces]
                ))?.range else {
                    throw Error.unableToParse
                }
                let objectBodyRange = try objectRange.clipedBounds(for: currentContent)
                let elements = try parse(content: content[objectBodyRange], range: objectBodyRange)
                let element = XProjObject(key: key, elements: elements)
                results.append(element)
                currentIndex = objectRange.upperBound
                try currentContent.advance(until: ";", index: &currentIndex)
            } else if let arrayStart = result.arrayStart, let key = result.key {
                guard let arrayRange = (try? ParenthesesParser().nextFrame(
                    currentContent,
                    from: currentContent.index(before: result.range.upperBound),
                    types: [.parentheses]
                ))?.range else {
                    throw Error.unableToParse
                }
                let arrayBodyRange = try arrayRange.clipedBounds(for: currentContent)
                let elements = try parse(arrayContent: content[arrayBodyRange], range: arrayBodyRange)
                let element = XProjArray(key: key, elements: elements)
                results.append(element)
                currentIndex = arrayRange.upperBound
                try currentContent.advance(until: ";", index: &currentIndex)
            } else if let key = result.propertyKey, var stringValue = result.value, let whiteSpace = result.whiteSpace {
                let stringValue = String(stringValue)
                let value: Any
                if key == "isa" {
                    value = XProjIsa(rawValue: stringValue)
                } else if let id = XProjId(stringValue) {
                    value = id
                } else if let boolValue = Bool(verbose: stringValue) {
                    value = boolValue
                } else if let intValue = Int(stringValue) {
                    value = intValue
                } else {
                    value = stringValue
                }
                let property = XProjProperty(indentation: String(whiteSpace), key: String(key), value: value)
                results.append(property)
                currentIndex = result.range.upperBound
            } else if let name = result.beginningSectionName {
                let isa = XProjIsa(rawValue: String(name))
                let header = XProjSectionComment(isStart: true, isa: isa)
                results.append(header)
                currentIndex = result.range.upperBound
            } else if let name = result.endingSectionName {
                let isa = XProjIsa(rawValue: String(name))
                let footer = XProjSectionComment(isStart: false, isa: isa)
                results.append(footer)
                currentIndex = result.range.upperBound
            } else {
                throw Error.unableToParse
            }
        }
        if 
            currentIndex < endIndex,
            !currentContent.containsWhitespace(in: currentIndex..<endIndex)
        {
            throw Error.unableToParse
        }
        return results
    }

    static func parse(arrayContent content: Substring, range: Range<String.Index>) throws -> [Any] {
        let regex = try RegexCompiler.shared.arrayRegex()
        var currentIndex = range.lowerBound
        let endIndex = range.upperBound
        let currentContent = content[currentIndex..<endIndex]
        var results: [Any] = []
        while let result = try regex.firstMatch(in: currentContent[currentIndex..<endIndex]) {
            if let id = result.id {
                let comment = result.comment
                let id = XProjId(stringValue: id, comment: comment)
                results.append(id)
            } else if let quoted = result.quoted {
                results.append(String(quoted))
            } else if let notQuoted = result.notQuoted {
                results.append(String(notQuoted))
            } else {
                throw Error.unableToParse
            }
            currentIndex = result.range.upperBound
        }
        if currentIndex < endIndex {
            let skipped = currentContent[currentIndex..<endIndex].trimmingCharacters(in: .whitespacesAndNewlines)
            if !skipped.isEmpty {
                throw Error.unableToParse
            }
        }
        return results
    }
}
