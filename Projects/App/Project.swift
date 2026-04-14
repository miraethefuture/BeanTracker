import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "BeanTrackerApp",
    organizationName: Constants.organizationName,
    settings: .beanTrackerDefault,
    targets: [
        .target(
            name: "BeanTrackerApp",
            destinations: Constants.destinations,
            product: .app,
            bundleId: "\(Constants.bundleIdPrefix).app",
            deploymentTargets: Constants.deploymentTargets,
            infoPlist: .extendingDefault(
                with: [
                    "CFBundleDisplayName": .string("BeanTracker"),
                    "UILaunchScreen": .dictionary([:]),
                    "CFBundleURLTypes": .array([
                        .dictionary([
                            "CFBundleURLName": .string("com.miraethefuture.BeanTracker"),
                            "CFBundleURLSchemes": .array([
                                .string("beantracker")
                            ])
                        ])
                    ])
                ]
            ),
            sources: ["Sources/**"],
            resources: ["Resources/**"],
            dependencies: [
                .feature("DashboardFeature"),
                .feature("BrewingLogFeature"),
                .feature("InventoryFeature"),
                .feature("OnboardingFeature"),
                .feature("SettingsFeature"),
                .core("DatabaseClient"),
                .external(name: "ComposableArchitecture"),
            ]
        )
    ]
)
