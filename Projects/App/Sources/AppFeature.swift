import BrewingLogFeature
import ComposableArchitecture
import DashboardFeature
import DatabaseClient
import InventoryFeature
import OnboardingFeature
import SettingsFeature

@Reducer
struct AppFeature {
    struct State: Equatable {
        var isBootstrapping = true
        var hasCompletedOnboarding = false
        var dashboard = DashboardFeature.State()
        var brewingLog = BrewingLogFeature.State()
        var inventory = InventoryFeature.State()
        var onboarding = OnboardingFeature.State()
        var settings = SettingsFeature.State()
    }

    enum Action: Equatable {
        case task
        case bootstrapResponse(Int?)
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
                    let preference = try await databaseClient.fetchUserPreference()
                    await send(.bootstrapResponse(preference?.standardCafePrice))
                }

            case let .bootstrapResponse(standardCafePrice):
                state.isBootstrapping = false
                state.hasCompletedOnboarding = standardCafePrice != nil

                if let standardCafePrice {
                    let priceString = String(standardCafePrice)
                    state.onboarding.standardCafePrice = priceString
                    state.settings.standardCafePrice = priceString
                }

                return .merge(
                    .send(.dashboard(.task)),
                    .send(.brewingLog(.task)),
                    .send(.inventory(.task))
                )

            case let .onboarding(.delegate(.didSavePreference(price))):
                state.hasCompletedOnboarding = true
                state.settings.standardCafePrice = String(price)

                return .merge(
                    .send(.dashboard(.task)),
                    .send(.brewingLog(.task)),
                    .send(.inventory(.task))
                )

            case let .settings(.delegate(.didUpdatePreference(price))):
                state.onboarding.standardCafePrice = String(price)
                return .send(.dashboard(.task))

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
