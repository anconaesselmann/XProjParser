//  Created by Axel Ancona Esselmann on 5/20/24.
//

import Foundation

public enum XProjIsa: Identifiable, Equatable {

    case PBXBuildFile, PBXFileReference, PBXFrameworksBuildPhase, PBXGroup, PBXNativeTarget, PBXProject, PBXResourcesBuildPhase, PBXSourcesBuildPhase, XCBuildConfiguration, XCConfigurationList, XCRemoteSwiftPackageReference, XCLocalSwiftPackageReference, XCSwiftPackageProductDependency
    case other(String)

    public var id: String {
        rawValue
    }

    public var rawValue: String {
        switch self {
        case .PBXBuildFile:
            return "PBXBuildFile"
        case .PBXFileReference:
            return "PBXFileReference"
        case .PBXFrameworksBuildPhase:
            return "PBXFrameworksBuildPhase"
        case .PBXGroup:
            return "PBXGroup"
        case .PBXNativeTarget:
            return "PBXNativeTarget"
        case .PBXProject:
            return "PBXProject"
        case .PBXResourcesBuildPhase:
            return "PBXResourcesBuildPhase"
        case .PBXSourcesBuildPhase:
            return "PBXSourcesBuildPhase"
        case .XCBuildConfiguration:
            return "XCBuildConfiguration"
        case .XCConfigurationList:
            return "XCConfigurationList"
        case .XCRemoteSwiftPackageReference:
            return "XCRemoteSwiftPackageReference"
        case .XCLocalSwiftPackageReference:
            return "XCLocalSwiftPackageReference"
        case .XCSwiftPackageProductDependency:
            return "XCSwiftPackageProductDependency"
        case .other(let rawValue):
            return rawValue
        }
    }

    public init(_ string: Substring) {
        let rawValue = String(string)
        switch rawValue {
        case "PBXBuildFile":
            self = .PBXBuildFile
        case "PBXFileReference":
            self = .PBXFileReference
        case "PBXFrameworksBuildPhase":
            self = .PBXFrameworksBuildPhase
        case "PBXGroup":
            self = .PBXGroup
        case "PBXNativeTarget":
            self = .PBXNativeTarget
        case "PBXProject":
            self = .PBXProject
        case "PBXResourcesBuildPhase":
            self = .PBXResourcesBuildPhase
        case "PBXSourcesBuildPhase":
            self = .PBXSourcesBuildPhase
        case "XCBuildConfiguration":
            self = .XCBuildConfiguration
        case "XCConfigurationList":
            self = .XCConfigurationList
        case "XCRemoteSwiftPackageReference":
            self = .XCRemoteSwiftPackageReference
        case "XCLocalSwiftPackageReference":
            self = .XCLocalSwiftPackageReference
        case "XCSwiftPackageProductDependency":
            self = .XCSwiftPackageProductDependency
        default:
            self = .other(rawValue)
        }
    }
}
