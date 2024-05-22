//  Created by Axel Ancona Esselmann on 5/21/24.
//

import Foundation

public extension XProjRoot {

    func removeRemotePackages(in content: String, _ elements: (packageName: String, targetName: String)...) throws -> String {
        var remove = try elements.reduce(into: [any Ranged]()) {
            $0 += try remotePackageEntries($1.packageName, in: $1.targetName)
        }
        var ranges = remove.ranges.merged

        guard let project = firstElement(withIsa: .PBXProject) else {
            throw XProjRootError.missingProperty
        }

        var containers: [(outer: Range<String.Index>, inner: Range<String.Index>)] = [
            try self.sectionRanges(for: .XCRemoteSwiftPackageReference),
            try self.sectionRanges(for: .XCSwiftPackageProductDependency),
            try project.objectPropertyRanges(for: "packageReferences")
        ]
        containers += try elements.map {
            guard let target = firstElement(
                withIsa: .PBXNativeTarget,
                key: "name",
                value: $0.targetName
            ) else {
                throw XProjRootError.missingTargetWithName($0.targetName)
            }
            return target
        }.map {
            try $0.objectPropertyRanges(for: "packageProductDependencies")
        }

        for container in containers {
            ranges = ranges.enlarged(to: container.outer, ifIncluded: container.inner)
        }

        var content = content
        content.removeSubranges(ranges)
        return content
    }

    private func remotePackageEntries(_ name: String, in targetName: String) throws -> [any Ranged] {
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
