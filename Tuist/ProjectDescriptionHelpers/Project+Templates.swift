import ProjectDescription

public enum Constants {
    public static let organizationName = "miraethefuture"
    public static let bundleIdPrefix = "com.miraethefuture.BeanTracker"
    public static let deploymentTargets: DeploymentTargets = .iOS("17.0")
    public static let destinations: Destinations = .iOS
    public static let baseSettings: SettingsDictionary = [
        "SWIFT_VERSION": "6.0",
        "ENABLE_USER_SCRIPT_SANDBOXING": "YES",
    ]
}

public extension Settings {
    static let beanTrackerDefault = Settings.settings(
        base: Constants.baseSettings,
        defaultSettings: .recommended
    )
}

public extension TargetDependency {
    static func feature(_ name: String) -> Self {
        .project(target: name, path: .relativeToRoot("Projects/Features/\(name)"))
    }

    static func domain(_ name: String) -> Self {
        .project(target: name, path: .relativeToRoot("Projects/Domain/\(name)"))
    }

    static func core(_ name: String) -> Self {
        .project(target: name, path: .relativeToRoot("Projects/Core/\(name)"))
    }
}
