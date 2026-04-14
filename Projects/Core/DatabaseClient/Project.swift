import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "DatabaseClient",
    organizationName: Constants.organizationName,
    settings: .beanTrackerDefault,
    targets: [
        .target(
            name: "DatabaseClient",
            destinations: Constants.destinations,
            product: .framework,
            bundleId: "\(Constants.bundleIdPrefix).core.database",
            deploymentTargets: Constants.deploymentTargets,
            sources: ["Sources/**"],
            dependencies: [
                .domain("CoffeeDomain"),
                .external(name: "ComposableArchitecture"),
            ]
        )
    ]
)
