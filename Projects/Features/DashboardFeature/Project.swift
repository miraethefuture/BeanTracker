import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "DashboardFeature",
    organizationName: Constants.organizationName,
    settings: .beanTrackerDefault,
    targets: [
        .target(
            name: "DashboardFeature",
            destinations: Constants.destinations,
            product: .framework,
            bundleId: "\(Constants.bundleIdPrefix).feature.dashboard",
            deploymentTargets: Constants.deploymentTargets,
            sources: ["Sources/**"],
            dependencies: [
                .domain("CoffeeDomain"),
                .core("DatabaseClient"),
                .external(name: "ComposableArchitecture"),
            ]
        )
    ]
)
