import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "BrewingLogFeature",
    organizationName: Constants.organizationName,
    settings: .beanTrackerDefault,
    targets: [
        .target(
            name: "BrewingLogFeature",
            destinations: Constants.destinations,
            product: .framework,
            bundleId: "\(Constants.bundleIdPrefix).feature.brewinglog",
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
