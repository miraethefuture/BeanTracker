import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "OnboardingFeature",
    organizationName: Constants.organizationName,
    settings: .beanTrackerDefault,
    targets: [
        .target(
            name: "OnboardingFeature",
            destinations: Constants.destinations,
            product: .framework,
            bundleId: "\(Constants.bundleIdPrefix).feature.onboarding",
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
