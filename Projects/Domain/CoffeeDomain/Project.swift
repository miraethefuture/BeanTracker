import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "CoffeeDomain",
    organizationName: Constants.organizationName,
    settings: .beanTrackerDefault,
    targets: [
        .target(
            name: "CoffeeDomain",
            destinations: Constants.destinations,
            product: .framework,
            bundleId: "\(Constants.bundleIdPrefix).domain.coffee",
            deploymentTargets: Constants.deploymentTargets,
            sources: ["Sources/**"]
        ),
        .target(
            name: "CoffeeDomainTests",
            destinations: Constants.destinations,
            product: .unitTests,
            bundleId: "\(Constants.bundleIdPrefix).domain.coffee.tests",
            deploymentTargets: Constants.deploymentTargets,
            sources: ["Tests/**"],
            dependencies: [
                .target(name: "CoffeeDomain"),
            ]
        ),
    ]
)
