//  Created by Axel Ancona Esselmann on 6/14/24.
//

import Foundation

public extension XProjRoot {

    enum GroupError: Swift.Error {
        case missingGroup(String)
        case missingParentGroup
        case missingEntryInFile(String)
        case missingNameOrGroup
    }
    
    func groups(in content: String) throws -> XProjGroup {
        guard let project = firstElement(withIsa: .PBXProject) else {
            throw XProjRootError.missingElement(.PBXProject)
        }
        let mainGroupId = try project.id(for: "mainGroup")
        return try resolve(id: mainGroupId)
    }

    func groupPath(_ name: String, in content: String) throws -> String {
        let mainGroup = try groups(in: content)
        guard let packageGroup = mainGroup.child(where: { $0.name == name || $0.path == name}) else {
            throw GroupError.missingGroup(name)
        }
        var current = packageGroup
        var parentId = packageGroup.parentId
        var pathComponents: [String] = []
        while parentId != nil {
            guard let path = current.path ?? current.name else {
                break
            }
            pathComponents.append(path)
            parentId = current.parentId
            if let XProjGroup = parentId {
                current = try resolve(id: XProjGroup)
            }
        }
        return pathComponents
            .reversed()
            .joined(separator: "/")
    }

    func removeGroup(_ name: String, in content: String) throws -> String {
        // TODO: Make sure name is unique in groups. Do this before moving the directory!
        var content = content
        let mainGroup = try groups(in: content)
        guard let packageGroup = mainGroup.child(where: { $0.name == name || $0.path == name}) else {
            throw GroupError.missingGroup(name)
        }
        let ids = packageGroup.ids()
        let elements = try ids.map {
            try element(withId: $0)
        }

        let idSet = Set(ids)

        let fileReferences = try self.elements(withIsa: .PBXBuildFile).filter {
            guard let fileRef = try? $0.id(for: "fileRef") else {
                return false
            }
            return idSet.contains(fileRef)
        }

        let fileReferenceIds = fileReferences.compactMap { XProjId($0.key) }

        let sourcesBuildPhases = try self.elements(withIsa: .PBXSourcesBuildPhase)

        let fileReferenceIdSet = Set(fileReferenceIds)

        let referenceIdsInSourceBuildPhases = sourcesBuildPhases.reduce(into: [any Ranged]()) {
            guard let filesArray = try? $1.array(for: "files") else {
                return
            }
            let referenceIds = filesArray.filter {
                guard let id = $0.value as? XProjId else {
                    return false
                }
                return fileReferenceIdSet.contains(id)
            }
            $0 += referenceIds
        }

        guard let parentId = packageGroup.parentId else {
            throw GroupError.missingParentGroup
        }

        let parent = try self.element(withId: parentId)
        guard let packageGroupEntryInParentFile = try parent.array(for: "children").first(where: {
            $0.id == packageGroup.id
        }) else {
            throw GroupError.missingEntryInFile(packageGroup.id.stringValue)
        }

        let elementRanges = (elements as [any Ranged])
            .ranges()
        let fileReferenceRanges = (fileReferences as [any Ranged])
            .ranges()
        let referenceIdsInSourceBuildPhaseRanges = (referenceIdsInSourceBuildPhases as [any Ranged])
            .ranges()
        let packageGroupEntryInParentFileRange = packageGroupEntryInParentFile.range

        let ranges = (
            elementRanges +
            fileReferenceRanges +
            referenceIdsInSourceBuildPhaseRanges +
            [packageGroupEntryInParentFileRange]
        ).merged()
        return content.removedSubranges(ranges)
    }

    private func resolve(id: XProjId) throws -> XProjGroup {
        let element = try self.element(withId: id)
        let name: String? = try? element.string(for: "name")
        let path: String? = try? element.string(for: "path")
        let childrenIds = ((try? element.array(for: "children")) ?? []).ids

        var group = XProjGroup(
            id: id,
            path: path,
            name: name,
            children: try childrenIds.map {
                var child = try resolve(id: $0)
                child.parentId = id
                return child
            }
        )
        return group
    }

}
