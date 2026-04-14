// swift-tools-version: 6.0

#if TUIST
import ProjectDescription

let packageSettings = PackageSettings(
    productTypes: [
        "CasePaths": .framework,
        "Clocks": .framework,
        "CombineSchedulers": .framework,
        "ComposableArchitecture": .framework,
        "ConcurrencyExtras": .framework,
        "CustomDump": .framework,
        "Dependencies": .framework,
        "IdentifiedCollections": .framework,
        "IssueReporting": .framework,
        "OrderedCollections": .framework,
        "Perception": .framework,
        "Sharing": .framework,
        "SwiftUINavigation": .framework,
        "UIKitNavigation": .framework,
        "XCTestDynamicOverlay": .framework,
    ]
)
#endif

import PackageDescription

let package = Package(
    name: "BeanTrackerDependencies",
    dependencies: [
        .package(
            url: "https://github.com/pointfreeco/swift-composable-architecture",
            from: "1.23.1"
        )
    ]
)
