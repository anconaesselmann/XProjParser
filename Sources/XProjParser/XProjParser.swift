//  Created by Axel Ancona Esselmann on 5/20/24.
//

import Foundation
import ParenthesesParser

public struct XProjParser {
    public enum Error: Swift.Error {
        case unableToParse
    }

    private let parser = ParenthesesParser()

    public init() {}

    public func parse(content: Substring, range: Range<String.Index>) throws -> [Any] {
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
            if let comment = XProjComment(result.comment, range: result.range) {
                results.append(comment)
                currentIndex = result.range.upperBound
            } else if
                let frameStart = result.frameStart ?? result.rootObjectStart,
                let frameStartChar = frameStart.first,
                let frameType = FrameType(start: frameStartChar)
            {
                let frameStartIndex = currentContent.index(before: result.range.upperBound)
                let frame = try parser.nextFrame(
                    currentContent,
                    from: frameStartIndex,
                    types: [frameType]
                )
                let isArray = frameType.isParentheses
                let bodyRange = try frame.range.clipedBounds(for: currentContent)
                let subElements: [Any]
                if isArray {
                    subElements = try parse(arrayContent: content[bodyRange], range: bodyRange)
                } else {
                    subElements = try parse(content: content[bodyRange], range: bodyRange)
                }
                currentIndex = frame.range.upperBound
                let element: Any
                if let key = result.key {
                    element = XProjObject(
                        key: key,
                        elements: subElements, 
                        isArray: isArray,
                        range: result.range.lowerBound..<currentIndex
                    )
                    try currentContent.skipWhitespace(until: ";", index: &currentIndex)
                } else {
                    element = XProjRoot(
                        elements: subElements,
                        range: result.range.lowerBound..<currentIndex
                    )
                }
                results.append(element)
            } else if let property = XProjProperty(
                key: result.propertyKey,
                stringValue:  result.value,
                whiteSpace: result.whiteSpace,
                range: result.range
            ) {
                results.append(property)
                currentIndex = result.range.upperBound
            } else if let sectionComment = XProjSectionComment(
                beginning: result.beginningSectionName,
                ending: result.endingSectionName,
                range: result.range
            ) {
                results.append(sectionComment)
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

    private func parse(arrayContent content: Substring, range: Range<String.Index>) throws -> [Any] {
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
        if 
            currentIndex < endIndex,
            !currentContent.containsWhitespace(in: currentIndex..<endIndex)
        {
            throw Error.unableToParse
        }
        return results
    }
}
