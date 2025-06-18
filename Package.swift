// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Hellfire",
    platforms: [.macOS(PackageDescription.SupportedPlatform.MacOSVersion.v14),
                .iOS(PackageDescription.SupportedPlatform.IOSVersion.v16),
                .tvOS(PackageDescription.SupportedPlatform.TVOSVersion.v16)
    ],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "Hellfire"
            , targets: ["Hellfire"]
        ),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "Hellfire"
            , dependencies: []
            , path: "Sources"
            , linkerSettings: [
                .linkedLibrary("sqlite3") // Link the SQLite3 system library
            ]
//            , swiftSettings: [
//                .define("PRODUCTION", .when(configuration: .release)),
//                .define("SANDBOX", .when(configuration: .debug))
//            ]
        ),
        .testTarget(
            name: "HellfireTests"
            , dependencies: ["Hellfire"]
            , resources: [.process("TestData/Company.json"),
                          .process("TestData/UserContainer.json"),
                          .process("TestData/PersonArray.json"),
                          .process("TestData/Person.json"),
                          .process("TestData/ProductsResponse.json"),
                          .process("TestData/Dog.jpeg")]
        ),
    ]
)
