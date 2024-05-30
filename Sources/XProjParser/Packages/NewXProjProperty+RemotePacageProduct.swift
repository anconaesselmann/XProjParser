//  Created by Axel Ancona Esselmann on 5/29/24.
//

import Foundation

public extension NewXProjProperty {
    public init(
        packageProductDependencyId: XProjId,
        remoteSwiftPackageReferenceId: XProjId?,
        name: String
    ) {
        let elements: [NewXProjProperty?] = [
            NewXProjProperty(key: "isa", value: XProjIsa.XCSwiftPackageProductDependency),
            remoteSwiftPackageReferenceId == nil
                ? nil
                : NewXProjProperty(
                    key: "package",
                    value: remoteSwiftPackageReferenceId!
                        .commented("XCRemoteSwiftPackageReference \"\(name)\"")
                ),
            NewXProjProperty(key: "productName", value: name)
        ]
        self = NewXProjProperty(
            key: packageProductDependencyId.stringValue,
            value: NewXProjObject(
                key: packageProductDependencyId.stringValue,
                elements: elements.compactMap { $0 },
                comment: name
            )
        )
    }
}
