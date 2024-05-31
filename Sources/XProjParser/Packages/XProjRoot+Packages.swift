//  Created by Axel Ancona Esselmann on 5/21/24.
//

import Foundation

public extension XProjRoot {

    func addPackages(
        in content: String,
        _ elements: [(dependency: XProjDependency, isLocal: Bool, targetName: String)]
    ) throws -> String {
        var content = content
        var localSwiftPackageReferenceObjects: [XProjWriteElement] = []
        var remoteSwiftPackageReferenceObjects: [XProjWriteElement] = []
        var packageProductDependencyObjects: [XProjWriteElement] = []
        var buildFileObjects: [XProjWriteElement] = []
        var frameworkFilesObjects: [XProjWriteElement] = []
        var targetPackageProductDependencyIdsObjects: [XProjWriteElement] = []
        var localSwiftPackageReferenceIdsObjects: [XProjWriteElement] = []
        var remoteSwiftPackageReferenceIdsObjects: [XProjWriteElement] = []

        var localSwiftPackageReferenceIds: [String: XProjId] = [:]
        var remoteSwiftPackageReferenceIds: [String: XProjId] = [:]

        var createLocalSwiftPackageReferenceSectionHeaders = false
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
            let name = element.dependency.name
            let url = element.dependency.url
            let localPath = element.dependency.localPath
            let version = element.dependency.version
            var remoteSwiftPackageReferenceId: XProjId?

            let elementId = element.dependency.id

            if element.isLocal {
                guard let localPath = localPath else {
                    throw Error.missingProperty
                }
                if localSwiftPackageReferenceIds[name] == nil {
                    let lastElementIndex = self.elements(withIsa: .XCLocalSwiftPackageReference)
                        .last?.range.upperBound
                    createLocalSwiftPackageReferenceSectionHeaders = lastElementIndex == nil
                    guard let index = lastElementIndex ?? self.sectionComments.last?.range.upperBound else {
                        throw Error.missingProperty
                    }
                    let id = XProjId(localIdFrom: elementId)
                    let writeElement = XProjWriteElement(
                        index: index,
                        indent: 2,
                        object: try NewXProjProperty(
                            localSwiftPackageReferenceId: id,
                            localPath: localPath
                        )
                    )
                    localSwiftPackageReferenceObjects.append(writeElement)
                    localSwiftPackageReferenceIds[name] = id
                }
            } else {
                if let id = remoteSwiftPackageReferenceIds[name] {
                    remoteSwiftPackageReferenceId = id
                } else {
                    let lastElementIndex = self.elements(withIsa: .XCRemoteSwiftPackageReference)
                        .last?.range.upperBound
                    createRemoteSwiftPackageReferenceSectionHeaders = lastElementIndex == nil
                    guard let index = lastElementIndex ?? self.sectionComments.last?.range.upperBound else {
                        throw Error.missingProperty
                    }
                    let id = XProjId(remoteIdFrom: elementId)
                    remoteSwiftPackageReferenceId = id
                    let writeElement = XProjWriteElement(
                        index: index,
                        indent: 2,
                        object: try NewXProjProperty(
                            remoteSwiftPackageReferenceId: id,
                            name: name,
                            url: url,
                            version: version
                        )
                    )
                    remoteSwiftPackageReferenceObjects.append(writeElement)
                    remoteSwiftPackageReferenceIds[name] = remoteSwiftPackageReferenceId
                }
            }

            let packageProductDependencyId = XProjId(packageIdFrom: elementId)
            if packageProductDependencyIds[element.targetName] == nil {
                packageProductDependencyIds[element.targetName] = [:]
            }
            packageProductDependencyIds[element.targetName]?[name] = packageProductDependencyId
            let packageProductDependency =  NewXProjProperty(
                packageProductDependencyId: packageProductDependencyId,
                remoteSwiftPackageReferenceId: remoteSwiftPackageReferenceId,
                name: name
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

            let buildFileId = XProjId(buildFileIdFrom: elementId)
            let buildFile = NewXProjProperty(
                key: buildFileId.stringValue,
                value: NewXProjObject(
                    key: buildFileId.stringValue,
                    elements: [
                        .isa(.PBXBuildFile),
                        NewXProjProperty(
                            key: "productRef",
                            value: packageProductDependencyId.commented(name)
                        ),
                    ],
                    isCompact: true,
                    comment: "\(name) in Frameworks"
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
                object: NewXProjArrayElement(value: buildFileId.commented("\(name) in Frameworks"))
            )
            frameworkFilesObjects.append(writeElement)
        }

        guard let project = firstElement(withIsa: .PBXProject) else {
            throw XProjRootError.missingProperty
        }

        let elementsByTarget = elements.reduce(into: [String: [XProjDependency]]()) {
            $0[$1.targetName] = ($0[$1.targetName] ?? []) + [$1.dependency]
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
                let index = try target.indexForNewProperty(named: "packageProductDependencies")
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
            let index = try project.indexForNewProperty(named: "packageReferences")

            let combinedIds = remoteSwiftPackageReferenceIds
                    .map { (key: $0.key, value: $0.value, isLocal: false)} +
                localSwiftPackageReferenceIds
                    .map { (key: $0.key, value: $0.value, isLocal: true)}

            let pathsByName = try elements
                .filter { $0.isLocal }
                .reduce(into: [String: String]()) {
                    if let path = $1.dependency.localPath {
                        $0[$1.dependency.name] = path
                    } else {
                        throw Error.missingProperty
                    }
                }

            let ids = try combinedIds
                .sorted { $0.key < $1.key }
                .map {
                    if $0.isLocal {
                        guard let path = pathsByName[$0.key] else {
                            throw Error.missingProperty
                        }
                        return $0.value.commented("XCLocalSwiftPackageReference \"\(path)\"")
                    } else {
                        return $0.value.commented("XCRemoteSwiftPackageReference \"\($0.key)\"")
                    }
                }

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
            localSwiftPackageReferenceIdsObjects +
            remoteSwiftPackageReferenceIdsObjects +
            (
                createLocalSwiftPackageReferenceSectionHeaders
                    ? localSwiftPackageReferenceObjects
                        .wrappedInSectionHeaders(.XCLocalSwiftPackageReference)
                    : localSwiftPackageReferenceObjects
            ) +
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

    func addPackages(
        in content: String,
        _ elements: (dependency: XProjDependency, isLocal: Bool, targetName: String)...
    ) throws -> String {
        try addPackages(in: content, elements)
    }

    func removePackages(in content: String, _ elements: [(packageName: String, relativePath: String?, targetName: String)]) throws -> String {
        var containers = try packageContainers(in: elements.map { $0.targetName })
        var ranges = try elements
            .reduce(into: [Range<String.Index>]()) {
                $0 += try remotePackageEntries(
                    for: $1.packageName,
                    relativePath: $1.relativePath,
                    in: $1.targetName
                )
                .ranges()
                $0 += try localPackageEntries(
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

    func removePackages(in content: String, _ elements: (packageName: String, relativePath: String?, targetName: String)...) throws -> String {
        try removePackages(in: content, elements)
    }

    private func packageContainers(in targetNames: [String])
        throws -> [(outer: Range<String.Index>, inner: Range<String.Index>)]
    {
        guard let project = firstElement(withIsa: .PBXProject) else {
            throw XProjRootError.missingProperty
        }

        var containers: [(outer: Range<String.Index>, inner: Range<String.Index>)?] = [
            try? self.sectionRanges(for: .XCLocalSwiftPackageReference),
            try? self.sectionRanges(for: .XCRemoteSwiftPackageReference),
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
        return containers.compactMap { $0 }
    }

    private func localPackageEntries(for name: String, relativePath: String?, in targetName: String) throws -> [any Ranged] {
        var ranged: [(any Ranged)?] = []
        let localPackageReferenceIds = try elements(withIsa: .XCLocalSwiftPackageReference)
            .map {
                (
                    id: XProjId(stringValue: $0.key),
                    relativePath: try $0.string(for: "relativePath")
                )
            }
            .filter {
                if let relativePath = relativePath {
                    return $0.relativePath == relativePath
                } else if let last = $0.relativePath.split(separator: "/").last {
                    return last == name
                } else {
                    return false
                }
            }.map { $0.id }
        guard !localPackageReferenceIds.isEmpty else {
            return []
        }
        ranged += try localPackageReferenceIds.map { try self.element(withId: $0)}
        guard let project = firstElement(withIsa: .PBXProject) else {
            throw XProjRootError.missingProperty
        }
        let localPackageReferenceArrayElements = try localPackageReferenceIds.map {
            try project
                .array(for: "packageReferences")
                .element(where: $0)
        }
        ranged += localPackageReferenceArrayElements
        return ranged.compactMap { $0 }
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
