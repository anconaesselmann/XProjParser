//  Created by Axel Ancona Esselmann on 5/29/24.
//

import Foundation

public extension NewXProjProperty {
    init(remoteSwiftPackageReferenceId: XProjId, name: String, url: String?, version: String?) throws {
        guard let url = url, let version = version else {
            throw Error.invalidValue
        }
        self = NewXProjProperty(
            key: remoteSwiftPackageReferenceId.stringValue,
            value: NewXProjObject(
                key: remoteSwiftPackageReferenceId.stringValue,
                elements: [
                    .isa(.XCRemoteSwiftPackageReference),
                    NewXProjProperty(key: "repositoryURL", value: "\"\(url)\""),
                    NewXProjProperty(
                        key: "requirement",
                        value: NewXProjObject(key: "requirement", elements: [
                            NewXProjProperty(key: "kind", value: "upToNextMajorVersion"),
                            NewXProjProperty(key: "minimumVersion", value: version)
                        ])
                    ),
                ],
                comment: "XCRemoteSwiftPackageReference \"\(name)\""
            )
        )
    }

    init(localSwiftPackageReferenceId: XProjId, localPath: String?) throws {
        guard let localPath = localPath else {
            throw Error.invalidValue
        }
        self = NewXProjProperty(
            key: localSwiftPackageReferenceId.stringValue,
            value: NewXProjObject(
                key: localSwiftPackageReferenceId.stringValue,
                elements: [
                    .isa(.XCLocalSwiftPackageReference),
                    NewXProjProperty(key: "relativePath", value: localPath)
                ],
                comment: "XCLocalSwiftPackageReference \"\(localPath)\""
            )
        )
    }
}
