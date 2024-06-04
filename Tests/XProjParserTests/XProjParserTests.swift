import XCTest
@testable import XProjParser

enum Error: Swift.Error {
    case unknown
}

final class XProjParserTests: XCTestCase {

    func testExample() throws {

        guard let filepath = Bundle.module.path(forResource: "01_project", ofType: "pbxproj") else {
            throw Error.unknown
        }
        var contents = try String(contentsOfFile: filepath)

        let id = UUID()

        contents = try XProjParser()
            .parse(content: contents)
            .root()
            .removePackages(
                in: contents,
                [(packageName: "WindowManager", relativePath: nil, targetName: "AppRover")]
            )
        contents = try XProjParser()
            .parse(content: contents)
            .root()
            .addPackages(
                in: contents,
                [
                    (
                        dependency: XProjDependency(
                            id: id,
                            name: "WindowManager",
                            url: "https://github.com/anconaesselmann/WindowManager",
                            version: "0.0.1"
                        ),
                        isLocal: false,
                        targetName: "AppRover"
                    )
                ]
            )
        print(contents)

    }
}
