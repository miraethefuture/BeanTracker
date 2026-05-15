import BrewingLogFeature
import ComposableArchitecture
import DashboardFeature
import DatabaseClient
import InventoryFeature
import OnboardingFeature
import SettingsFeature

@Reducer
struct AppFeature {
    enum Tab: Hashable {
        case dashboard
        case brewing
        case inventory
        case settings
    }

    struct State: Equatable {
        var isBootstrapping = true
        var hasCompletedOnboarding = false
        var selectedTab: Tab = .dashboard
        var dashboard = DashboardFeature.State()
        var brewingLog = BrewingLogFeature.State()
        var inventory = InventoryFeature.State()
        var onboarding = OnboardingFeature.State()
        var settings = SettingsFeature.State()
    }

    enum Action: Equatable {
        case task
        case bootstrapResponse(Bool)
        case selectedTabChanged(Tab)
        case dashboard(DashboardFeature.Action)
        case brewingLog(BrewingLogFeature.Action)
        case inventory(InventoryFeature.Action)
        case onboarding(OnboardingFeature.Action)
        case settings(SettingsFeature.Action)
    }

    @Dependency(\.databaseClient) var databaseClient

    var body: some ReducerOf<Self> {
        Scope(state: \.dashboard, action: \.dashboard) {
            DashboardFeature()
        }
        Scope(state: \.brewingLog, action: \.brewingLog) {
            BrewingLogFeature()
        }
        Scope(state: \.inventory, action: \.inventory) {
            InventoryFeature()
        }
        Scope(state: \.onboarding, action: \.onboarding) {
            OnboardingFeature()
        }
        Scope(state: \.settings, action: \.settings) {
            SettingsFeature()
        }

        Reduce { state, action in
            switch action {
            case .task:
                state.isBootstrapping = true
                let databaseClient = self.databaseClient

                return .run { send in
                    let hasCompletedOnboarding = try await databaseClient.fetchHasCompletedOnboarding()
                    await send(.bootstrapResponse(hasCompletedOnboarding))
                }

            case let .bootstrapResponse(hasCompletedOnboarding):
                state.isBootstrapping = false
                state.hasCompletedOnboarding = hasCompletedOnboarding

                return .merge(
                    .send(.dashboard(.task)),
                    .send(.brewingLog(.task)),
                    .send(.inventory(.task))
                )

            case .selectedTabChanged(let tab):
                state.selectedTab = tab
                return .none

            case .onboarding(.delegate(.didFinishOnboarding)):
                state.hasCompletedOnboarding = true
                state.selectedTab = .inventory
                let databaseClient = self.databaseClient

                return .run { send in
                    try await databaseClient.completeOnboarding()
                    await send(.dashboard(.task))
                    await send(.brewingLog(.task))
                    await send(.inventory(.task))
                }

            case .brewingLog(.delegate(.didSaveBrew)):
                return .merge(
                    .send(.dashboard(.task)),
                    .send(.inventory(.task))
                )

            case .inventory(.delegate(.didChangeInventory)):
                return .merge(
                    .send(.dashboard(.task)),
                    .send(.brewingLog(.task)),
                    .send(.inventory(.task))
                )

            case .dashboard, .brewingLog, .inventory, .onboarding, .settings:
                return .none
            }
        }
    }
}
