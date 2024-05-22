//  Created by Axel Ancona Esselmann on 5/21/24.
//

import Foundation

public extension XProjRoot {

    func removeRemotePackages(in content: String, _ elements: (packageName: String, targetName: String)...) throws -> String {
        let containers = try remotePackageContainers(in: elements.map { $0.targetName })
        var ranges = try elements
            .reduce(into: [Range<String.Index>]()) {
                $0 += try remotePackageEntries(
                    for: $1.packageName,
                    in: $1.targetName
                ).ranges
            }
            .merged
            .map {
                containers.reduce(into: $0) {
                    $0 = $0.enlarged(to: $1.outer, if: $1.inner)
                }
            }
        return content.removedSubranges(ranges)
    }

    private func remotePackageContainers(in targetNames: [String]) throws -> [(outer: Range<String.Index>, inner: Range<String.Index>)] {
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

    private func remotePackageEntries(for name: String, in targetName: String) throws -> [any Ranged] {
        guard let target = firstElement(
            withIsa: .PBXNativeTarget,
            key: "name",
            value: targetName
        ) else {
            throw XProjRootError.missingTargetWithName(targetName)
        }
        let packageProductDependencyIdElements = target
            .array(for: "packageProductDependencies")
        let packageProductDependencyId = try packageProductDependencyIdElements
            .first { try element(withId: $0).string(for: "productName") == name }
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
        let packageId = try packageProductDependency.id(for: "package")
        let remotePackageReference = try element(withId: packageId)
        guard let project = firstElement(withIsa: .PBXProject) else {
            throw XProjRootError.missingProperty
        }
        let dependencyArrayElement = try project
            .array(for: "packageReferences")
            .element(where: packageId)
        let buildPhaseArrayElements = target.array(for: "buildPhases")
        let buildPhaseId = try buildPhaseArrayElements.first {
            try element(withId: $0).isa == .PBXFrameworksBuildPhase
        }
        let buildPhase = try element(withId: buildPhaseId)
        let fileArrayElement = try buildPhase.array(for: "files").element(where: buildFileId)
        return [
            packageProductDependency,
            remotePackageReference,
            dependencyArrayElement,
            packageProductDependencyArrayElement,
            fileArrayElement,
            buildFile
        ]
    }
}
