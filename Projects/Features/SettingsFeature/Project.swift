import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "SettingsFeature",
    organizationName: Constants.organizationName,
    settings: .beanTrackerDefault,
    targets: [
        .target(
            name: "SettingsFeature",
            destinations: Constants.destinations,
            product: .framework,
            bundleId: "\(Constants.bundleIdPrefix).feature.settings",
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
