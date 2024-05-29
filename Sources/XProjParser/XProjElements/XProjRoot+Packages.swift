//  Created by Axel Ancona Esselmann on 5/21/24.
//

import Foundation

protocol XProjWriteable {
    func asString(_ indentCount: Int) throws -> String
}

public struct NewXProjSectionComment: XProjWriteable {
    public let isStart: Bool
    public let isa: XProjIsa

    func asString(_ indentCount: Int) throws -> String {
        var indentCount = indentCount
        let sectionCommentType = isStart ? "Begin" : "End"
        var result = ""
        result.indent(indentCount)
        result += "/* \(sectionCommentType) \(isa.rawValue) section */"
        return result
    }
}

public struct NewLineBreak: XProjWriteable {
    public let count: Int

    func asString(_ indentCount: Int) throws -> String {
        Array(repeating: "\n", count: count).joined()
    }

    static var one: Self {
        .init(count: 0)
    }
}

public struct NewXProjObject: XProjWriteable {
    public let key: String
    public let elements: [NewXProjProperty]
    public let isArray: Bool
    public let isCompact: Bool
    public let comment: String?

    public init(key: String, elements: [NewXProjProperty], isArray: Bool = false, isCompact: Bool = false, comment: String? = nil) {
        self.key = key
        self.elements = elements
        self.isArray = isArray
        self.isCompact = isCompact
        self.comment = comment
    }

    func asString(_ indentCount: Int) throws -> String {
        isCompact ? try asCompactString() : try asExpandedString(indentCount)
    }

    private func asExpandedString(_ indentCount: Int) throws -> String {
        var indentCount = indentCount
        var result = "{"
        for element in elements {
            result.nl()
            result += try element.asString(indentCount + 1)
        }
        result.nl()
        result.indent(indentCount)
        result += "}"
        return result
    }

    private func asCompactString() throws -> String {
        var result = "{"
        result += try elements
            .map { try $0.asString(0) }
            .joined(separator: " ")
        result += " }"
        return result
    }
}

extension String {
    mutating func nl() {
        self += "\n"
    }
    mutating func indent(_ count: Int) {
        self += Array(repeating: "\t", count: count).joined()
    }
}

public struct NewXProjProperty: XProjWriteable {
    enum Error: Swift.Error {
        case invalidValue
    }

    public let key: String
    public let value: Any

    public init(key: String, value: Any) {
        self.key = key
        self.value = value
    }

    func asString(_ indentCount: Int) throws -> String {
        var indentCount = indentCount
        var result = ""
        result.indent(indentCount)
        result += key
        if !(value is NewXProjObject) {
            result += " = "
        }
        switch value {
        case let string as String:
            result += string
        case let id as XProjId:
            result += id.stringValue
            if let comment = id.comment {
                result += " /* \(comment) */"
            }
        case let isa as XProjIsa:
            result += isa.rawValue
        case let object as NewXProjObject:
            if object.isArray {
                fatalError()
            } else {
                if let comment = object.comment {
                    result += " /* \(comment) */"
                }
                result += " = "
                result += try object.asString(indentCount)
            }
        case let ids as [XProjId]:
            result += "("
            let idStrings = ids.map { id in
                var result = id.stringValue
                if let comment = id.comment {
                    result += " /* \(comment) */"
                }
                return result
            }
            for idString in idStrings {
                result.nl()
                result.indent(indentCount + 1)
                result += idString + ","
            }
            result.nl()
            result.indent(indentCount)
            result += ")"
        default:
            throw Error.invalidValue
        }
        result += ";"
        return result
    }
}

public struct NewXProjArrayElement: XProjWriteable {
    enum Error: Swift.Error {
        case invalidValue
    }

    let value: Any
    func asString(_ indentCount: Int) throws -> String {
        switch value {
        case let id as XProjId:
            var result = ""
            result.indent(indentCount)
            result += id.stringValue
            if let comment = id.comment {
                result += " /* \(comment) */"
            }
            result += ","
            return result
        default:
            throw Error.invalidValue
        }
    }
}

struct XProjWriteElement {
    let index: String.Index
    let indent: Int
    let object: XProjWriteable

    static func linebreak(index: String.Index) -> Self {
        .init(index: index, indent: 0, object: NewLineBreak.one)
    }

    static func sectionStart(index: String.Index, isa: XProjIsa) -> Self {
        XProjWriteElement(
            index: index,
            indent: 0,
            object: NewXProjSectionComment(
                isStart: true,
                isa: isa
            )
        )
    }

    static func sectionEnd(index: String.Index, isa: XProjIsa) -> Self {
        XProjWriteElement(
            index: index,
            indent: 0,
            object: NewXProjSectionComment(
                isStart: false,
                isa: isa
            )
        )
    }
}

extension Array where Element == XProjWriteElement {
    func wrappedInSectionHeaders(_ isa: XProjIsa) -> Self {
        guard let index = first?.index else {
            return self
        }
        let indicies = map { $0.index }
        guard reduce(into: true, { $0 = $0 && $1.index == index }) else {
            return self
        }
        return [
            XProjWriteElement.linebreak(index: index),
            XProjWriteElement.sectionStart(
                index: index,
                isa: isa
            )
        ] + self + [
            XProjWriteElement.sectionEnd(
                index: index,
                isa: isa
            )
        ]
    }
}

struct Dependency {
    let name: String
    let url: String
    let version: String
}

public extension XProjRoot {

    func addRemotePackages(
        in content: String,
        _ elements: (packageName: String, url: String, version: String, targetName: String)...
    ) throws -> String {
        var content = content
        var remoteSwiftPackageReferenceObjects: [XProjWriteElement] = []
        var packageProductDependencyObjects: [XProjWriteElement] = []
        var buildFileObjects: [XProjWriteElement] = []
        var frameworkFilesObjects: [XProjWriteElement] = []
        var targetPackageProductDependencyIdsObjects: [XProjWriteElement] = []
        var remoteSwiftPackageReferenceIdsObjects: [XProjWriteElement] = []

        var remoteSwiftPackageReferenceIds: [String: XProjId] = [:]

        var createRemoteSwiftPackageReferenceSectionHeaders = false
        var createPackageProductDependencySectionHeaders = false

        let targets = self.elements(withIsa: .PBXNativeTarget)

        let targetsByName: [String: XProjObject] = try targets
            .reduce(into: [:]) {
                let name = try $1.string(for: "name")
                $0[name] = $1
            }

        let frameworksById: [XProjId: XProjObject] = try self.elements(withIsa: .PBXFrameworksBuildPhase)
            .reduce(into: [:]) {
                let id = XProjId(stringValue: $1.key)
                $0[id] = $1
            }

        let frameworkIds = Set(frameworksById.keys)

        let frameworks: [String: XProjObject] = try targets
            .reduce(into: [:]) {
                let name = try $1.string(for: "name")
                let buildPhases = Set(try $1.array(for: "buildPhases").ids)
                guard
                    let frameworkId = frameworkIds.intersection(buildPhases).first,
                    let framework = frameworksById[frameworkId]
                else {
                    throw Error.missingProperty
                }
                $0[name] = framework
            }

        var packageProductDependencyIds: [String: [String: XProjId]] = [:]

        for element in elements {
            let remoteSwiftPackageReferenceId: XProjId

            if let id = remoteSwiftPackageReferenceIds[element.packageName] {
                remoteSwiftPackageReferenceId = id
            } else {
                remoteSwiftPackageReferenceId = XProjId()
                let remoteSwiftPackageReference = NewXProjProperty(
                    key: remoteSwiftPackageReferenceId.stringValue,
                    value: NewXProjObject(
                        key: remoteSwiftPackageReferenceId.stringValue,
                        elements: [
                            NewXProjProperty(key: "isa", value: XProjIsa.XCRemoteSwiftPackageReference),
                            NewXProjProperty(key: "repositoryURL", value: "\"\(element.url)\""),
                            NewXProjProperty(
                                key: "requirement",
                                value: NewXProjObject(key: "requirement", elements: [
                                    NewXProjProperty(key: "kind", value: "upToNextMajorVersion"),
                                    NewXProjProperty(key: "minimumVersion", value: element.version)
                                ])
                            ),
                        ],
                        comment: "XCRemoteSwiftPackageReference \"\(element.packageName)\""
                    )
                )
                let lastElementIndex = self.elements(withIsa: .XCRemoteSwiftPackageReference).last?.range.upperBound
                createRemoteSwiftPackageReferenceSectionHeaders = lastElementIndex == nil
                guard let index = lastElementIndex ?? self.sectionComments.last?.range.upperBound else {
                    throw Error.missingProperty
                }
                let writeElement = XProjWriteElement(
                    index: index,
                    indent: 2,
                    object: remoteSwiftPackageReference
                )
                remoteSwiftPackageReferenceObjects.append(writeElement)
                remoteSwiftPackageReferenceIds[element.packageName] = remoteSwiftPackageReferenceId
            }

            let packageProductDependencyId = XProjId()
            if packageProductDependencyIds[element.targetName] == nil {
                packageProductDependencyIds[element.targetName] = [:]
            }
            packageProductDependencyIds[element.targetName]?[element.packageName] = packageProductDependencyId
            let packageProductDependency = NewXProjProperty(
                key: packageProductDependencyId.stringValue,
                value: NewXProjObject(
                    key: packageProductDependencyId.stringValue,
                    elements: [
                        NewXProjProperty(key: "isa", value: XProjIsa.XCSwiftPackageProductDependency),
                        NewXProjProperty(
                            key: "package",
                            value: remoteSwiftPackageReferenceId
                                .commented("XCRemoteSwiftPackageReference \"\(element.packageName)\"")
                        ),
                        NewXProjProperty(key: "productName", value: element.packageName)
                    ],
                    comment: element.packageName
                )
            )
            let lastElementIndex = self.elements(withIsa: .XCSwiftPackageProductDependency).last?.range.upperBound
            createPackageProductDependencySectionHeaders = lastElementIndex == nil
            guard var index = lastElementIndex ?? self.sectionComments.last?.range.upperBound else {
                throw Error.missingProperty
            }
            var writeElement = XProjWriteElement(
                index: index,
                indent: 2,
                object: packageProductDependency
            )
            packageProductDependencyObjects.append(writeElement)

            // 1 PBXBuildFile

            let buildFileId = XProjId()
            let buildFile = NewXProjProperty(
                key: buildFileId.stringValue,
                value: NewXProjObject(
                    key: buildFileId.stringValue,
                    elements: [
                        NewXProjProperty(key: "isa", value: XProjIsa.PBXBuildFile),
                        NewXProjProperty(
                            key: "productRef",
                            value: packageProductDependencyId.commented(element.packageName)
                        ),
                    ],
                    isCompact: true,
                    comment: "\(element.packageName) in Frameworks"
                )
            )
            index = self.elements(withIsa: .PBXBuildFile).last!.range.upperBound
            writeElement = XProjWriteElement(
                index: index,
                indent: 2,
                object: buildFile
            )
            buildFileObjects.append(writeElement)

            // 2 PBXFrameworksBuildPhase

            guard let framework = frameworks[element.targetName] else {
                throw Error.missingProperty
            }
            guard let files = framework.object(for: "files") else {
                throw Error.missingProperty
            }
            index = files.elements.isEmpty
                ? files.elementsRange.lowerBound
                : files.elementsRange.upperBound

            writeElement = XProjWriteElement(
                index: index,
                indent: 4,
                object: NewXProjArrayElement(value: buildFileId.commented("\(element.packageName) in Frameworks"))
            )
            frameworkFilesObjects.append(writeElement)
        }

        guard let project = firstElement(withIsa: .PBXProject) else {
            throw XProjRootError.missingProperty
        }

        let elementsByTarget = elements.reduce(into: [String: [Dependency]]()) {
            $0[$1.targetName] = ($0[$1.targetName] ?? []) + [Dependency(name: $1.packageName, url: $1.url, version: $1.version)]
        }

        for (targetName, dependencies) in elementsByTarget {
            // 3 PBXNativeTarget

            guard let target = firstElement(
                withIsa: .PBXNativeTarget,
                key: "name",
                value: targetName
            ) else {
                throw XProjRootError.missingTargetWithName(targetName)
            }
            if let packageProductDependenciesArray = try? target.array(for: "packageProductDependencies") {
                // TODO: Not implemented
                assertionFailure()
            } else {
                // TODO: insert alphabetically
                let index = target.elementsRange.upperBound
                // TODO: sort
                let ids: [XProjId] = try dependencies.map {
                    guard let id = packageProductDependencyIds[targetName]?[$0.name] else {
                        throw Error.missingProperty
                    }
                    return id.commented($0.name)
                }
                let packageProductDependenciesProperty = NewXProjProperty(key: "packageProductDependencies", value: ids)
                let writeElement = XProjWriteElement(
                    index: index,
                    indent: 3,
                    object: packageProductDependenciesProperty
                )
                targetPackageProductDependencyIdsObjects.append(writeElement)
            }
        }

        // 4 PBXProject

        if let files = project.object(for: "packageReferences") {
            // TODO: - Implement
            assertionFailure("Implement")
        } else {
            // TODO: Insert alphabetically
            let index = project.elementsRange.upperBound

            let ids = remoteSwiftPackageReferenceIds.sorted(by: { $0.key < $1.key }).map { $0.value.commented("XCRemoteSwiftPackageReference \"\($0.key)\"") }

            let packageReferencesProperty = NewXProjProperty(key: "packageReferences", value: ids)
            let writeElement = XProjWriteElement(
                index: index,
                indent: 3,
                object: packageReferencesProperty
            )
            remoteSwiftPackageReferenceIdsObjects.append(writeElement)
        }

        let objects =
            buildFileObjects +
            frameworkFilesObjects +
            targetPackageProductDependencyIdsObjects +
            remoteSwiftPackageReferenceIdsObjects +
            (
                createRemoteSwiftPackageReferenceSectionHeaders
                    ? remoteSwiftPackageReferenceObjects
                        .wrappedInSectionHeaders(.XCRemoteSwiftPackageReference)
                    : remoteSwiftPackageReferenceObjects
            ) +
            (
                createPackageProductDependencySectionHeaders
                    ? packageProductDependencyObjects
                        .wrappedInSectionHeaders(.XCSwiftPackageProductDependency)
                    : packageProductDependencyObjects
            )
        for object in objects.sorted { $0.index < $1.index }.reversed() {
            let objectString = try object.object.asString(object.indent)
            content.insert(contentsOf: "\n" + objectString, at: object.index)
        }
        // TODO: consolidate
        return content
    }

    func removeRemotePackages(in content: String, _ elements: (packageName: String, relativePath: String?, targetName: String)...) throws -> String {
        var containers = try remotePackageContainers(in: elements.map { $0.targetName })
        var ranges = try elements
            .reduce(into: [Range<String.Index>]()) {
                $0 += try remotePackageEntries(
                    for: $1.packageName,
                    relativePath: $1.relativePath,
                    in: $1.targetName
                )
                .ranges()
            }
            .merged()
            .map {
                containers.reduce(into: $0) {
                    $0 = $0.enlarged(to: $1.outer, if: $1.inner)
                }
            }
        return content.removedSubranges(ranges)
    }

    private func remotePackageContainers(in targetNames: [String]) 
        throws -> [(outer: Range<String.Index>, inner: Range<String.Index>)]
    {
        guard let project = firstElement(withIsa: .PBXProject) else {
            throw XProjRootError.missingProperty
        }

        var containers: [(outer: Range<String.Index>, inner: Range<String.Index>)] = [
            try self.sectionRanges(for: .XCRemoteSwiftPackageReference),
            try self.sectionRanges(for: .XCSwiftPackageProductDependency),
            try project.objectPropertyRanges(for: "packageReferences")
        ]
        containers += try targetNames.map {
            guard let target = firstElement(
                withIsa: .PBXNativeTarget,
                key: "name",
                value: $0
            ) else {
                throw XProjRootError.missingTargetWithName($0)
            }
            return target
        }
        .map {
            try $0.objectPropertyRanges(for: "packageProductDependencies")
        }
        return containers
    }

    private func remotePackageEntries(for name: String, relativePath: String?, in targetName: String) throws -> [any Ranged] {
        var ranged: [(any Ranged)?] = []
        guard let target = firstElement(
            withIsa: .PBXNativeTarget,
            key: "name",
            value: targetName
        ) else {
            throw XProjRootError.missingTargetWithName(targetName)
        }
        let packageProductDependencyIdElements = try target
            .array(for: "packageProductDependencies")
        let packageProductDependencyIds = try packageProductDependencyIdElements
            .filter { try element(withId: $0).string(for: "productName") == name }
        for packageProductDependencyId in packageProductDependencyIds {
            let packageProductDependencyArrayElement = try packageProductDependencyIdElements
                .element(where: packageProductDependencyId)
            let packageProductDependency = try element(withId: packageProductDependencyId)
            guard let buildFile = firstElement(
                withIsa: .PBXBuildFile,
                key: "productRef",
                value: packageProductDependencyId
            ) else {
                throw XProjRootError.missingBuildFile
            }
            let buildFileId = XProjId(stringValue: buildFile.key)
            var remotePackageReference: XProjObject?
            var dependencyArrayElement: XProjArrayElement?
            do {
                let packageId = try packageProductDependency.id(for: "package")
                remotePackageReference = try element(withId: packageId)
                guard let project = firstElement(withIsa: .PBXProject) else {
                    throw XProjRootError.missingProperty
                }
                dependencyArrayElement = try project
                    .array(for: "packageReferences")
                    .element(where: packageId)
            } catch {
                print(error)
            }
            let buildPhaseArrayElements = try target.array(for: "buildPhases")
            let buildPhaseId = try buildPhaseArrayElements.first {
                try element(withId: $0).isa == .PBXFrameworksBuildPhase
            }
            let buildPhase = try element(withId: buildPhaseId)
            let fileArrayElement = try buildPhase.array(for: "files").element(where: buildFileId)
            ranged += [
                packageProductDependency,
                remotePackageReference,
                dependencyArrayElement,
                packageProductDependencyArrayElement,
                fileArrayElement,
                buildFile
            ]
        }
        return ranged.compactMap { $0 }
    }
}
